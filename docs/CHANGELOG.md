# CHANGELOG.md — Completed outputs & milestones

> Append-only history of what shipped, in order. Each entry doubles as a record
> of *how* a system was implemented. For the *current* state of each system, see
> [SYSTEMS.md](SYSTEMS.md). When you finish an output, add it here.

---

### Output 0 — Repo + project scaffold

- GitHub repo created.
- Godot project scaffolded.

### Output 1 — Local click-to-move

- `CharacterBody2D` player.
- Click sets target.
- Player moves using `velocity` and `move_and_slide()`.

### Output 2 — Local headless server + client connect

- ENet server on UDP 32100.
- Local client connects.
- Logs added for connect/disconnect.

### Output 3 — Multiplayer spawning + sync

- `Players` container.
- `MultiplayerSpawner`.
- `Player.tscn` spawnable.
- Authority fixed using node name / peer id.
- `MultiplayerSynchronizer` syncs player position.
- Input guarded with `is_multiplayer_authority()`.

### Output 4 — Soft separation / collision investigation

- Player-player physics collision disabled.
- Player collides with world only.
- Tried NavigationAgent2D avoidance.
- Eventually moved away from avoidance for player-vs-player.
  (See [DECISIONS.md](DECISIONS.md).)

### Output C — Deploy headless server to Vultr

- Server deployed to Vultr Seattle.
- UDP 32100 opened.
- Client connected from home and hotspot.
- Server runs as systemd service.

### Output D — Harden SSH access

- Tailscale installed.
- SSH works over Tailscale IP.
- Public SSH closed in Vultr firewall.
- SSH removed from UFW.
- UDP 32100 remains public.

### Output E — Deploy/update routine

- Created release folders.
- Created `deploy_elysium` helper script.
- Can deploy new server builds with one command.

### Output G — Gameplay foundation

- Camera follows local player.
- Removed server-owned fake player.
- Diagnosed join-order avoidance bug.
- Decided on manual player separation / blocking style.
- Added background map.
- Added boundary walls and cliff obstacles.
- Added name labels.
- Added player name input.
- Added simple click-to-attack.
- Added creature HP and death.

### Friend package milestone

- Exported Windows client.
- Sent to Windows machine.
- Windows client ran successfully.
- Windows player connected to live server.
- Mac player also connected at the same time.

This means the project has passed the “real second machine can join” milestone.

### Output H — Multiple creature spawning

- `Creatures` container and `CreaturesSpawner` (`MultiplayerSpawner`) in `Main.tscn`.
- `game_data.gd` with `CREATURE_SPAWN_POSITIONS`.
- `spawn_initial_creatures()` called on server startup.
- Multiple creatures spawn at fixed positions for all connected players.
- Each creature has its own HP; players can attack different creatures.

### Output I — Knight character sprite + animations

- Generated knight character sprite using Gemini (Warhammer 40k / TMNT / Iron Man mashup).
- Three poses stored as `assets/knight/idle.png`, `attack.png`, `walk.png`.
- Replaced `Sprite2D` with `AnimatedSprite2D` in `Player.tscn`.
- Three animations set up in SpriteFrames: `idle`, `walk`, `attack`.
- `player.gd` updated to drive animations from movement and attack state.
- `is_attacking` flag prevents `_physics_process` from overwriting the attack animation.
- `animation_finished` signal returns to idle after attack completes.

### Output J — Creature respawn

- Creatures hide on death instead of `queue_free()`.
- Server waits 5 seconds then resets HP and position.
- `set_visibility` RPC propagates hide/show to all clients.

### Output K — Player HP + respawn

- Player has `MAX_HP = 100` and `hp` variable.
- `take_damage` RPC on player mirrors creature pattern.
- On death, HP resets and player teleports back to spawn position.

### Output L — Creatures attack back

- Creature runs a server-side `attack_loop` every 2 seconds.
- Checks all players in range (`ATTACK_RANGE = 150px`).
- Deals `ATTACK_DAMAGE = 5` to any player within range via `take_damage` RPC.
- Skips attacking while hidden (dead/respawning).

### Output M — HP bar visible to player

- Added `HUD` (`CanvasLayer`) → `HPBar` (`ProgressBar`) inside `Player.tscn`.
- `HUD` hidden by default; script shows it only for the authoritative local player (same pattern as `Camera2D`), so friends' bars don't stack on your screen.
- `HPBar` pinned Top-Left, fixed size, red fill via a `StyleBoxFlat` Fill override.
- `player.gd` sets `hp_bar.max_value`/`value` in `_ready`, and updates `hp_bar.value` in `take_damage` and `restart`.
- Purely client-side: no replication schema change, so no server redeploy / version-mismatch risk.

### Output N — Attack cooldown

- `ATTACK_COOLDOWN = 1.0s` constant and `cooldown_remaining` float in `player.gd`.
- `_physics_process(delta)` ticks `cooldown_remaining` down every frame, above the `has_target` early-return.
- `_input` only swings (animation + `take_damage` RPC) when `cooldown_remaining <= 0.0`, then resets it; click-spam is ignored.
- In-range clicks now set `has_target = false` so the knight stands and swings instead of drifting.
- Client-side only; no replication change.

### Output O — Floating damage numbers (local-only)

- New `damage_number.tscn` (`Label` root + `damage_number.gd`): a `Tween` floats it up ~80px and fades alpha to 0 over 0.6s, then `queue_free`s itself.
- `player.gd` preloads it and calls `spawn_damage_number(creature.global_position, 1)` inside the cooldown check, so a number only pops when a hit actually lands.
- Spawned into `get_tree().current_scene` (not parented to the creature) so it survives the creature's death/hide, doesn't ride along if the creature moves, and isn't a single reused label.
- Local-only by design: spawned on the attacking client at click time. Note `creature.take_damage` runs on the **server** (`rpc_id(1, …)`), so a creature-owned label would animate where no one can see it — hence client-side spawn.
- Reads as instant client-side prediction; fine for prototype, would come from server confirmation under authoritative combat later.

### Output P — EXP on kill (server-authoritative)

- Chosen as **EXP** (not a raw kill count) — same code cost, fits the Lineage-classic feel, and is the natural hook for future leveling. Leveling itself is explicitly deferred.
- `creature.gd`: `EXP_REWARD = 10`. In `take_damage`, when `hp <= 0` on the server, `multiplayer.get_remote_sender_id()` identifies the killer (player nodes are named by peer id), then `player.add_exp.rpc_id(killer_id, EXP_REWARD)` awards only that peer before `respawn()`.
- `player.gd`: `var exp`, `@rpc("any_peer","call_local","reliable") func add_exp(amount)` increments and updates `EXPLabel`. `any_peer` is required because the **server** (not the node's client-authority) sends this RPC.
- `EXPLabel` added to `HUD` under the HP bar; authority-gated like the rest of the HUD.
- Server-authoritative on purpose: the **client never knows creature HP** — `take_damage.rpc_id(1, …)` runs only on the server, and `call_local` does *not* fire for a targeted `rpc_id` to another peer (verified empirically). So client-side kill detection is impossible; the server is the only source of truth for the kill and the killer.
- Touches `creature.gd`, so it required a server redeploy (RPC added, not a synced property, so no replication-schema mismatch).

### Output Q — Hit sound on landed attack (client-side)

- Free CC0 impact sound (Kenney "Impact Sounds", `impactPunch` family) saved as `assets/audio/hit.ogg`.
- `AudioStreamPlayer` node named `AttackSound` added as a child of the root `Player` node in `Player.tscn`, with `hit.ogg` assigned to `Stream`. Plain (non-positional) `AudioStreamPlayer` on purpose — a flat one-shot is all a top-down prototype needs when the target is always near you.
- `player.gd`: `@onready var attack_sound: AudioStreamPlayer = $AttackSound`, and `attack_sound.play()` added as the last line of the cooldown block in `_input`, right after `spawn_damage_number(...)`.
- Plays **only on a landed hit**: gated by the same `cooldown_remaining <= 0.0` guard as the damage RPC, so click-spam yields one thwack per 1s cooldown, never on a miss or out-of-range click.
- Decided **impact** sound (the thwack of connecting), not a swing whoosh — impact gives combat its weight.
- Client-side only: every player has the node, but only the local authority's `_input` runs, so each player hears only their own hits. No replication-schema change → **no server redeploy**.
- **Known tradeoff:** the sound fires at swing *start* (click time, same hook as the damage number), so it slightly leads the visual impact frame of the `attack_right` animation. Logged as a future polish item (sync to the animation's contact frame via `anim_sprite.frame_changed`).
- **Deferred:** sound currently lives on the player. Move it to the creature (via an RPC, which costs a redeploy) only when the second creature variant ships — that's the first moment two creatures could sound different.

### Output R — Death sound on creature kill (client-side)

- Death `.mp3` saved as `assets/audio/death-1.mp3` (Godot 4 imports MP3 natively as `AudioStreamMP3` — no conversion needed).
- `AudioStreamPlayer2D` node named `DeathSound` added as a child of the root `Creature` node in `creature.tscn`, with `death-1.mp3` assigned to `Stream`. **Positional (2D) on purpose:** a creature death is a shared world event, so nearby players hear it with distance falloff (vs. the hit sound, which is flat/personal on the player).
- `creature.gd`: `@onready var death_sound: AudioStreamPlayer2D = $DeathSound`, and `death_sound.play()` inside `set_visiblity`, gated on `if not value:` — fires on the death/hide, not on the respawn (`set_visiblity(true)`).
- Hook is **server-authoritative-aware**: the client never knows creature HP, so it can't predict death. The death moment reaches all clients via the existing `set_visiblity.rpc(false)` (the same RPC that hides the corpse), so the sound rides that.
- **No server redeploy:** unlike the usual `creature.gd` caution (which is about synced-property/replication-schema mismatch), this adds no synced property and no new RPC, and doesn't change `set_visiblity`'s signature or `@rpc` config. It's presentation behavior in the **client's** copy of an existing handler plus a non-synced local node. Server keeps its old build; only clients need the new one. (A friend on the old build simply won't hear *their* kills until they update — harmless.)
- No server guard needed: if not redeployed the server never runs the line; even if redeployed, `play()` on a headless server hits the dummy audio driver as a no-op.

### Output S — KnightSword sprite swap + 4-way directional walk

- Replaced the old individual-PNG knight art with the **KnightSword** pack (grid sprite sheets + Aseprite/TexturePacker JSON, 256×256 frames, authored at 10 FPS). Sheets copied into `assets/knight_new/`; old `assets/knight/` left on disk as a fallback (not referenced).
- Sliced sheets directly in Godot's SpriteFrames "Add frames from Sprite Sheet" (Horizontal×Vertical grid, skipping trailing empty cells) — no manual PNG splitting. Direction mapping confirmed via the pack's `.gif` previews: dir8 = S (toward camera), dir6 = E, dir4 = N, dir2 = W.
- Animations now: `idle` (Idle_dir8), `walk_down` (Walk_dir8), `walk_up` (Walk_dir4), `walk_left` (Walk_dir2), `walk_right` (Walk_dir6) — all loop at 10 FPS — plus `attack_right` (Attack_dir6, 15 frames, **Loop OFF**). Unused `attack_poke` deleted.
- **Loop OFF on `attack_right` is load-bearing:** `player.gd` waits on `animation_finished` → `_on_attack_finished` to clear `is_attacking`; a looping attack never fires that signal and freezes the knight mid-swing.
- `AnimatedSprite2D` set to `scale = (2, 2)`, position (5, −72) to fit the 256px frames to the world. The `CollisionShape2D` was also adjusted (RectangleShape2D 180×160.5 at position (10, −131)) to sit on the scaled body and verified in-editor with Visible Collision Shapes. Note: the docs previously claimed 210×195 — corrected against the actual scene file during this output.
- `player.gd`: rewrote the movement animation block to **4-way selection by dominant velocity axis** (`walk_right`/`walk_left`/`walk_down`/`walk_up`), dropping `flip_h` for movement. Chose real directional frames over `flip_h`-mirroring because the knight holds the sword in one hand — mirroring put the sword in the wrong hand. `walk_up` = `last_direction.y < 0` (Godot screen-down is +Y).
- Attack stays **right-only** (one sheet) but faces the target: `flip_h = clicked_creature.global_position.x < global_position.x` set in `_input` before `play("attack_right")`. First attempt flipped on stale `last_direction` (only updated while moving), so a standing attack on a left-side creature swung right — fixed by facing the clicked creature instead. 8-way diagonals and directional attacks deferred (parking lot).
- Client-side visual logic only — no synced property or RPC change, replication schema untouched, so no forced redeploy. But `player.gd` also runs in the server build: sync builds (redeploy server + restart clients) at the next deploy for hygiene.

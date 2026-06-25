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

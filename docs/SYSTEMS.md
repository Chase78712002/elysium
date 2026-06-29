# SYSTEMS.md — Current technical state of Elysium

> How the game is built *right now*, verified against the actual scene/script
> files. For the history of how each system got here, see
> [CHANGELOG.md](CHANGELOG.md). For server/ops, see
> [DEPLOYMENT.md](DEPLOYMENT.md). For *why* certain choices were made, see
> [DECISIONS.md](DECISIONS.md).
>
> When you change a system, update this file to match.

---

## Tech Stack

- Engine: Godot **4.6.1 stable**
- Networking: Godot `ENetMultiplayerPeer`, UDP port **32100**, `MAX_CLIENTS = 32`

(Server, hosting, and deploy details live in [DEPLOYMENT.md](DEPLOYMENT.md).)

---

## Main scene (`Main.tscn`)

The root node `Node2D` has **`server.gd` attached** — the same script runs the
server (headless) and the client.

```text
Node2D  (root, named "Node2D", script = server.gd)
  Background            (Sprite2D, scale 4, generated map texture)
  boundary / StaticBody2D
    left, right, top, bottom   (CollisionShape2D, RectangleShape2D walls)
  Players               (Node2D — container for spawned players)
  Spawner               (MultiplayerSpawner → ../Players, spawns Player.tscn)
  NavigationRegion2D    (visible = false; does NOT block movement)
  Obstacles / StaticBody2D
    CollisionShape2D, CollisionShape2D2, CollisionShape2D3, CollisionShape2D4
                        (4 CapsuleShape2D cliff obstacles)
  CanvasLayer
    NameInput           (LineEdit, "Enter Your Name")
    JoinButton          (Button, "JOIN")
  Creatures             (Node2D — container for spawned creatures)
  CreaturesSpawner      (MultiplayerSpawner → ../Creatures, spawns creature.tscn)
```

Notes:

- `NavigationRegion2D` exists but does **not** block movement by itself. Actual
  blocking is `StaticBody2D` + `CollisionShape2D` (boundary walls + obstacles).
  See [DECISIONS.md](DECISIONS.md).
- Background is a generated top-down fantasy starter-area map.

---

## Server / client flow (`server.gd`)

`server.gd` is attached to the `Main.tscn` root and handles both roles:

- `PORT = 32100`, `MAX_CLIENTS = 32`.
- On `_ready`: sets `Spawner`/`CreaturesSpawner` spawn functions. If
  `DisplayServer.get_name() == "headless"` → `start_server()`; otherwise shows
  the join `CanvasLayer` and wires up the Join button.
- **The hardcoded `connect_to_server("<PUBLIC_IP>")` call in `_ready` is
  commented out.** The live connect happens in `_on_join_pressed` when the
  player clicks JOIN. (Real IP is in `server.gd` / `docs/INFRA.local.md`.)
- `start_server()` creates the ENet server, connects peer connect/disconnect
  signals, and calls `spawn_initial_creatures()`.
- `request_spawn` (`@rpc("any_peer")`) assigns a spawn point round-robin via
  `spawn_couner` [sic] and calls `Spawner.spawn(...)`.
- Player nodes are **named by peer id** (`p.name = str(data.id)`), which is what
  makes authority and the EXP-killer lookup work.

---

## Player (`Player.tscn` + `player.gd`)

Actual scene tree:

```text
Player / CharacterBody2D        (group "players", collision_layer = 2)
  AnimatedSprite2D              (NOT a plain Sprite2D)
  CollisionShape2D              (RectangleShape2D, 210 × 195)
  MultiplayerSynchronizer
  NavigationAgent2D             (radius 80 — present but see note)
  Camera2D                      (enabled only for the local authority)
  NameLabel                     (Label)
  AttackArea / Area2D           (CircleShape2D ~208 radius — see note)
    CollisionShape2D
  AttackSound / AudioStreamPlayer  (plain/non-positional; Stream = assets/audio/hit.ogg)
  HUD / CanvasLayer             (shown only for the local authority)
    HPBar / ProgressBar         (red StyleBoxFlat fill, top-left)
    EXPLabel / Label            ("EXP: N", under the HP bar)
```

`MultiplayerSynchronizer` replicates: `position`, `sync_velocity`,
`player_display_name`.

Constants in `player.gd`:

- `SPEED = 300`, `ARRIVAL_DIST = 8`
- `SEPARATION_DIST = 150`
- `ATTACK_RANGE = 200`
- `MAX_HP = 100`
- `ATTACK_COOLDOWN = 1.0`

Authority:

```gdscript
func _enter_tree() -> void:
	set_multiplayer_authority(int(name))   # node name is the peer id
```

Do not remove without good reason (also flagged in CLAUDE.md "Critical
gotchas"). Only the local authority processes input, moves itself, and shows its
Camera2D / HUD. Remote players are synced via replication.

Animations (`SpriteFrames` in `Player.tscn`): `attack_poke`, `attack_right`,
`idle`, `walk_down`, `walk_right`. The code plays `attack_right` (attack),
`walk_right` / `walk_down` (movement, chosen by dominant axis with `flip_h`),
and `idle`. `attack_poke` is currently **not** referenced by `player.gd`.
`is_attacking` blocks `_physics_process` from overwriting the attack animation;
`animation_finished` → `_on_attack_finished` returns to `idle`.

> **Vestigial nodes:** `NavigationAgent2D` exists (radius 80, `max_speed` set)
> but movement uses `global_position.direction_to(target_pos)` directly — no
> agent pathfinding. `AttackArea` exists but attacks use a point query +
> `ATTACK_RANGE` distance check, not Area2D overlap. Neither currently drives
> behavior.

---

## Movement, attack & combat (`player.gd`)

Movement:

- Click-to-move. Left click sets `target_pos` / `has_target`; `_physics_process`
  moves toward it with `move_and_slide()` then `apply_player_separation()`.
- `apply_player_separation()` pushes this player directly out of any other
  `players`-group body within `SEPARATION_DIST` (150). This is the custom
  blocking-style separation — **implemented**, not just planned. See
  [DECISIONS.md](DECISIONS.md).

Attack:

- Left click runs a `PhysicsPointQueryParameters2D` point query and looks for a
  `creatures`-group collider.
- Creature clicked and within `ATTACK_RANGE` (200): `has_target = false`, and if
  `cooldown_remaining <= 0` → start cooldown, play `attack_right`, send
  `creature.take_damage.rpc_id(1, 1)` (1 damage, **runs on the server**),
  spawn a local damage number, and play the local hit sound (`AttackSound`).
  Sound + damage number are client-side prediction at swing *start*, so they
  lead the animation's visual contact frame (logged in ROADMAP).
- Creature clicked but out of range → move toward it. Empty ground → move there.
- Cooldown: `cooldown_remaining` ticks down in `_physics_process`; click-spam
  while on cooldown is ignored.

Player HP / EXP:

- `hp` starts at `MAX_HP = 100`. `take_damage`
  (`@rpc("any_peer","call_local","reliable")`) subtracts, updates `HPBar`, and
  on `hp <= 0` calls `restart()` (reset HP, clear target, teleport to
  `spawn_position`).
- `add_exp` (`@rpc("any_peer","call_local","reliable")`) increments `exp` and
  updates `EXPLabel`. `any_peer` is required because the **server** sends it.
  See [DECISIONS.md](DECISIONS.md) for why EXP is server-authoritative.

Floating damage numbers (`damage_number.tscn` + `damage_number.gd`):

- A `Label` whose `_ready` runs a parallel `Tween`: floats up 80px and fades
  alpha to 0 over 0.6s, then `queue_free`s.
- `player.gd` spawns it into `get_tree().current_scene` when a hit lands,
  offset `Vector2(0, -150)` from the creature. Local-only / client-side
  prediction by design.

---

## Creature (`creature.tscn` + `creature.gd`)

Scene tree:

```text
Creature / StaticBody2D         (group "creatures")
  Sprite2D                      (PlaceholderTexture2D, 155 × 155)
  CollisionShape2D              (RectangleShape2D, 155 × 155)
```

Constants in `creature.gd`:

- `MAX_HP = 3`  (player deals 1 per hit → **3 hits to kill**)
- `ATTACK_RANGE = 150`
- `ATTACK_DAMAGE = 5`
- `EXP_REWARD = 10`

Behavior (all server-driven):

- `take_damage` (`@rpc("any_peer","call_local","reliable")`) subtracts HP. On
  `hp <= 0`, **on the server**, finds the killer via
  `multiplayer.get_remote_sender_id()` (matched against player node names),
  awards `EXP_REWARD` to that peer with `player.add_exp.rpc_id(killer_id, ...)`,
  then `respawn()`.
- `attack_loop()` (started in `_ready` on the server) loops every 2.0s: skips
  while not `visible`, otherwise deals `ATTACK_DAMAGE` (5) to every player within
  `ATTACK_RANGE` (150) via `player.take_damage.rpc(...)`.
- `respawn()`: `set_visiblity.rpc(false)` [sic — misspelled in code], wait 5.0s,
  reset HP and position, `set_visiblity.rpc(true)`.

---

## Game data (`game_data.gd`)

Autoload-style singleton (`extends Node`) holding static spawn data:

```text
SPAWN_POINTS              — 5 Vector2 player spawn positions
CREATURE_SPAWN_POSITIONS  — 5 Vector2 creature spawn positions
```

`server.gd` reads `GameData.CREATURE_SPAWN_POSITIONS` on startup to spawn
creatures, and `GameData.SPAWN_POINTS` in `request_spawn` (round-robin) to place
players. **Do not hardcode spawn positions elsewhere — put them here.**

---

## Join / name UI

`CanvasLayer` in `Main.tscn` holds `NameInput` (LineEdit) and `JoinButton`.
Flow: client does not connect on launch → player types a name → clicks JOIN →
`_on_join_pressed` stores the name, hides the UI, and connects to the server.
Preserve this simple flow if modifying it.

# CLAUDE.md — Elysium Godot MMO Prototype

## Project Identity

Project name: **Elysium**

Elysium is a small prototype for a **classic top-down 2D MMORPG**, inspired by the feeling of older games like Lineage Classic, but not a clone. The current goal is not to build a full MMO yet. The current goal is:

> Get to “play with friends soon” as quickly as possible.

The project should prioritize small playable outputs over big architecture work.

---

## Core Design Direction

Elysium should feel like:

- old-school top-down MMORPG
- simple click-to-move movement
- readable multiplayer presence
- players standing in the same small world together
- simple combat loop first, depth later
- nostalgic, fantasy, starter-zone feel

The philosophy is:

- Build small.
- Test with real people early.
- Avoid overengineering.
- Avoid huge refactors unless clearly needed.
- Prefer one working output over five unfinished systems.

---

## Current Tech Stack

Engine:

- Godot **4.6.1 stable**

Networking:

- Godot `ENetMultiplayerPeer`
- UDP port: **32100**

Server:

- Vultr VPS in **Seattle**
- Ubuntu 24.04 x64
- Headless Godot exported server build
- Runs as a `systemd` service named:

```bash
elysium.service
```

Server user:

```bash
gameserver
```

Live server folder:

```bash
/home/gameserver/elysium
```

Release folder:

```bash
/home/gameserver/releases
```

Admin access:

- SSH is locked down to **Tailscale-only**
- Public SSH is closed
- Public game port UDP 32100 remains open

VPS Tailscale IP:

```bash
100.104.229.41
```

Public game server IP:

```bash
45.77.215.222
```

---

## Deployment Notes

The live server runs from:

```bash
/home/gameserver/elysium
```

There is a helper deploy script:

```bash
deploy_elysium <release-folder-name>
```

Example:

```bash
deploy_elysium elysium-2026-03-17
```

The simple deploy flow is:

1. Export server build locally.
2. Upload files to a new folder under:

```bash
/home/gameserver/releases/
```

3. Run:

```bash
deploy_elysium <release-folder-name>
```

The deploy script stops the service, copies the release files into the live folder, starts the service again, and shows status.

The server service can be controlled with:

```bash
sudo systemctl start elysium
sudo systemctl stop elysium
sudo systemctl restart elysium
sudo systemctl status elysium --no-pager
```

Live logs:

```bash
sudo journalctl -u elysium -f
```

---

## Important Networking State

The client currently connects to the live Vultr server by hardcoded IP:

```gdscript
connect_to_server("45.77.215.222")
```

So if testing against the live server, code changes that affect server behavior require:

1. Export new server build.
2. Upload to VPS release folder.
3. Run `deploy_elysium`.

Local-only changes will not affect the live VPS server unless redeployed.

---

## Current Scene Structure

Main scene roughly contains:

```text
Node2D  (root, named "Node2D")
  Background
  boundary / StaticBody2D
    left, right, top, bottom (CollisionShape2D)
  Players
  Spawner / MultiplayerSpawner
  NavigationRegion2D
  Obstacles / StaticBody2D
    CollisionShape2D (×4, CapsuleShape2D for cliff obstacles)
  CanvasLayer
    NameInput
    JoinButton
  Creatures
  CreaturesSpawner / MultiplayerSpawner
```

Notes:

- Root node is named `Node2D`, not `Main`.
- `Players` is the container for spawned player nodes.
- `Spawner` is the `MultiplayerSpawner` for players.
- `CreaturesSpawner` is the `MultiplayerSpawner` for creatures.
- `NavigationRegion2D` exists, but it does **not** block movement by itself.
- `boundary` holds the outer boundary wall collision shapes.
- `Obstacles` holds the cliff obstacle collision shapes.
- Background is a generated map image.

---

## Current Player Setup

`Player.tscn` root:

```text
Player / CharacterBody2D
  Sprite2D
  CollisionShape2D
  NavigationAgent2D
  MultiplayerSynchronizer
  Camera2D
  NameLabel
  AttackArea / Area2D
    CollisionShape2D
```

Player root:

- is `CharacterBody2D`
- collision layer: **2**
- collision mask: **1**
- belongs to group:

```text
players
```

Collision meaning:

- Players do not physically collide with other players.
- Players collide with world/walls.
- Player-to-player separation is handled manually, not through physics collision.

Camera:

- Each player has a `Camera2D`.
- Only the local authoritative player activates its camera.
- This fixed the issue where all clients saw the same fixed camera.

Label:

- `NameLabel` displays the player’s name.
- Initially labels used peer id.
- Later player-name input was added.

Attack:

- Each player has `AttackArea`.
- `AttackArea` is an `Area2D` with a circular `CollisionShape2D`.
- Current attack radius was adjusted based on player size.
- Player collision square is about **155px × 155px**.
- Attack radius was set larger than the body so melee range extends outside the icon.

---

## Player Movement

The project started with:

- click-to-move
- `target_pos`
- `has_target`
- `velocity`
- `move_and_slide()`

Important movement behavior:

- Only the local authoritative player processes input.
- Only the local authoritative player moves itself.
- Remote players are synced through multiplayer replication.

Authority setup:

```gdscript
func _enter_tree() -> void:
	set_multiplayer_authority(int(name))
```

This is important and should not be removed without good reason.

---

## Player Separation Decision

Originally, the project tried to use `NavigationAgent2D` avoidance for player-vs-player separation.

That caused a join-order bug:

- newest player could affect older players
- oldest player could not affect newer players
- players behaved asymmetrically

Several things were tested:

- avoidance layers/masks
- syncing `sync_velocity`
- feeding remote agent velocity
- disabling avoidance for remote players
- removing server-owned fake player

Conclusion:

> Godot `NavigationAgent2D` avoidance is not currently being used for player-vs-player separation.

Current direction:

- keep player-vs-player behavior simple
- players should not push each other around
- players should feel like solid presence, similar to classic Lineage-style blocking
- use a small custom separation/blocking behavior instead of Godot avoidance

This is intentional because the desired feel is:

> Players do not shove each other. They route around / get blocked by each other.

Avoid reintroducing `NavigationAgent2D` avoidance for player-vs-player unless there is a clear reason.

---

## Map / Background State

A generated top-down fantasy map background was imported.

Visual style:

- classic fantasy MMO starter area
- grassy/dirt/stone terrain
- cliffs/ruins/pond-like details
- open center for testing

The background is a `Sprite2D` in `Main.tscn`.

Current scale:

```text
Scale = 4
```

Manual walls were added:

- outer boundary walls
- several cliff obstacles

Important:

- `NavigationRegion2D` does not act as collision.
- Actual blocking is done through `StaticBody2D` + `CollisionShape2D`.

Current wall direction:

- manual wall collision is acceptable for prototype
- do not start a full TileMap system yet unless it becomes clearly necessary

---

## Creature Setup

A placeholder creature scene was created.

`Creature.tscn` root:

```text
Creature / StaticBody2D
  Sprite2D
  CollisionShape2D
```

Creature root belongs to group:

```text
creatures
```

Creature script:

- has `max_hp`
- has `hp`
- has `take_damage(amount)`
- prints HP
- disappears with `queue_free()` when HP reaches 0

Current behavior:

- player can click creature
- if in range, creature takes damage
- HP decreases
- creature disappears at 0 HP

This output is complete.

---

## Game Data

`game_data.gd` is an autoload-style singleton (extends `Node`) that holds static spawn data.

```text
SPAWN_POINTS       — 5 Vector2 positions where players spawn
CREATURE_SPAWN_POSITIONS — 5 Vector2 positions where creatures spawn
```

Server reads `GameData.CREATURE_SPAWN_POSITIONS` on startup to call `CreaturesSpawner.spawn()` for each position. Server reads `GameData.SPAWN_POINTS` in `request_spawn` to assign a spawn position per player (round-robin via `spawn_counter`).

Do not hardcode spawn positions elsewhere — put them here.

---

## Attack Behavior

Current attack approach:

- left click checks whether a creature was clicked
- if creature clicked and within `ATTACK_RANGE` (200px), deal 1 damage
- if creature clicked but out of range, move toward the creature
- if empty ground clicked, move there

Current simple attack does:

```text
target.take_damage(1)
```

Current output completed:

- clicking creature in range lowers HP
- creature disappears at 0 HP

Next likely improvement:

- attack cooldown
- tiny hit visual / sound
- creature respawn

---

## Player Name System

A simple join UI was added:

```text
CanvasLayer
  NameInput
  JoinButton
```

Current flow:

- client does not connect immediately
- player enters a name
- presses Join
- UI hides
- client connects to server

Player names output was considered complete.

If modifying this system, preserve the simple flow.

---

## Completed Outputs / Milestones

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

---

## Current Known Issues / Notes

### 1. Server/client version mismatch can break replication

When adding synced properties, all clients and the server must run the same build.

If there are errors like:

```text
Invalid packet received. Size too small.
on_sync_receive: Condition "err" is true
```

It usually means:

- local client changed replication schema
- server is still old
- another client is still old

Fix:

- re-export
- redeploy server
- fully restart clients

### 2. Hardcoded IP is okay for now

Current IP is hardcoded:

```gdscript
45.77.215.222
```

This is okay for early prototype.

Later, consider:

- config file
- simple server select UI
- environment-specific setting

Do not overbuild this yet.

### 3. NavigationRegion2D is not collision

Players can walk outside a navigation polygon unless movement code uses navigation paths or physics walls block them.

Use manual walls for now.

### 4. Player-vs-player behavior is intentionally blocking-ish

The desired feel is closer to classic MMO body presence.

Do not accidentally reintroduce “players shove each other around” unless the design changes.

---

## Immediate Next Outputs

The planned order from here:

### Output J — Creature respawn

- Creatures hide on death instead of `queue_free()`.
- Server waits 5 seconds then resets HP and position.
- `set_visibility` RPC propagates hide/show to all clients.

### Output K — Player HP + respawn

- Player has `MAX_HP = 100` and `hp` variable.
- `take_damage` RPC on player mirrors creature pattern.
- On death, HP resets and player teleports back to spawn position.

### Output next — Basic combat polish

Possible small outputs:

- attack cooldown
- hit feedback print / small flash
- simple damage number
- simple creature respawn
- simple creature name / HP label

### After that — More game loop

Potential features:

- simple creature AI
- creature attacks back
- player HP
- respawn
- basic chat
- friend session playtest notes

---

## Working Style Instructions for Claude

When helping on this project:

1. Give small step-by-step instructions.
2. Only give 1–2 steps at a time.
3. Wait for the user to say “next steps” before continuing.
4. Be specific with Godot 4.6.1 UI names and paths.
5. If unsure about the Godot UI, say so and ask for what the user sees.
6. Include code when changing scripts.
7. Avoid dumping huge files unless asked.
8. Prefer small playable outputs over large refactors.
9. Ask before changing architecture.
10. Remember the milestone: **play with friends soon**.

The user prefers detailed explanations when commands or scripts are introduced. Explain what command flags mean when asked.

---

## Anti-Overengineering Rule

Do not jump to:

- full MMO architecture
- accounts/auth
- database persistence
- authoritative combat server
- ECS-style refactors
- large TileMap systems
- full AI/pathfinding
- inventory/equipment

unless the user explicitly asks.

The current correct strategy is:

> Ship one small playable improvement, test it with real clients, then choose the next bottleneck.

---

## Current Priority

The next concrete output should be:

> Creatures attack back — give players a reason to care about their HP.

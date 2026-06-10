# Codename: Elysium

## Goal:

Top down online RPG prototype

## Tech:

- Godot 4.6.1
- Planned dedicated server on Vultr Seattle

## Running the Client

The client currently connects automatically to the live Elysium server after a player enters a name and clicks **Join**.

### Run from the Godot project

From the project directory containing `project.godot`, run:

```bash
godot --path .
```

Then:

1. Enter a player name.
2. Click **Join**.
3. The client will connect to the live server.

To run multiple clients on the same machine, open another Terminal window and run the same command again.

### Run the packaged Windows client

Keep these files together in the same folder:

```text
elysium.exe
elysium.pck
```

To join:

1. Extract the ZIP file.
2. Double-click `elysium.exe`.
3. Enter a player name.
4. Click **Join**.

Godot does not need to be installed to run the packaged Windows client.

### Troubleshooting

If the client cannot connect:

- Confirm the computer has an internet connection.
- Make sure `elysium.exe` and `elysium.pck` are in the same folder.
- Fully close and reopen the client.
- Confirm the live server is running.
- Make sure the client build is compatible with the currently deployed server build.

---

## What exists now:

- Output 0:
  - Main scene set.
  - Player (CharacterBody2D) created.
  - Placeholder Sprite2D
  - Initial input logging in script

- Output 1:
  - Local click to move placeholder

- Output 2:
  - Set up server and boots
  - Set up client and connect to server
- Output 3:
  - Two clients connect → each sees both players (as placeholders) moving.
- Output 4:
  - Fix collision that moves players by adding navigation agent.
  - players separate softly via navigation avoidance.
- Output 5:
  - Deploy headless server to Vultr and able to connect from different network
    - Server running on Vultr
    - UDP32100 opened (Vultr firewall + UFW)
    - Client connected successfully from home and hotspot network
    - Server running continuously via systemd
- Output 6:
  - Implement Tailscale-only SSH
    - setup a tailnet network and add VPS server and mac device into the network.
    - Delete firewall rule for TCP 22 via SSH in the allowlist
    - Remove 22/tcp from UFW allowlist
- Output 7:
  - Implement simple deploy and update routine
    - Creating a script to make deployment easier.
    - test the deployment script

- Output 8:
  - Fix later joined players can't be push by prior joined players.
    - Apply player separation via code.
    - Players don't push each other anymore.
    - Players treat each other as solid blocks and go around when bumping together.
- Output 9:
  - Export client and share to friends
    - Exported windows client build and sent to another machine.
    - Another machine with the windows .exe file are able to join the server.
- Output 10:
  - Add tiny map background + a few blocking walls
    - a grassy floor
    - 3 wall blocks
    - a bounded test area
  - Player name label above each character.
- Output 11:
  - Spawn position follows pre-defined spawn locations in order.
- Output 12:
  - Add real player names
    - Create simple start UI for players to enter their names.
    - Player connects with their entered name on the top of their placeholder icon
- Output 13:
  - Add simple attacks
- Output 14:
  - Add simple creatures
  - Add hp to creatures
  - Attacks reduce creatures' hp
  - Creatures are removed when hp reaches 0
- Output 15:
  - Spawn multiple creatures
  - Fix attacks and creatures removed only happen locally.
- Output 16:
  - Add character's basic sprites
    - walk
    - idle
    - attack
  - Add animations logic
- Output 17:
  - Add creatures respawning after death
- Output 18:
  - Add player HP + death/respawn
- Output 19: WIP
  - Add creatures attacking back to reduce player HP
  - Add new attack right animation
  - Add HPBar node in view
  - WIP... wiring up HPBar in script

## Upcoming work:

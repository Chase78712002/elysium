# Codename: Elysium

## Goal:

Top down online RPG prototype

## Tech:

- Godot 4.6.1
- Planned dedicated server on Vultr Seattle

## Run Instruction:

1. Open in Godot
2. run Main scene

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
- Output 13: WIP...
  - Add simple attacks

## Upcoming work:

- Add simple creatures

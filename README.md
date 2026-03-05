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

## Current Output:

3

## Next Output:

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

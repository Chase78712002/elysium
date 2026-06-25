# CLAUDE.md — Elysium Godot MMO Prototype

Elysium is a small prototype for a **classic top-down 2D MMORPG**, inspired by
the feeling of older games like Lineage Classic, but not a clone. Not a full MMO
yet. The current goal is:

> Get to "play with friends soon" as quickly as possible.

Prioritize small playable outputs over big architecture work.

---

## Docs map — READ THE RELEVANT FILE BEFORE ACTING

This file is the always-loaded context. Detailed reference lives in `docs/`.
Open the relevant file *before* doing the matching action — don't act on memory.

- **Changing a game system** (player, creature, attack, spawn, movement, HUD)?
  → read [`docs/SYSTEMS.md`](docs/SYSTEMS.md) FIRST — it's verified against the
  actual scene/script files. Update it when you change a system.
- **Touching the server, networking, or deploying?**
  → read [`docs/DEPLOYMENT.md`](docs/DEPLOYMENT.md) FIRST. Local changes don't
  reach the live VPS without a redeploy.
- **About to reverse a design choice or "fix" something that looks odd**
  (player separation, NavigationAgent2D avoidance, client-side EXP)?
  → read [`docs/DECISIONS.md`](docs/DECISIONS.md) FIRST — there's likely a reason.
- **Picking the next thing to build?**
  → read [`docs/ROADMAP.md`](docs/ROADMAP.md).
- **Finished an output?**
  → append it to [`docs/CHANGELOG.md`](docs/CHANGELOG.md) and update
  `docs/SYSTEMS.md` to match the new reality.

---

## Critical gotchas (never skip these)

1. **Player authority is bound to the node name (peer id).** Do not remove or
   change without a clear reason:

   ```gdscript
   func _enter_tree() -> void:
       set_multiplayer_authority(int(name))
   ```

2. **Adding a synced property requires a full redeploy + client restart.**
   Server and all clients must run the same build. Symptoms of a mismatch:

   ```text
   Invalid packet received. Size too small.
   on_sync_receive: Condition "err" is true
   ```

   Fix: re-export, redeploy the server, fully restart clients. (Adding an RPC
   does not change the replication schema, but still needs a redeploy if the
   server runs the affected script.)

3. **Player-vs-player is intentionally blocking-ish, not shove-y.** Players
   route around / get blocked by each other; they do not push each other around.
   Don't reintroduce shoving unless the design changes.

---

## Core design direction

Elysium should feel like:

- old-school top-down MMORPG, click-to-move
- readable multiplayer presence — players standing in the same small world
- simple combat loop first, depth later
- nostalgic, fantasy, starter-zone feel

Philosophy: build small, test with real people early, avoid overengineering,
avoid huge refactors unless clearly needed, prefer one working output over five
unfinished systems.

---

## Working style for Claude

1. Give small step-by-step instructions — only 1–2 steps at a time.
2. Wait for the user to say "next steps" before continuing.
3. Be specific with Godot 4.6.1 UI names and paths.
4. If unsure about the Godot UI, say so and ask what the user sees.
5. Include code when changing scripts; avoid dumping huge files unless asked.
6. Prefer small playable outputs over large refactors. Ask before changing
   architecture.
7. The user prefers detailed explanations when commands or scripts are
   introduced (explain flags when asked).
8. Remember the milestone: **play with friends soon**.

---

## Anti-overengineering rule

Do not jump to: full MMO architecture, accounts/auth, database persistence,
authoritative combat server, ECS-style refactors, large TileMap systems, full
AI/pathfinding, or inventory/equipment — unless the user explicitly asks.

> Ship one small playable improvement, test it with real clients, then choose
> the next bottleneck.

---

## Current priority

> Polish pass before wider sharing. The combat loop is visible, paced,
> responsive, and rewarding (HP bar, attack cooldown, floating damage numbers,
> EXP-on-kill all done). Next is a small-polish choice: hit/death sound,
> creature name + HP label above its head, or a second creature variant.
> Leveling is deferred until after a play-test.

Full next/deferred list: [`docs/ROADMAP.md`](docs/ROADMAP.md).

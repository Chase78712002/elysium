# ROADMAP.md — What's next

> The live "what should I build next" list, organized by horizon. When something
> ships, move it to [CHANGELOG.md](CHANGELOG.md) and update
> [SYSTEMS.md](SYSTEMS.md).
>
> **Discipline: one small playable output at a time.** Build the NOW item, test
> it, then let the playtest reveal the next lever. Don't stack leveling + a
> second creature + a bigger map at once.

---

## North Star (vision — not a task, no date)

Eventually: a wider public release — a top-down 2D MMORPG a *stranger* would
choose to play, in the Lineage-Classic spirit. Direction only. Everything below
should point roughly this way, but we get there by shipping small.

---

## Spine — next real milestone

> **A real friend playtest on the live VPS, with a FRESH exported build.**

Milestone-triggered, not date-triggered. Worth doing *now* because leveling
gives the combat loop a payoff worth testing with real people. The playtest is
the forcing function that closes this cycle of work.

---

## NOW — the one depth addition: LEVELING

The single thing we're building. Everything else waits.

When the local player's EXP crosses a threshold:

- `level += 1`
- max HP increases (~+20 per level)
- heal to full
- show **"Lv N"** on the HUD

**Implemented CLIENT-SIDE, on the local player only, inside the existing
`add_exp` RPC path.** Zero new synced property → zero redeploy → dodges the
CLAUDE.md replication-schema gotcha.

Why this is legit (see [DECISIONS.md](DECISIONS.md), [SYSTEMS.md](SYSTEMS.md)):
`add_exp` already fires server → the killer's own client, already does
`exp += reward` and updates the EXP label, and the HUD is authority-gated so
only your own client shows your HUD. A locally-computed level is exactly as
"real" as the EXP label already is.

**Accepted caveats for a friend playtest:** other players won't see your level,
and buffed stats aren't server-validated (spoofable). A synced level can be one
deliberate redeploy later if it matters.

---

## Before playtest (later, this game)

- **Fresh exported Windows build.** The current build predates recent combat
  polish (damage numbers, sounds, EXP) — friends have a stale copy.
- **Write down how 2–3 friends get and run it** (short handoff note).

---

## Later / optional (this game)

Demoted from "NOW" on purpose — cosmetic, and only interesting *after* leveling
gives a reason to prefer a tougher target.

- Creature name / HP label above the creature's head.
- Second creature type (even just a color variant).

---

## Parking lot (North-Star fuel — not now)

Good ideas, deliberately out of scope. Keep the specific notes; they're
expensive to reconstruct later.

- **EXP bar instead of EXP label.** Replace `EXPLabel` ("EXP: N") with a
  `ProgressBar` filling toward the next-level threshold. Pairs naturally with
  leveling: `max_value` = next-level threshold, `value` = current EXP, resets
  each level-up. Same HUD/authority-gated pattern as the HP bar — mostly a
  `Label` → `ProgressBar` swap plus the leveling threshold math.
- **Synced level number** (so other players see your level) — one deliberate
  redeploy; the replication-schema gotcha applies.
- **Hit-sound impact-frame sync.** The hit sound fires at swing *start* (click
  time), so it leads the animation's visual contact frame. Fix: play it on the
  impact frame via `anim_sprite.frame_changed` or a short tuned timer. Cheap,
  client-side, no redeploy. Polish-of-the-polish.
- **Move hit sound onto the creature** (an RPC → server redeploy) — only when
  the second creature variant ships, the first moment two creatures could sound
  different.
- Story / plot, bigger map / TileMap, inventory / equipment.
- Creature chase / aggro movement (needs position sync = redeploy gotcha).

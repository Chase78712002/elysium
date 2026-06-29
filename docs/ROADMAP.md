# ROADMAP.md — What's next

> The live "what should I build next" list. When something ships, move it to
> [CHANGELOG.md](CHANGELOG.md). Keep this short — prefer one small playable
> output at a time.

---

## Current priority

> Polish pass before wider sharing. Outputs M–Q are all done (HP bar, attack
> cooldown, floating damage numbers, EXP-on-kill, hit sound). The combat loop is
> now visible, paced, responsive, rewarding, and audible.

Next is a small-polish choice (hit sound shipped — Output Q):

- death sound effect (free asset)
- creature name / HP label above creature head
- second creature type (even just a color variant)

Leveling is deferred until after a play-test.

---

## Deferred — Hit sound polish (from Output Q)

- **Sync sound to impact frame.** The hit sound currently fires at swing *start*
  (click time, same hook as the damage number), so it leads the visual contact
  frame of `attack_right`. Fix: play it on the animation's impact frame via
  `anim_sprite.frame_changed` (or a short tuned `create_timer`). Cheap,
  client-side, no redeploy. Polish-of-the-polish — do only if it bothers in play.
- **Move sound to the creature.** Sound lives on the player today. Move it onto
  the creature (an RPC, which costs a server redeploy) only when the second
  creature variant ships — the first moment two creatures could sound different.

## Deferred — Leveling

- EXP already accumulates server-side (Output P). Leveling builds on it:
  thresholds, what a level grants, syncing/displaying level, eventual
  persistence.
- Not started yet — explicitly out of scope until the polish above is done and
  play-tested.

## Deferred — EXP bar instead of EXP label

- Replace the `EXPLabel` (currently "EXP: N") with a `ProgressBar` that fills
  toward the next level and shows a percentage.
- Pairs naturally with Leveling: the bar's `max_value` becomes the next-level
  threshold, `value` is current EXP, and it visually resets each level-up.
- Same HUD/authority-gated pattern as the HP bar; mostly a swap of
  `Label` → `ProgressBar` plus the threshold math from Leveling.
- Deferred until Leveling exists (a percentage only means something once there's
  a "next level" target).

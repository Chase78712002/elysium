# DECISIONS.md — Why things are the way they are

> **Read this before reversing a design choice or "fixing" something that looks
> odd.** Each entry exists because a simpler-looking alternative was already
> tried and rejected, or because the current behavior is intentional.

---

## Player separation — no NavigationAgent2D avoidance

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

The desired feel:

> Players do not shove each other. They route around / get blocked by each other.

**Avoid reintroducing `NavigationAgent2D` avoidance for player-vs-player unless
there is a clear reason.** Do not accidentally reintroduce "players shove each
other around" unless the design changes.

---

## EXP is server-authoritative on purpose

The **client never knows creature HP** — `take_damage.rpc_id(1, …)` runs only on
the server, and `call_local` does *not* fire for a targeted `rpc_id` to another
peer (verified empirically). So client-side kill detection is impossible; the
server is the only source of truth for the kill and the killer.

This is why `add_exp` is an `any_peer` RPC sent *by the server*, not a
client-side increment. Don't "simplify" it into client-side EXP — it would be
trivially spoofable and the client doesn't have the information anyway.

(EXP, not a raw kill count, was chosen as the natural hook for future leveling —
same code cost, fits the Lineage-classic feel. Leveling itself is deferred; see
[ROADMAP.md](ROADMAP.md).)

---

## NavigationRegion2D is not collision

Players can walk outside a navigation polygon unless movement code uses
navigation paths or physics walls block them.

Actual blocking is done through `StaticBody2D` + `CollisionShape2D` (boundary
walls + cliff obstacles). Use manual walls for now; do not start a full TileMap
system yet unless it becomes clearly necessary.

---

## Known issue — server/client version mismatch breaks replication

When adding synced properties, all clients and the server must run the same build.

Errors like:

```text
Invalid packet received. Size too small.
on_sync_receive: Condition "err" is true
```

usually mean:

- local client changed replication schema
- server is still old
- another client is still old

Fix:

- re-export
- redeploy server (see [DEPLOYMENT.md](DEPLOYMENT.md))
- fully restart clients

> Note: adding an **RPC** does not change the replication schema, but it still
> requires a redeploy if the server runs the affected script. Adding a **synced
> property** is the case that causes the packet-size mismatch above.

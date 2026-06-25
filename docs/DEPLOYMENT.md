# DEPLOYMENT.md — Server, networking & ops

> **Read this before touching server behavior, networking, or deploying.**
> Local-only changes do NOT affect the live VPS unless redeployed.
>
> **Real IPs / hostnames / usernames are NOT in this file** (public repo). They
> live in `docs/INFRA.local.md`, which is gitignored. Placeholders below
> (`<PUBLIC_IP>`, `<TAILSCALE_IP>`, `<server-user>`) map to entries there.

---

## Server

- Vultr VPS in **Seattle**
- Ubuntu 24.04 x64
- Headless Godot exported server build
- Runs as a `systemd` service named:

```bash
elysium.service
```

Server user: `<server-user>` (see `docs/INFRA.local.md`)

Live server folder:

```bash
/home/<server-user>/elysium
```

Release folder:

```bash
/home/<server-user>/releases
```

---

## Admin access

- SSH is locked down to **Tailscale-only**
- Public SSH is closed
- Public game port UDP 32100 remains open

IPs are in `docs/INFRA.local.md`:

- `<TAILSCALE_IP>` — VPS Tailscale IP (admin/SSH; not publicly routable)
- `<PUBLIC_IP>` — public game server IP (UDP 32100; also hardcoded in `server.gd`)

---

## Deployment flow

The live server runs from `/home/<server-user>/elysium`.

Helper deploy script:

```bash
deploy_elysium <release-folder-name>
```

Example:

```bash
deploy_elysium elysium-2026-03-17
```

The simple deploy flow:

1. Export server build locally.
2. Upload files to a new folder under:

```bash
/home/<server-user>/releases/
```

3. Run:

```bash
deploy_elysium <release-folder-name>
```

The deploy script stops the service, copies the release files into the live folder, starts the service again, and shows status.

Service control:

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

## Important networking state

The client connects to the live server by **hardcoded IP** (`<PUBLIC_IP>`). The
connect is triggered when the player clicks JOIN (`_on_join_pressed` in
`server.gd`):

```gdscript
connect_to_server("<PUBLIC_IP>")   # real IP is in server.gd / INFRA.local.md
```

(Note: there is also a commented-out `connect_to_server(...)` in `_ready` — the
active path is the Join button, not `_ready`.)

> The public IP is **already in `server.gd`** (it has to be — the client dials
> it), so it's inherently public. The placeholder here is just to keep this doc
> free of infra specifics; it is not a secret.

So if testing against the live server, code changes that affect server behavior require:

1. Export new server build.
2. Upload to VPS release folder.
3. Run `deploy_elysium`.

**Local-only changes will not affect the live VPS server unless redeployed.**

The hardcoded IP is fine for early prototype. Later, consider a config file, a
simple server-select UI, or an environment-specific setting — but do not
overbuild this yet.

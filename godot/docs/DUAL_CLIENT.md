## Clashpoint Year-1 — dual client (desktop + browser)

### Desktop (macOS)

```bash
./godot/run.sh
```

Exported app (after templates installed):

```bash
./godot/run.sh --headless --export-release "macOS" export/Clashpoint.app
open godot/export/Clashpoint.app
```

### Browser (HTML5)

```bash
# one-time: install templates
./godot/scripts/install_export_templates.sh   # or Godot → Manage Export Templates

./godot/scripts/export_web.sh
cd godot/export/web && python3 -m http.server 8081
```

Open http://127.0.0.1:8081/

**Verified:** web export produces `index.html` + `index.wasm` (~38MB) + `index.pck`; HTTP 200 smoke on `/index.html` and `/index.wasm`. Renderer for web = `gl_compatibility`.

### Modes (main menu)

| Button | Scene |
|--------|--------|
| Training | map_training (3 bots) |
| Casual Bots | map_dust2 (5 bots, rounds) |
| Deathmatch | map_mirage mode=deathmatch |
| Ranked | Matchmaking stub → bot match after ~2s |
| Host LAN | NetSession.host_lan(7777) → Dust2 |

### LAN / dedicated

```bash
./godot/scripts/run_dedicated.sh
# or in-game: Host LAN
NetSession.host_lan(7777)
NetSession.join_lan("127.0.0.1", 7777)
```

See [`NET_PROTOCOL.md`](NET_PROTOCOL.md).

### Controls in match

- WASD move, Shift walk, Ctrl crouch, Space jump
- LMB shoot, R reload, 1/2/3 weapons, 4–7 grenades
- B buy (freeze + buy zone): F1–F7 purchase
- V plant (on site), E defuse
- Esc menu

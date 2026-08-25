# Year-1 scaffold status

Implemented against the Clashpoint year-1 roadmap (Godot desktop + HTML5).

| Quarter todo | Evidence |
|--------------|----------|
| Q1 app shell | Main menu, autoloads, folders, macOS `.app` export |
| Q1 combat | 18 weapons + spray patterns from `index.html`, hitscan, armor |
| Q1 bots/map/web | Dust2 arena + navmesh + 5 bots + HUD; web export HTTP smoke |
| Q2 rounds/bomb/nades | RoundManager freeze/live/plant/defuse; grenades g=19.2 |
| Q2 eco/audio/map2 | Economy + buy menu; AudioBus beeps; Mirage/Inferno arenas; bot plant |
| Q3 arsenal/ladders/LAN | m4a1s+zeus; ladders; NetSession ENet host; dedicated stub |
| Q4 MM/ranked/ship | Matchmaking queue stub + MMR; dual client docs + exports |

Verify:

```bash
./godot/run.sh --headless -s res://scripts/verify_pmove.gd
./godot/run.sh --headless -s res://scripts/verify_year1.gd
./godot/run.sh --headless -s res://scripts/verify_match_boot.gd
./godot/run.sh --headless -s res://scripts/verify_ship.gd
```

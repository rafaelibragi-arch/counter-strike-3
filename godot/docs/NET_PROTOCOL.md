# Clashpoint network protocol (Year-1 freeze draft)

## Modes

| Mode | Transport | Authority |
|------|-----------|-----------|
| OFFLINE | local | client |
| LISTEN | ENet UDP | host player |
| DEDICATED_CLIENT | ENet / WebSocket | dedicated headless |

## Tick

- Simulation: **64 Hz**
- Snapshot: 64/s
- Client interp delay: 100–200 ms (planned)

## Messages (planned)

1. `ClMove` — wishdir, buttons, viewangles, client_time
2. `SvSnapshot` — positions, hp, ammo, bomb state, tick
3. `ClShoot` — eye ray, weapon_id, fire_id (server validates)
4. `SvHit` — confirmed damage / kill
5. `SvRound` — state machine sync

## API stubs

```gdscript
NetSession.host_lan(7777)
NetSession.join_lan("192.168.1.10", 7777)
NetSession.disconnect_session()
Matchmaking.queue_casual()
Matchmaking.queue_ranked()
```

Ranked MMR stored in `Matchmaking.mmr` / `GameState.mmr` (Elo-lite).

# Veriisha

A turn-based survival game. You wake alone on a planet whose winter runs a third
of a year, beside a wrecked ship holding two hundred and twenty frozen colonists.
You get seven days of summer to prepare. Then the dark, and one of them dies every
day whether you reach them or not.

This app does three things: it simulates that survival run day by day, it forces
real trade-offs with a fixed budget of actions, and it remembers who you saved.

## Current state

This is the **headless engine** build. The whole game is decisions and numbers,
so the rules are proven in a console before any interface is drawn. There is no
UI yet - that is the next build. The engine is pure Dart with no Flutter
dependency, which lets it run and test here and drop into the Flutter app later
with no rewrite.

## Running it

Install the Dart SDK, then from the project root:

```
dart pub get
dart test            # run the rule + invariant tests
dart run bin/sim.dart   # play a full scripted run, printed day by day
```

`bin/sim.dart` plays a complete run with a fixed seed and prints a daily digest,
ending on one of the two endings with the plain count line. That is the proof the
simulation works.

## Layout

- `lib/models` - the game state as immutable value types (maps the data model)
- `lib/config` - the single config object; difficulty is multipliers over it
- `lib/engine` - the phase machine, the day-end resolver, the action economy, RNG
- `lib/systems` - one module per subsystem (needs, power, medical, threats, ...)
- `lib/content` - the static data: the 220-name roster, sites, buildings, events
- `bin` - the console harnesses

## License

MIT. See `LICENSE`.

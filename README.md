# AFTERFALL — Greywood (Prototype 0.1)

Mobile-first landscape stylized 3D survival prototype made with Godot 4.4.1.

## Playable slice
- Survivor movement, angled follow camera, keyboard and touch controls.
- Procedural Greywood town block: houses, shop, garage, gas station, camp and roadside trees.
- Salvageable objects with durability and material drops.
- Infected that detect and follow the player.
- Basic melee combat, health, stamina, inventory counters, camp rest and local save/load.

## Controls
Desktop: WASD/arrows move, Shift sprint, E interact/salvage/rest, Space attack.
Android: left virtual joystick; ACTION and ATTACK buttons on the right.

Open in Godot 4.4.1+ and run `scenes/Main.tscn`.

GitHub Actions builds a debug APK on push to main or manual workflow dispatch. Download the `afterfall-android-debug` artifact.

This is an early playable foundation. Geometry is procedural placeholder art; dedicated models, interiors and richer animation are future milestones.

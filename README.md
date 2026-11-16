# ASHENFORGE: Dragon's Tribute

A portrait-mode dark fantasy blacksmith roguelite built with Godot 4.4.1.

## Project structure

- `scenes/` — game scenes.
- `scripts/` — game state, forging, economy, saving, visuals and screen controller.
- `data/` — JSON definitions for weapons, materials and upgrades.
- `assets/` — source artwork (SVG).
- `.github/workflows/` — cloud Android build.

## Current playable systems

- Forge strikes, critical hits, heat and blade durability.
- Cooling the blade between forging sessions.
- Blade sale value based on quality and remaining durability.
- Dragon tribute and chapter progression.
- Local save data for gold, chapter, blade stats and upgrades.
- First upgrade path: improved bellows.

## Build from a phone

1. Open the repository's **Actions** tab.
2. Select **AshenForge Android APK**.
3. Tap **Run workflow**.
4. When the run succeeds, download the `ashenforge-android-debug` artifact.
5. Extract the ZIP and install the APK on Android.

No local editor is needed for the cloud build. The project itself can be opened in Godot 4.4.1 on desktop.

## Development note

This is a structured playable foundation, not yet the final full game. Planned milestones include weapon recipes, material selection, additional upgrades, random events, dragon encounters, sound, richer animations and balancing.

extends RefCounted
## Monster roster, stage progression and balance numbers.
## HP is tuned against player damage in main.gd: fists 8, hatchet 16, crowbar 18,
## bow 22, spear 28 (plus +6% per player level).

const MONSTERS := {
    # ---------------------------------------------------------------- stage 1
    "walker": {
        "name": "Заражённый", "kind": "walker", "hp": 30.0, "speed": 1.4, "damage": 6.0, "xp": 15,
        "scale": 1.0, "reach": 1.35, "special": "none", "boss": false,
        "skin": Color(0.60, 0.67, 0.56), "shirt": Color(0.58, 0.57, 0.52), "pants": Color(0.30, 0.32, 0.27),
    },
    "worker": {
        "name": "Гнилой работник", "kind": "walker", "hp": 45.0, "speed": 1.3, "damage": 8.0, "xp": 22,
        "scale": 1.06, "reach": 1.4, "special": "none", "boss": false,
        "skin": Color(0.66, 0.62, 0.52), "shirt": Color(0.24, 0.36, 0.52), "pants": Color(0.22, 0.30, 0.46),
    },
    "boss_elder": {
        "name": "Староста-распухший", "kind": "walker", "hp": 300.0, "speed": 1.1, "damage": 16.0, "xp": 300,
        "scale": 1.55, "reach": 2.0, "special": "slam", "boss": true, "extras": ["bloat", "glow_eyes", "sash"],
        "skin": Color(0.66, 0.70, 0.52), "shirt": Color(0.42, 0.30, 0.22), "pants": Color(0.22, 0.20, 0.18),
        "glow": Color(0.95, 0.80, 0.25),
    },
    # ---------------------------------------------------------------- stage 2
    "stalker": {
        "name": "Ходульник", "kind": "stalker", "hp": 60.0, "speed": 2.6, "damage": 9.0, "xp": 35,
        "scale": 1.0, "reach": 2.7, "special": "long_reach", "boss": false,
        "skin": Color(0.78, 0.55, 0.62), "accent": Color(0.55, 0.14, 0.24), "dark": Color(0.07, 0.06, 0.08),
    },
    "boss_matriarch": {
        "name": "Матка ходульников", "kind": "stalker", "hp": 600.0, "speed": 2.2, "damage": 18.0, "xp": 600,
        "scale": 1.6, "reach": 3.6, "special": "long_reach", "boss": true, "extras": ["extra_spines", "egg_sacs", "glow_eyes"],
        "skin": Color(0.62, 0.50, 0.66), "accent": Color(0.35, 0.10, 0.34), "dark": Color(0.05, 0.04, 0.07),
        "glow": Color(1.0, 0.45, 0.2),
    },
    # ---------------------------------------------------------------- stage 3
    "brute": {
        "name": "Когтистый брут", "kind": "brute", "hp": 110.0, "speed": 2.2, "damage": 14.0, "xp": 60,
        "scale": 1.0, "reach": 1.9, "special": "lunge", "boss": false,
        "skin": Color(0.46, 0.20, 0.20), "accent": Color(0.82, 0.76, 0.62), "glow": Color(0.95, 0.15, 0.1),
    },
    "boss_ripper": {
        "name": "Алый потрошитель", "kind": "brute", "hp": 1000.0, "speed": 2.4, "damage": 26.0, "xp": 1000,
        "scale": 1.45, "reach": 2.6, "special": "lunge", "boss": true, "extras": ["arm_blades", "horns"],
        "skin": Color(0.62, 0.10, 0.12), "accent": Color(0.90, 0.86, 0.72), "glow": Color(1.0, 0.25, 0.1),
    },
    # ---------------------------------------------------------------- stage 4
    "ogre": {
        "name": "Огр-булавоносец", "kind": "ogre", "hp": 200.0, "speed": 1.2, "damage": 22.0, "xp": 90,
        "scale": 1.0, "reach": 2.4, "special": "slam", "boss": false,
        "skin": Color(0.78, 0.60, 0.50), "accent": Color(0.86, 0.82, 0.70), "cloth": Color(0.58, 0.38, 0.18),
    },
    "boss_fistking": {
        "name": "Король шипастого кулака", "kind": "ogre", "hp": 1800.0, "speed": 1.2, "damage": 36.0, "xp": 1800,
        "scale": 1.45, "reach": 3.2, "special": "slam", "boss": true, "extras": ["crown", "armor", "both_fists"],
        "skin": Color(0.60, 0.48, 0.44), "accent": Color(0.88, 0.84, 0.72), "cloth": Color(0.25, 0.26, 0.30),
    },
    # ---------------------------------------------------------------- stage 5
    "hybrid": {
        "name": "Гибрид-мутант", "kind": "brute", "hp": 300.0, "speed": 2.0, "damage": 24.0, "xp": 130,
        "scale": 1.1, "reach": 2.1, "special": "lunge", "boss": false, "extras": ["arm_blades"],
        "skin": Color(0.42, 0.44, 0.46), "accent": Color(0.78, 0.76, 0.70), "glow": Color(0.35, 0.85, 0.9),
    },
    "boss_smith": {
        "name": "Пепельный Кузнец", "kind": "ogre", "hp": 3000.0, "speed": 1.5, "damage": 48.0, "xp": 5000,
        "scale": 1.7, "reach": 3.6, "special": "slam", "boss": true, "extras": ["forge", "hammer", "cracks", "horns"],
        "skin": Color(0.32, 0.29, 0.29), "accent": Color(0.62, 0.58, 0.52), "cloth": Color(0.17, 0.16, 0.16),
        "glow": Color(1.0, 0.45, 0.1),
    },
}

## One entry per stage. `spawns` lists the regular monsters, `boss` appears at the stage start.
const STAGES := [
    {"name": "Заброшенная деревня", "spawns": ["walker", "walker", "walker", "worker", "worker"], "boss": "boss_elder",
     "sun": Color(1.0, 0.93, 0.82), "sky": Color(0.11, 0.14, 0.13)},
    {"name": "Туманный лес", "spawns": ["stalker", "stalker", "stalker", "walker", "worker"], "boss": "boss_matriarch",
     "sun": Color(0.78, 0.92, 0.88), "sky": Color(0.08, 0.13, 0.12)},
    {"name": "Заброшенные шахты", "spawns": ["brute", "brute", "brute", "stalker", "stalker"], "boss": "boss_ripper",
     "sun": Color(0.95, 0.72, 0.62), "sky": Color(0.14, 0.08, 0.07)},
    {"name": "Руины", "spawns": ["ogre", "ogre", "brute", "brute", "stalker"], "boss": "boss_fistking",
     "sun": Color(0.92, 0.84, 0.70), "sky": Color(0.13, 0.12, 0.10)},
    {"name": "Лаборатория Кузни", "spawns": ["hybrid", "hybrid", "hybrid", "ogre", "ogre"], "boss": "boss_smith",
     "sun": Color(0.82, 0.62, 0.50), "sky": Color(0.10, 0.06, 0.05)},
]

static func get_monster(id: String) -> Dictionary:
    return MONSTERS.get(id, MONSTERS["walker"])

static func get_stage(index: int) -> Dictionary:
    return STAGES[clampi(index, 0, STAGES.size() - 1)]

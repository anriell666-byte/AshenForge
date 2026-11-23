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
    # ---------------------------------------------------------------- district fauna
    "crawler": {
        "name": "Ползун", "kind": "walker", "hp": 18.0, "speed": 2.3, "damage": 4.0, "xp": 10,
        "scale": 0.72, "reach": 1.1, "special": "none", "boss": false,
        "skin": Color(0.55, 0.60, 0.50), "shirt": Color(0.42, 0.38, 0.30), "pants": Color(0.26, 0.26, 0.22),
    },
    "hound": {
        "name": "Гончая", "kind": "brute", "hp": 42.0, "speed": 3.3, "damage": 8.0, "xp": 28,
        "scale": 0.72, "reach": 1.5, "special": "lunge", "boss": false,
        "skin": Color(0.38, 0.36, 0.34), "accent": Color(0.78, 0.74, 0.62), "glow": Color(0.9, 0.7, 0.15),
    },
    "bramble": {
        "name": "Терновник", "kind": "stalker", "hp": 85.0, "speed": 1.9, "damage": 11.0, "xp": 45,
        "scale": 0.95, "reach": 2.5, "special": "long_reach", "boss": false, "extras": ["extra_spines"],
        "skin": Color(0.40, 0.52, 0.32), "accent": Color(0.55, 0.32, 0.14), "dark": Color(0.06, 0.08, 0.05),
    },
    "patient": {
        "name": "Пациент", "kind": "walker", "hp": 55.0, "speed": 1.5, "damage": 9.0, "xp": 30,
        "scale": 1.0, "reach": 1.35, "special": "none", "boss": false,
        "skin": Color(0.74, 0.76, 0.72), "shirt": Color(0.62, 0.76, 0.80), "pants": Color(0.55, 0.68, 0.72),
    },
    "orderly": {
        "name": "Санитар", "kind": "walker", "hp": 95.0, "speed": 1.7, "damage": 13.0, "xp": 48,
        "scale": 1.14, "reach": 1.5, "special": "none", "boss": false,
        "skin": Color(0.64, 0.68, 0.58), "shirt": Color(0.82, 0.84, 0.78), "pants": Color(0.30, 0.44, 0.40),
    },
    "spitter": {
        "name": "Плевун", "kind": "walker", "hp": 50.0, "speed": 1.1, "damage": 10.0, "xp": 40,
        "scale": 1.0, "reach": 1.3, "special": "spit", "boss": false, "extras": ["bloat"],
        "skin": Color(0.55, 0.72, 0.38), "shirt": Color(0.36, 0.44, 0.24), "pants": Color(0.24, 0.28, 0.20),
    },
    "bloater": {
        "name": "Взрывник", "kind": "walker", "hp": 70.0, "speed": 1.0, "damage": 32.0, "xp": 50,
        "scale": 1.12, "reach": 1.6, "special": "explode", "boss": false, "extras": ["bloat", "glow_eyes"],
        "skin": Color(0.78, 0.66, 0.34), "shirt": Color(0.55, 0.36, 0.16), "pants": Color(0.28, 0.22, 0.14),
        "glow": Color(1.0, 0.55, 0.1),
    },
    "welder": {
        "name": "Сварщик", "kind": "walker", "hp": 125.0, "speed": 1.4, "damage": 14.0, "xp": 58,
        "scale": 1.1, "reach": 1.5, "special": "burn", "boss": false, "extras": ["glow_eyes"],
        "skin": Color(0.62, 0.58, 0.50), "shirt": Color(0.70, 0.38, 0.16), "pants": Color(0.22, 0.20, 0.18),
        "glow": Color(0.35, 0.8, 1.0),
    },
    "miner": {
        "name": "Шахтёр-мертвец", "kind": "walker", "hp": 150.0, "speed": 1.3, "damage": 17.0, "xp": 62,
        "scale": 1.1, "reach": 1.5, "special": "none", "boss": false, "extras": ["glow_eyes"],
        "skin": Color(0.52, 0.54, 0.50), "shirt": Color(0.78, 0.62, 0.16), "pants": Color(0.30, 0.30, 0.34),
        "glow": Color(1.0, 0.85, 0.3),
    },
    "cinder": {
        "name": "Угольщик", "kind": "brute", "hp": 230.0, "speed": 2.2, "damage": 20.0, "xp": 100,
        "scale": 1.05, "reach": 2.0, "special": "burn", "boss": false,
        "skin": Color(0.20, 0.17, 0.16), "accent": Color(0.55, 0.50, 0.44), "glow": Color(1.0, 0.45, 0.08),
    },
    # ---------------------------------------------------------------- mini bosses
    "mb_butcher": {
        "name": "Мясник Грейвуда", "kind": "brute", "hp": 260.0, "speed": 2.3, "damage": 14.0, "xp": 150,
        "scale": 1.3, "reach": 2.1, "special": "lunge", "boss": false, "mini": true, "extras": ["arm_blades"],
        "skin": Color(0.62, 0.40, 0.36), "accent": Color(0.82, 0.80, 0.74), "glow": Color(0.95, 0.2, 0.1),
    },
    "mb_hunter": {
        "name": "Охотник-перевёртыш", "kind": "stalker", "hp": 380.0, "speed": 2.7, "damage": 14.0, "xp": 260,
        "scale": 1.3, "reach": 3.2, "special": "spit,long_reach", "boss": false, "mini": true, "extras": ["glow_eyes", "extra_spines"],
        "skin": Color(0.52, 0.58, 0.40), "accent": Color(0.40, 0.26, 0.12), "dark": Color(0.05, 0.06, 0.04),
        "glow": Color(0.9, 0.9, 0.3),
    },
    "mb_gravedigger": {
        "name": "Могильщик", "kind": "ogre", "hp": 540.0, "speed": 1.2, "damage": 24.0, "xp": 300,
        "scale": 1.2, "reach": 2.6, "special": "slam", "boss": false, "mini": true, "extras": ["hammer"],
        "skin": Color(0.60, 0.58, 0.52), "accent": Color(0.78, 0.76, 0.66), "cloth": Color(0.22, 0.20, 0.26),
    },
    "mb_nurse": {
        "name": "Сестра милосердия", "kind": "walker", "hp": 440.0, "speed": 2.1, "damage": 17.0, "xp": 350,
        "scale": 1.3, "reach": 1.9, "special": "lunge", "boss": false, "mini": true, "extras": ["glow_eyes", "sash"],
        "skin": Color(0.80, 0.78, 0.74), "shirt": Color(0.90, 0.92, 0.90), "pants": Color(0.55, 0.20, 0.22),
        "glow": Color(0.9, 0.2, 0.25),
    },
    "mb_welder": {
        "name": "Главный сварщик", "kind": "walker", "hp": 560.0, "speed": 1.5, "damage": 20.0, "xp": 400,
        "scale": 1.35, "reach": 1.9, "special": "burn,spit", "boss": false, "mini": true, "extras": ["glow_eyes", "bloat"],
        "skin": Color(0.58, 0.52, 0.46), "shirt": Color(0.80, 0.42, 0.14), "pants": Color(0.18, 0.18, 0.20),
        "glow": Color(0.4, 0.85, 1.0),
    },
    "mb_miner": {
        "name": "Старший забойщик", "kind": "ogre", "hp": 780.0, "speed": 1.3, "damage": 30.0, "xp": 450,
        "scale": 1.25, "reach": 2.7, "special": "slam", "boss": false, "mini": true, "extras": ["hammer", "armor"],
        "skin": Color(0.55, 0.52, 0.48), "accent": Color(0.78, 0.66, 0.24), "cloth": Color(0.32, 0.30, 0.20),
    },
    "mb_ash": {
        "name": "Пепельный страж", "kind": "brute", "hp": 950.0, "speed": 2.4, "damage": 30.0, "xp": 600,
        "scale": 1.4, "reach": 2.5, "special": "lunge,burn", "boss": false, "mini": true, "extras": ["horns", "arm_blades"],
        "skin": Color(0.22, 0.18, 0.17), "accent": Color(0.60, 0.54, 0.46), "glow": Color(1.0, 0.4, 0.08),
    },
    # ---------------------------------------------------------------- extra boss
    "boss_foreman": {
        "name": "Прораб-Исполин", "kind": "ogre", "hp": 1300.0, "speed": 1.3, "damage": 30.0, "xp": 1300,
        "scale": 1.5, "reach": 3.3, "special": "slam", "boss": true, "extras": ["armor", "hammer", "horns"],
        "skin": Color(0.58, 0.50, 0.42), "accent": Color(0.90, 0.72, 0.20), "cloth": Color(0.80, 0.46, 0.12),
    },
}

static func get_monster(id: String) -> Dictionary:
    return MONSTERS.get(id, MONSTERS["walker"])

static func has_special(id: String, name: String) -> bool:
    return String(get_monster(id).get("special", "none")).split(",").has(name)

## Regular drops: [resource, chance, min, max]. Mini bosses and bosses always drop extra (see infected.gd).
const LOOT := {
    "walker": ["cloth", 0.40, 1, 2], "worker": ["scrap", 0.40, 1, 2], "crawler": ["cloth", 0.25, 1, 1],
    "stalker": ["food", 0.40, 1, 2], "hound": ["food", 0.50, 1, 2], "bramble": ["wood", 0.55, 2, 3],
    "patient": ["medicine", 0.35, 1, 1], "orderly": ["medicine", 0.45, 1, 2], "spitter": ["plastic", 0.45, 1, 2],
    "bloater": ["fuel", 0.60, 1, 2], "welder": ["fuel", 0.55, 1, 2], "miner": ["stone", 0.65, 2, 3],
    "brute": ["scrap", 0.50, 2, 3], "ogre": ["stone", 0.55, 2, 4], "cinder": ["fuel", 0.65, 1, 3],
    "hybrid": ["plastic", 0.55, 2, 3],
}

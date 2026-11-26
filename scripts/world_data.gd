extends RefCounted
## Static data for the open world: districts, locked-district gates, quests and notes.
## One continuous map, 3x3 grid of 64 m cells centred on the Greywood village (0, 0).

const CELL := 64.0
const HALF := 32.0

## center: world XZ. spawns: [monster id, count] (random positions). boss / minis: [id, local x, local z].
## sun / sky tint the lighting while the player is inside.
const DISTRICTS := {
    "greywood": {
        "name": "Грейвуд", "center": Vector2(0, 0), "tier": 1,
        "ground": Color(0.28, 0.34, 0.27),
        "sun": Color(1.0, 0.93, 0.82), "sky": Color(0.11, 0.14, 0.13),
        "spawns": [["walker", 4], ["worker", 2], ["crawler", 2]],
        "boss": ["boss_elder", 0.0, -23.0],
        "minis": [["mb_butcher", 24.0, -24.0]],
        "fixed_spawns": [Vector2(5, -15), Vector2(21, 15), Vector2(-20, 22), Vector2(-25, -12), Vector2(26, -8), Vector2(2, 27)],
    },
    "woods": {
        "name": "Туманный лес", "center": Vector2(-64, 0), "tier": 2,
        "ground": Color(0.17, 0.25, 0.19),
        "sun": Color(0.78, 0.92, 0.88), "sky": Color(0.08, 0.13, 0.12),
        "spawns": [["stalker", 4], ["hound", 5], ["bramble", 4], ["crawler", 3]],
        "boss": ["boss_matriarch", -18.0, 18.0],
        "minis": [["mb_hunter", -14.0, -4.0], ["mb_gravedigger", 14.0, 10.0]],
    },
    "hospital": {
        "name": "Больница Св. Эльма", "center": Vector2(0, 64), "tier": 3,
        "ground": Color(0.44, 0.47, 0.46),
        "sun": Color(0.90, 0.96, 1.0), "sky": Color(0.10, 0.13, 0.15),
        "spawns": [["patient", 6], ["orderly", 4], ["spitter", 4]],
        "boss": ["boss_ripper", 0.0, 21.0],
        "minis": [["mb_nurse", 10.0, -4.0]],
    },
    "rustworks": {
        "name": "Ржавый завод", "center": Vector2(0, -64), "tier": 4,
        "ground": Color(0.29, 0.23, 0.19),
        "sun": Color(0.95, 0.72, 0.62), "sky": Color(0.14, 0.08, 0.07),
        "spawns": [["welder", 5], ["bloater", 4], ["worker", 4], ["brute", 3]],
        "boss": ["boss_foreman", 0.0, -22.0],
        "minis": [["mb_welder", -18.0, 5.0]],
        "locked": true,
    },
    "quarry": {
        "name": "Карьер", "center": Vector2(64, 0), "tier": 5,
        "ground": Color(0.42, 0.39, 0.33),
        "sun": Color(0.92, 0.84, 0.70), "sky": Color(0.13, 0.12, 0.10),
        "spawns": [["miner", 5], ["ogre", 3], ["brute", 4], ["hound", 3]],
        "boss": ["boss_fistking", 18.0, -4.0],
        "minis": [["mb_miner", -6.0, 12.0]],
        "locked": true,
    },
    "forge": {
        "name": "Кузня Пепла", "center": Vector2(64, -64), "tier": 6,
        "ground": Color(0.14, 0.12, 0.12),
        "sun": Color(0.82, 0.62, 0.50), "sky": Color(0.10, 0.06, 0.05),
        "spawns": [["cinder", 5], ["hybrid", 4], ["ogre", 3]],
        "boss": ["boss_smith", 0.0, -10.0],
        "minis": [["mb_ash", -12.0, 10.0], ["mb_ash", 12.0, 10.0]],
        "locked": true,
    },
}

## Corner cells of the 3x3 grid are impassable cliffs.
const CLIFF_CELLS := [Vector2(-64, -64), Vector2(-64, 64), Vector2(64, 64)]

## Fences that keep a locked district closed. [centre x, centre z, size x, size z]
const GATES := {
    "rustworks": {"segments": [[0.0, -32.0, 64.0, 1.0]], "sign": Vector3(0, 0, -30.2),
        "hint": "Ворота завода заперты.\\nКлюч у старосты Грейвуда."},
    "quarry": {"segments": [[32.0, 0.0, 1.0, 64.0]], "sign": Vector3(30.2, 0, 0),
        "hint": "Проход в карьер завален.\\nНужно добыть камень и расчистить."},
    "forge": {"segments": [[64.0, -32.0, 64.0, 1.0], [32.0, -64.0, 1.0, 64.0]], "sign": Vector3(64.0, 0, -30.2),
        "hint": "Врата Кузни запечатаны.\\nНужны три печати боссов."},
}

# ---------------------------------------------------------------- quests
## goal types: kill_any {count, district?}, kill {id, count}, defeat {id}, collect {res, count}, visit {district}
## reward: xp, res {resource: amount} dropped at the player's feet, items {id: n}, unlock district id.
const QUESTS := {
    "q_first": {"title": "Первые шаги", "from": "Дневник Марты",
        "desc": "Победи 5 заражённых в Грейвуде.",
        "goal": {"type": "kill_any", "count": 5, "district": "greywood"},
        "reward": {"xp": 60, "res": {"cloth": 3, "food": 2}}},
    "q_explore": {"title": "Разведка", "from": "Радиосообщение",
        "desc": "Дойди до Больницы Св. Эльма на юге.",
        "goal": {"type": "visit", "district": "hospital"},
        "reward": {"xp": 80, "res": {"medicine": 2}}},
    "q_gate": {"title": "Ключ от завода", "from": "Записка бригадира",
        "desc": "Победи Старосту-распухшего: ключ от Ржавого завода у него.",
        "goal": {"type": "defeat", "id": "boss_elder"},
        "reward": {"xp": 150, "res": {"scrap": 6}, "unlock": "rustworks"}},
    "q_rubble": {"title": "Завал у карьера", "from": "Письмо шахтёра",
        "desc": "Добудь 4 камня. Каменные осыпи есть в лесу и в Грейвуде.",
        "goal": {"type": "collect", "res": "stone", "count": 4},
        "reward": {"xp": 120, "unlock": "quarry"}},
    "q_butcher": {"title": "Мясник из лавки", "from": "Записка торговца",
        "desc": "Убей Мясника Грейвуда на северо-востоке деревни.",
        "goal": {"type": "defeat", "id": "mb_butcher"},
        "reward": {"xp": 120, "res": {"essence": 2}}},
    "q_hunter": {"title": "След охотника", "from": "Дневник охотника",
        "desc": "Выследи Охотника-перевёртыша в Туманном лесу.",
        "goal": {"type": "defeat", "id": "mb_hunter"},
        "reward": {"xp": 150, "items": {"bandage": 2}}},
    "q_grave": {"title": "Тихий могильщик", "from": "Записка у часовни",
        "desc": "Упокой Могильщика на старом кладбище в лесу.",
        "goal": {"type": "defeat", "id": "mb_gravedigger"},
        "reward": {"xp": 150, "res": {"essence": 2}}},
    "q_matriarch": {"title": "Гнездо Матки", "from": "Клочок бумаги",
        "desc": "Уничтожь Матку ходульников в чаще леса.",
        "goal": {"type": "defeat", "id": "boss_matriarch"},
        "reward": {"xp": 300, "res": {"essence": 3}}},
    "q_meds": {"title": "Лекарства для Лены", "from": "Записка Лены",
        "desc": "Собери 4 единицы медикаментов.",
        "goal": {"type": "collect", "res": "medicine", "count": 4},
        "reward": {"xp": 100, "items": {"bandage": 3}}},
    "q_nurse": {"title": "Ночная смена", "from": "Журнал дежурств",
        "desc": "Победи Сестру милосердия в больнице.",
        "goal": {"type": "defeat", "id": "mb_nurse"},
        "reward": {"xp": 200, "items": {"medkit": 1}}},
    "q_seals": {"title": "Три печати", "from": "Бумаги доктора Рейна",
        "desc": "Добудь 3 печати: у Алого потрошителя, Прораба-Исполина и Короля кулака.",
        "goal": {"type": "collect", "res": "seal", "count": 3},
        "reward": {"xp": 400, "unlock": "forge"}},
    "q_welder": {"title": "Огонь в цехе", "from": "Заметка мастера",
        "desc": "Победи Главного сварщика на заводе.",
        "goal": {"type": "defeat", "id": "mb_welder"},
        "reward": {"xp": 250, "res": {"fuel": 4}}},
    "q_miner": {"title": "Забой", "from": "Записка штейгера",
        "desc": "Победи Старшего забойщика в карьере.",
        "goal": {"type": "defeat", "id": "mb_miner"},
        "reward": {"xp": 280, "res": {"essence": 2, "stone": 4}}},
    "q_smith": {"title": "Пепельный Кузнец", "from": "Приказ Кузнеца",
        "desc": "Войди в Кузню и победи Пепельного Кузнеца.",
        "goal": {"type": "defeat", "id": "boss_smith"},
        "reward": {"xp": 1500, "res": {"essence": 5}}},
}

# ---------------------------------------------------------------- notes
## pos is in world coordinates. Standing near it and pressing E reads the note.
## desk: draw a small desk under the paper (used inside houses).
const NOTES := [
    {"id": "n_camp", "title": "Правила лагеря", "pos": Vector3(-5.2, 0.0, 15.8), "desk": true, "quest": "",
     "text": "У верстака можно делать оружие и инструменты. Простые рецепты доступны сразу.\n\nСложное оружие требует чертёж: его носят мини-боссы и боссы. Дальше в лес, в больницу и на завод.\n\nДенег нет, есть только то, что унесёшь."},
    {"id": "n_marta", "title": "Дневник Марты", "pos": Vector3(-19.6, 0.0, -15.6), "desk": true, "quest": "q_first",
     "text": "День 9. Они ходят по улицам даже днём. Дима ушёл за водой и не вернулся.\n\nПока в Грейвуде столько заражённых, мы не выберемся. Если ты это читаешь: вычисти хотя бы пять, чтобы можно было пройти к дороге."},
    {"id": "n_foreman", "title": "Записка бригадира", "pos": Vector3(14.4, 0.0, -15.6), "desk": true, "quest": "q_gate",
     "text": "Ключ от заводских ворот забрал староста. Он распух и держит его при себе, сидит в северной части деревни.\n\nБез ключа на Ржавый завод не попасть: ворота я запер сам. Там цех, склад и прораб. Не ходи без хорошего оружия."},
    {"id": "n_radio", "title": "Радиосообщение", "pos": Vector3(-20.6, 0.0, 13.2), "desk": true, "quest": "q_explore",
     "text": "...Больница Святого Эльма на юге ещё держится. Там остались лекарства и бумаги доктора Рейна. Но коридоры полны пациентов. Повторяю: идите по дороге на юг..."},
    {"id": "n_shop", "title": "Записка торговца", "pos": Vector3(15.4, 0.0, 6.4), "desk": true, "quest": "q_butcher",
     "text": "Мясник вернулся. Раньше он продавал мясо на рынке, а теперь бродит у северо-восточной ограды и рычит. Лавку не открыть, пока он рядом.\n\nКто его уберёт, получит эссенцию из моего тайника."},
    {"id": "n_miner", "title": "Письмо шахтёра", "pos": Vector3(-14.8, 0.0, -0.4), "desk": true, "quest": "q_rubble",
     "text": "Брат, дорога в карьер завалена камнями, обвал был ночью. Расчистить можно кирками, но без камня их не сделать.\n\nКаменные осыпи видел в лесу и у восточной дороги. Принеси четыре, и завал снимут."},
    {"id": "n_hunter", "title": "Дневник охотника", "pos": Vector3(-78.0, 0.0, -9.0), "desk": true, "quest": "q_hunter",
     "text": "Ставил силки у хижины. Что-то ходит на двух ногах, но по следам на четырёх. Оно слышит дыхание. Если идти тихо, на открытом месте оно не нападает.\n\nНа арбалет у меня остался чертёж, но он у него."},
    {"id": "n_chapel", "title": "Записка у часовни", "pos": Vector3(-49.0, 0.0, 17.5), "desk": false, "quest": "q_grave",
     "text": "Могильщик не ушёл, он продолжает копать. По ночам слышно лопату. Тяжёлый топор из кладбищенской сторожки я прячу у него, а его самого лучше бить издалека."},
    {"id": "n_lair", "title": "Клочок бумаги", "pos": Vector3(-76.0, 0.0, 12.0), "desk": false, "quest": "q_matriarch",
     "text": "Гнездо в глубине леса. Там яйца, а над ними она, огромная и пятнистая. Ходульники сторожат подходы. Не лезь одна."},
    {"id": "n_lena", "title": "Записка Лены", "pos": Vector3(-8.0, 0.0, 58.0), "desk": true, "quest": "q_meds",
     "text": "Мне нужны лекарства. Хотя бы четыре упаковки. Они лежат в ящиках в палатах и у санитаров. Кто принесёт, тому бинты и мой пайок."},
    {"id": "n_shift", "title": "Журнал дежурств", "pos": Vector3(8.0, 0.0, 62.0), "desk": true, "quest": "q_nurse",
     "text": "Ночная сестра отказалась уходить после смены. Теперь она обходит палаты и ищет, кому сделать укол. Чертёж аптечки у неё в нагрудном кармане."},
    {"id": "n_rein", "title": "Бумаги доктора Рейна", "pos": Vector3(0.0, 0.0, 70.0), "desk": true, "quest": "q_seals",
     "text": "Кузня на северо-востоке запечатана тремя печатями. Они у тех, кого мы не смогли остановить: Алый потрошитель из нашего двора, Прораб с завода, Король кулака из карьера.\n\nКто соберёт три печати, тот откроет Кузню. И сам решит, стоит ли."},
    {"id": "n_master", "title": "Заметка мастера", "pos": Vector3(-24.0, 0.0, -78.0), "desk": true, "quest": "q_welder",
     "text": "Главный сварщик не снимает маску. Он поджигает всё, что видит, и плюётся огнём. Бейте его издалека, лучше арбалетом.\n\nЧертёж бензопилы он держит под фартуком."},
    {"id": "n_foreman_log", "title": "Журнал прораба", "pos": Vector3(6.0, 0.0, -58.0), "desk": false, "quest": "",
     "text": "Смена не закончилась. Люди ушли, а прораб остался с молотом. Он до сих пор хочет, чтобы всё работало.\n\nСхема кузни на стене: печи работают на печатях."},
    {"id": "n_steiger", "title": "Записка штейгера", "pos": Vector3(46.0, 0.0, -17.0), "desk": true, "quest": "q_miner",
     "text": "Забойщик спустился в шахту и вышел другим. Теперь он бьёт кувалдой в одну точку, пока не рухнет порода. Следи за землёй под ногами: перед ударом он замахивается высоко."},
    {"id": "n_smith", "title": "Приказ Кузнеца", "pos": Vector3(64.0, 0.0, -48.0), "desk": false, "quest": "q_smith",
     "text": "Огонь не должен гаснуть. Тот, кто пришёл с печатями, пусть выйдет к наковальне. Я кую новый мир из пепла, и в нём не будет места слабым."},
]

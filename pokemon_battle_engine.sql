-- ============================================================
-- POKEMON BATTLE ENGINE - DB2 for i
-- Gen 1 Data Model & Seed Data
-- ============================================================

-- ============================================================
-- TYPES
-- ============================================================
CREATE OR REPLACE TABLE NHAGENCO1.TYPES (
    TYPE_ID     SMALLINT     NOT NULL,
    TYPE_NAME   VARCHAR(10)  NOT NULL,
    PRIMARY KEY (TYPE_ID)
);

INSERT INTO NHAGENCO1.TYPES VALUES ( 1, 'NORMAL');
INSERT INTO NHAGENCO1.TYPES VALUES ( 2, 'FIRE');
INSERT INTO NHAGENCO1.TYPES VALUES ( 3, 'WATER');
INSERT INTO NHAGENCO1.TYPES VALUES ( 4, 'ELECTRIC');
INSERT INTO NHAGENCO1.TYPES VALUES ( 5, 'GRASS');
INSERT INTO NHAGENCO1.TYPES VALUES ( 6, 'ICE');
INSERT INTO NHAGENCO1.TYPES VALUES ( 7, 'FIGHTING');
INSERT INTO NHAGENCO1.TYPES VALUES ( 8, 'POISON');
INSERT INTO NHAGENCO1.TYPES VALUES ( 9, 'GROUND');
INSERT INTO NHAGENCO1.TYPES VALUES (10, 'FLYING');
INSERT INTO NHAGENCO1.TYPES VALUES (11, 'PSYCHIC');
INSERT INTO NHAGENCO1.TYPES VALUES (12, 'BUG');
INSERT INTO NHAGENCO1.TYPES VALUES (13, 'ROCK');
INSERT INTO NHAGENCO1.TYPES VALUES (14, 'GHOST');
INSERT INTO NHAGENCO1.TYPES VALUES (15, 'DRAGON');

-- ============================================================
-- TYPE EFFECTIVENESS
-- Gen 1 matchup chart (only non-1.0 multipliers stored)
-- If a matchup is not in this table, assume 1.0x
-- ============================================================
CREATE OR REPLACE TABLE NHAGENCO1.TYPE_EFFECT (
    ATK_TYPE    SMALLINT       NOT NULL,
    DEF_TYPE    SMALLINT       NOT NULL,
    MULTIPLIER  DECIMAL(3, 1)  NOT NULL,
    PRIMARY KEY (ATK_TYPE, DEF_TYPE),
    FOREIGN KEY (ATK_TYPE) REFERENCES NHAGENCO1.TYPES(TYPE_ID),
    FOREIGN KEY (DEF_TYPE) REFERENCES NHAGENCO1.TYPES(TYPE_ID)
);

-- NORMAL attacking
INSERT INTO NHAGENCO1.TYPE_EFFECT VALUES (1, 13, 0.5);   -- Normal vs Rock
INSERT INTO NHAGENCO1.TYPE_EFFECT VALUES (1, 14, 0.0);   -- Normal vs Ghost

-- FIRE attacking
INSERT INTO NHAGENCO1.TYPE_EFFECT VALUES (2, 2,  0.5);   -- Fire vs Fire
INSERT INTO NHAGENCO1.TYPE_EFFECT VALUES (2, 3,  0.5);   -- Fire vs Water
INSERT INTO NHAGENCO1.TYPE_EFFECT VALUES (2, 5,  2.0);   -- Fire vs Grass
INSERT INTO NHAGENCO1.TYPE_EFFECT VALUES (2, 6,  2.0);   -- Fire vs Ice
INSERT INTO NHAGENCO1.TYPE_EFFECT VALUES (2, 12, 2.0);   -- Fire vs Bug
INSERT INTO NHAGENCO1.TYPE_EFFECT VALUES (2, 13, 0.5);   -- Fire vs Rock
INSERT INTO NHAGENCO1.TYPE_EFFECT VALUES (2, 15, 0.5);   -- Fire vs Dragon

-- WATER attacking
INSERT INTO NHAGENCO1.TYPE_EFFECT VALUES (3, 2,  2.0);   -- Water vs Fire
INSERT INTO NHAGENCO1.TYPE_EFFECT VALUES (3, 3,  0.5);   -- Water vs Water
INSERT INTO NHAGENCO1.TYPE_EFFECT VALUES (3, 5,  0.5);   -- Water vs Grass
INSERT INTO NHAGENCO1.TYPE_EFFECT VALUES (3, 9,  2.0);   -- Water vs Ground
INSERT INTO NHAGENCO1.TYPE_EFFECT VALUES (3, 13, 2.0);   -- Water vs Rock
INSERT INTO NHAGENCO1.TYPE_EFFECT VALUES (3, 15, 0.5);   -- Water vs Dragon

-- ELECTRIC attacking
INSERT INTO NHAGENCO1.TYPE_EFFECT VALUES (4, 3,  2.0);   -- Electric vs Water
INSERT INTO NHAGENCO1.TYPE_EFFECT VALUES (4, 4,  0.5);   -- Electric vs Electric
INSERT INTO NHAGENCO1.TYPE_EFFECT VALUES (4, 5,  0.5);   -- Electric vs Grass
INSERT INTO NHAGENCO1.TYPE_EFFECT VALUES (4, 9,  0.0);   -- Electric vs Ground
INSERT INTO NHAGENCO1.TYPE_EFFECT VALUES (4, 10, 2.0);   -- Electric vs Flying
INSERT INTO NHAGENCO1.TYPE_EFFECT VALUES (4, 15, 0.5);   -- Electric vs Dragon

-- GRASS attacking
INSERT INTO NHAGENCO1.TYPE_EFFECT VALUES (5, 2,  0.5);   -- Grass vs Fire
INSERT INTO NHAGENCO1.TYPE_EFFECT VALUES (5, 3,  2.0);   -- Grass vs Water
INSERT INTO NHAGENCO1.TYPE_EFFECT VALUES (5, 5,  0.5);   -- Grass vs Grass
INSERT INTO NHAGENCO1.TYPE_EFFECT VALUES (5, 8,  0.5);   -- Grass vs Poison
INSERT INTO NHAGENCO1.TYPE_EFFECT VALUES (5, 9,  2.0);   -- Grass vs Ground
INSERT INTO NHAGENCO1.TYPE_EFFECT VALUES (5, 10, 0.5);   -- Grass vs Flying
INSERT INTO NHAGENCO1.TYPE_EFFECT VALUES (5, 12, 0.5);   -- Grass vs Bug
INSERT INTO NHAGENCO1.TYPE_EFFECT VALUES (5, 13, 2.0);   -- Grass vs Rock
INSERT INTO NHAGENCO1.TYPE_EFFECT VALUES (5, 15, 0.5);   -- Grass vs Dragon

-- ICE attacking
INSERT INTO NHAGENCO1.TYPE_EFFECT VALUES (6, 2,  0.5);   -- Ice vs Fire  -- Gen 1: Ice is not very effective vs Fire
INSERT INTO NHAGENCO1.TYPE_EFFECT VALUES (6, 3,  0.5);   -- Ice vs Water
INSERT INTO NHAGENCO1.TYPE_EFFECT VALUES (6, 5,  2.0);   -- Ice vs Grass
INSERT INTO NHAGENCO1.TYPE_EFFECT VALUES (6, 6,  0.5);   -- Ice vs Ice
INSERT INTO NHAGENCO1.TYPE_EFFECT VALUES (6, 9,  2.0);   -- Ice vs Ground
INSERT INTO NHAGENCO1.TYPE_EFFECT VALUES (6, 10, 2.0);   -- Ice vs Flying
INSERT INTO NHAGENCO1.TYPE_EFFECT VALUES (6, 15, 2.0);   -- Ice vs Dragon

-- FIGHTING attacking
INSERT INTO NHAGENCO1.TYPE_EFFECT VALUES (7, 1,  2.0);   -- Fighting vs Normal
INSERT INTO NHAGENCO1.TYPE_EFFECT VALUES (7, 6,  2.0);   -- Fighting vs Ice
INSERT INTO NHAGENCO1.TYPE_EFFECT VALUES (7, 8,  0.5);   -- Fighting vs Poison
INSERT INTO NHAGENCO1.TYPE_EFFECT VALUES (7, 10, 0.5);   -- Fighting vs Flying
INSERT INTO NHAGENCO1.TYPE_EFFECT VALUES (7, 11, 0.5);   -- Fighting vs Psychic
INSERT INTO NHAGENCO1.TYPE_EFFECT VALUES (7, 12, 0.5);   -- Fighting vs Bug
INSERT INTO NHAGENCO1.TYPE_EFFECT VALUES (7, 13, 2.0);   -- Fighting vs Rock
INSERT INTO NHAGENCO1.TYPE_EFFECT VALUES (7, 14, 0.0);   -- Fighting vs Ghost

-- POISON attacking
INSERT INTO NHAGENCO1.TYPE_EFFECT VALUES (8, 5,  2.0);   -- Poison vs Grass
INSERT INTO NHAGENCO1.TYPE_EFFECT VALUES (8, 8,  0.5);   -- Poison vs Poison
INSERT INTO NHAGENCO1.TYPE_EFFECT VALUES (8, 9,  0.5);   -- Poison vs Ground
INSERT INTO NHAGENCO1.TYPE_EFFECT VALUES (8, 13, 0.5);   -- Poison vs Rock
INSERT INTO NHAGENCO1.TYPE_EFFECT VALUES (8, 14, 0.5);   -- Poison vs Ghost
INSERT INTO NHAGENCO1.TYPE_EFFECT VALUES (8, 12, 2.0);   -- Poison vs Bug  -- Gen 1 specific

-- GROUND attacking
INSERT INTO NHAGENCO1.TYPE_EFFECT VALUES (9, 2,  2.0);   -- Ground vs Fire
INSERT INTO NHAGENCO1.TYPE_EFFECT VALUES (9, 4,  2.0);   -- Ground vs Electric
INSERT INTO NHAGENCO1.TYPE_EFFECT VALUES (9, 5,  0.5);   -- Ground vs Grass
INSERT INTO NHAGENCO1.TYPE_EFFECT VALUES (9, 8,  2.0);   -- Ground vs Poison
INSERT INTO NHAGENCO1.TYPE_EFFECT VALUES (9, 10, 0.0);   -- Ground vs Flying
INSERT INTO NHAGENCO1.TYPE_EFFECT VALUES (9, 12, 0.5);   -- Ground vs Bug
INSERT INTO NHAGENCO1.TYPE_EFFECT VALUES (9, 13, 2.0);   -- Ground vs Rock

-- FLYING attacking
INSERT INTO NHAGENCO1.TYPE_EFFECT VALUES (10, 4,  0.5);  -- Flying vs Electric
INSERT INTO NHAGENCO1.TYPE_EFFECT VALUES (10, 5,  2.0);  -- Flying vs Grass
INSERT INTO NHAGENCO1.TYPE_EFFECT VALUES (10, 7,  2.0);  -- Flying vs Fighting
INSERT INTO NHAGENCO1.TYPE_EFFECT VALUES (10, 12, 2.0);  -- Flying vs Bug
INSERT INTO NHAGENCO1.TYPE_EFFECT VALUES (10, 13, 0.5);  -- Flying vs Rock

-- PSYCHIC attacking
INSERT INTO NHAGENCO1.TYPE_EFFECT VALUES (11, 7,  2.0);  -- Psychic vs Fighting
INSERT INTO NHAGENCO1.TYPE_EFFECT VALUES (11, 8,  2.0);  -- Psychic vs Poison
INSERT INTO NHAGENCO1.TYPE_EFFECT VALUES (11, 11, 0.5);  -- Psychic vs Psychic

-- BUG attacking
INSERT INTO NHAGENCO1.TYPE_EFFECT VALUES (12, 2,  0.5);  -- Bug vs Fire
INSERT INTO NHAGENCO1.TYPE_EFFECT VALUES (12, 5,  2.0);  -- Bug vs Grass
INSERT INTO NHAGENCO1.TYPE_EFFECT VALUES (12, 7,  0.5);  -- Bug vs Fighting
INSERT INTO NHAGENCO1.TYPE_EFFECT VALUES (12, 8,  2.0);  -- Bug vs Poison -- Gen 1 specific
INSERT INTO NHAGENCO1.TYPE_EFFECT VALUES (12, 10, 0.5);  -- Bug vs Flying
INSERT INTO NHAGENCO1.TYPE_EFFECT VALUES (12, 11, 2.0);  -- Bug vs Psychic
INSERT INTO NHAGENCO1.TYPE_EFFECT VALUES (12, 14, 0.5);  -- Bug vs Ghost

-- ROCK attacking
INSERT INTO NHAGENCO1.TYPE_EFFECT VALUES (13, 2,  2.0);  -- Rock vs Fire
INSERT INTO NHAGENCO1.TYPE_EFFECT VALUES (13, 6,  2.0);  -- Rock vs Ice
INSERT INTO NHAGENCO1.TYPE_EFFECT VALUES (13, 7,  0.5);  -- Rock vs Fighting
INSERT INTO NHAGENCO1.TYPE_EFFECT VALUES (13, 9,  0.5);  -- Rock vs Ground
INSERT INTO NHAGENCO1.TYPE_EFFECT VALUES (13, 10, 2.0);  -- Rock vs Flying
INSERT INTO NHAGENCO1.TYPE_EFFECT VALUES (13, 12, 2.0);  -- Rock vs Bug

-- GHOST attacking
INSERT INTO NHAGENCO1.TYPE_EFFECT VALUES (14, 1,  0.0);  -- Ghost vs Normal  -- Gen 1 specific
INSERT INTO NHAGENCO1.TYPE_EFFECT VALUES (14, 14, 2.0);  -- Ghost vs Ghost
INSERT INTO NHAGENCO1.TYPE_EFFECT VALUES (14, 11, 0.0);  -- Ghost vs Psychic -- Gen 1 BUG: Psychic immune to Ghost

-- DRAGON attacking
INSERT INTO NHAGENCO1.TYPE_EFFECT VALUES (15, 15, 2.0);  -- Dragon vs Dragon

-- ============================================================
-- MOVE CATEGORIES
-- Gen 1: Physical/Special determined by type, not per-move
-- Physical types: Normal, Fighting, Poison, Ground, Flying,
--                 Bug, Rock, Ghost
-- Special types:  Fire, Water, Electric, Grass, Ice,
--                 Psychic, Dragon
-- ============================================================

-- ============================================================
-- MOVES
-- ============================================================
CREATE OR REPLACE TABLE NHAGENCO1.MOVES (
    MOVE_ID     SMALLINT       NOT NULL,
    MOVE_NAME   VARCHAR(20)    NOT NULL,
    TYPE_ID     SMALLINT       NOT NULL,
    POWER       SMALLINT,                     -- NULL = status move
    ACCURACY    SMALLINT       NOT NULL,      -- out of 100
    PP          SMALLINT       NOT NULL,
    IS_PHYSICAL CHAR(1)        NOT NULL        -- Y/N (Gen 1 rule: based on type)
                               DEFAULT 'N',
    EFFECT      VARCHAR(30)    DEFAULT NULL,   -- optional: BURN, POISON, FLINCH, etc.
    EFFECT_PCT  SMALLINT       DEFAULT 0,      -- chance of secondary effect
    PRIMARY KEY (MOVE_ID),
    FOREIGN KEY (TYPE_ID) REFERENCES NHAGENCO1.TYPES(TYPE_ID)
);

-- === NORMAL MOVES ===
INSERT INTO NHAGENCO1.MOVES VALUES (1,   'TACKLE',        1,  40,  100, 35, 'Y', NULL,      0);
INSERT INTO NHAGENCO1.MOVES VALUES (2,   'SCRATCH',       1,  40,  100, 35, 'Y', NULL,      0);
INSERT INTO NHAGENCO1.MOVES VALUES (3,   'POUND',         1,  40,  100, 35, 'Y', NULL,      0);
INSERT INTO NHAGENCO1.MOVES VALUES (4,   'BODY SLAM',     1,  85,  100, 15, 'Y', 'PARALYZE', 30);
INSERT INTO NHAGENCO1.MOVES VALUES (5,   'HYPER BEAM',    1, 150,   90,  5, 'Y', 'RECHARGE', 100);
INSERT INTO NHAGENCO1.MOVES VALUES (6,   'QUICK ATTACK',  1,  40,  100, 30, 'Y', 'PRIORITY', 100);
INSERT INTO NHAGENCO1.MOVES VALUES (7,   'SLASH',         1,  70,  100, 20, 'Y', 'HIGH CRIT', 100);
INSERT INTO NHAGENCO1.MOVES VALUES (8,   'STRENGTH',      1,  80,  100, 15, 'Y', NULL,      0);

-- === FIRE MOVES ===
INSERT INTO NHAGENCO1.MOVES VALUES (10,  'EMBER',         2,  40,  100, 25, 'N', 'BURN',    10);
INSERT INTO NHAGENCO1.MOVES VALUES (11,  'FLAMETHROWER',  2,  95,  100, 15, 'N', 'BURN',    10);
INSERT INTO NHAGENCO1.MOVES VALUES (12,  'FIRE BLAST',    2, 120,   85,  5, 'N', 'BURN',    30);
INSERT INTO NHAGENCO1.MOVES VALUES (13,  'FIRE SPIN',     2,  35,   85, 15, 'N', 'TRAP',   100);
INSERT INTO NHAGENCO1.MOVES VALUES (14,  'FIRE PUNCH',    2,  75,  100, 15, 'N', 'BURN',    10);

-- === WATER MOVES ===
INSERT INTO NHAGENCO1.MOVES VALUES (20,  'BUBBLE',        3,  20,  100, 30, 'N', NULL,      0);
INSERT INTO NHAGENCO1.MOVES VALUES (21,  'WATER GUN',     3,  40,  100, 25, 'N', NULL,      0);
INSERT INTO NHAGENCO1.MOVES VALUES (22,  'SURF',          3,  95,  100, 15, 'N', NULL,      0);
INSERT INTO NHAGENCO1.MOVES VALUES (23,  'HYDRO PUMP',    3, 120,   80,  5, 'N', NULL,      0);
INSERT INTO NHAGENCO1.MOVES VALUES (24,  'BUBBLE BEAM',   3,  65,  100, 20, 'N', 'SPD DOWN', 10);
INSERT INTO NHAGENCO1.MOVES VALUES (25,  'WITHDRAW',      3, NULL, 100, 40, 'N', 'DEF UP', 100);
INSERT INTO NHAGENCO1.MOVES VALUES (26,  'WATER PULSE',   3,  60,  100, 20, 'N', 'CONFUSE',  20);

-- === ELECTRIC MOVES ===
INSERT INTO NHAGENCO1.MOVES VALUES (30,  'THUNDER SHOCK', 4,  40,  100, 30, 'N', 'PARALYZE', 10);
INSERT INTO NHAGENCO1.MOVES VALUES (31,  'THUNDERBOLT',   4,  95,  100, 15, 'N', 'PARALYZE', 10);
INSERT INTO NHAGENCO1.MOVES VALUES (32,  'THUNDER',       4, 120,   70, 10, 'N', 'PARALYZE', 30);
INSERT INTO NHAGENCO1.MOVES VALUES (33,  'THUNDER WAVE',  4, NULL, 100, 20, 'N', 'PARALYZE',100);

-- === GRASS MOVES ===
INSERT INTO NHAGENCO1.MOVES VALUES (40,  'VINE WHIP',     5,  35,  100, 10, 'N', NULL,      0);
INSERT INTO NHAGENCO1.MOVES VALUES (41,  'RAZOR LEAF',    5,  55,   95, 25, 'N', 'HIGH CRIT',100);
INSERT INTO NHAGENCO1.MOVES VALUES (42,  'SOLAR BEAM',    5, 120,  100, 10, 'N', 'CHARGE',  100);
INSERT INTO NHAGENCO1.MOVES VALUES (43,  'LEECH SEED',    5, NULL,  90, 10, 'N', 'DRAIN',   100);
INSERT INTO NHAGENCO1.MOVES VALUES (44,  'SLEEP POWDER',  5, NULL,  75, 15, 'N', 'SLEEP',   100);

-- === ICE MOVES ===
INSERT INTO NHAGENCO1.MOVES VALUES (50,  'ICE BEAM',      6,  95,  100, 10, 'N', 'FREEZE',  10);
INSERT INTO NHAGENCO1.MOVES VALUES (51,  'BLIZZARD',      6, 120,   90,  5, 'N', 'FREEZE',  10);
INSERT INTO NHAGENCO1.MOVES VALUES (52,  'ICE PUNCH',     6,  75,  100, 15, 'N', 'FREEZE',  10);

-- === FIGHTING MOVES ===
INSERT INTO NHAGENCO1.MOVES VALUES (60,  'KARATE CHOP',   7,  50,  100, 25, 'Y', 'HIGH CRIT',100);
INSERT INTO NHAGENCO1.MOVES VALUES (61,  'LOW KICK',      7,  50,   90, 20, 'Y', NULL,      0);
INSERT INTO NHAGENCO1.MOVES VALUES (62,  'SUBMISSION',    7,  80,   80, 25, 'Y', 'RECOIL',  100);
INSERT INTO NHAGENCO1.MOVES VALUES (63,  'SEISMIC TOSS',  7, NULL, 100, 20, 'Y', 'FIXED DMG',100);

-- === POISON MOVES ===
INSERT INTO NHAGENCO1.MOVES VALUES (70,  'POISON STING',  8,  15,  100, 35, 'Y', 'POISON',  30);
INSERT INTO NHAGENCO1.MOVES VALUES (71,  'SLUDGE',        8,  65,  100, 20, 'Y', 'POISON',  30);
INSERT INTO NHAGENCO1.MOVES VALUES (72,  'TOXIC',         8, NULL,  85, 10, 'Y', 'BAD PSN', 100);

-- === GROUND MOVES ===
INSERT INTO NHAGENCO1.MOVES VALUES (80,  'DIG',           9,  80,  100, 10, 'Y', 'DIG',     100);
INSERT INTO NHAGENCO1.MOVES VALUES (81,  'EARTHQUAKE',    9, 100,  100, 10, 'Y', NULL,      0);
INSERT INTO NHAGENCO1.MOVES VALUES (82,  'SAND ATTACK',   9, NULL, 100, 15, 'Y', 'ACC DOWN',100);

-- === FLYING MOVES ===
INSERT INTO NHAGENCO1.MOVES VALUES (90,  'WING ATTACK',  10,  35,  100, 35, 'Y', NULL,      0);
INSERT INTO NHAGENCO1.MOVES VALUES (91,  'FLY',          10,  70,   95, 15, 'Y', 'FLY',     100);
INSERT INTO NHAGENCO1.MOVES VALUES (92,  'DRILL PECK',   10,  80,  100, 20, 'Y', NULL,      0);

-- === PSYCHIC MOVES ===
INSERT INTO NHAGENCO1.MOVES VALUES (100, 'CONFUSION',    11,  50,  100, 25, 'N', 'CONFUSE',  10);
INSERT INTO NHAGENCO1.MOVES VALUES (101, 'PSYCHIC',      11,  90,  100, 10, 'N', 'SPDEF DN', 30);
INSERT INTO NHAGENCO1.MOVES VALUES (102, 'DREAM EATER',  11, 100,  100, 15, 'N', 'DRAIN',   100);

-- === BUG MOVES ===
INSERT INTO NHAGENCO1.MOVES VALUES (110, 'STRING SHOT',  12, NULL,  95, 40, 'Y', 'SPD DOWN',100);
INSERT INTO NHAGENCO1.MOVES VALUES (111, 'PIN MISSILE',  12,  14,   85, 20, 'Y', 'MULTI',   100);

-- === ROCK MOVES ===
INSERT INTO NHAGENCO1.MOVES VALUES (120, 'ROCK SLIDE',   13,  75,   90, 10, 'Y', 'FLINCH',  30);
INSERT INTO NHAGENCO1.MOVES VALUES (121, 'ROCK THROW',   13,  50,   90, 15, 'Y', NULL,      0);

-- === GHOST MOVES ===
INSERT INTO NHAGENCO1.MOVES VALUES (130, 'LICK',         14,  20,  100, 30, 'Y', 'PARALYZE', 30);
INSERT INTO NHAGENCO1.MOVES VALUES (131, 'NIGHT SHADE',  14, NULL, 100, 15, 'Y', 'FIXED DMG',100);

-- === DRAGON MOVES ===
INSERT INTO NHAGENCO1.MOVES VALUES (140, 'DRAGON RAGE',  15, NULL, 100, 10, 'N', 'FIXED 40', 100);

-- ============================================================
-- POKEDEX
-- ASCII_ART uses # as line delimiter for 5250 rendering (# is CCSID-safe across 037/273)
-- Gen 1 base stats included
-- ============================================================
CREATE OR REPLACE TABLE NHAGENCO1.POKEDEX (
    PKMN_ID     SMALLINT       NOT NULL,
    PKMN_NAME   VARCHAR(12)    NOT NULL,
    TYPE1       SMALLINT       NOT NULL,
    TYPE2       SMALLINT,                     -- NULL if single type
    HP          SMALLINT       NOT NULL,
    ATTACK      SMALLINT       NOT NULL,
    DEFENSE     SMALLINT       NOT NULL,
    SP_ATK      SMALLINT       NOT NULL,      -- Gen 1: "Special" for both
    SP_DEF      SMALLINT       NOT NULL,      -- Gen 1: same as SP_ATK
    SPEED       SMALLINT       NOT NULL,
    COLOR       SMALLINT       NOT NULL DEFAULT 1,  -- 1=GRN 2=WHT 3=RED 4=TRQ 5=YLW 6=PNK 7=BLU
    ASCII_ART   VARCHAR(500) CCSID 37,        -- '#'-delimited, single-line, CCSID 37 so \ and | survive
    BATTLE_CRY  VARCHAR(30),                  -- text displayed on entry
    PRIMARY KEY (PKMN_ID),
    FOREIGN KEY (TYPE1) REFERENCES NHAGENCO1.TYPES(TYPE_ID)
);

-- ============================================================
-- IMPORTANT: ASCII_ART must be a SINGLE-LINE string literal.
-- Do NOT paste multi-line art or let your editor wrap the string
-- across multiple lines. Embedded CR/LF characters survive into
-- the column and, when written to a 5250 output field, get
-- interpreted by the terminal as display attribute bytes --
-- causing reverse image or other weird rendering.
--
-- Format: lines separated by '#' (not '|' -- CCSID 273 safe).
-- Max 10 lines, each up to 25 characters wide.
-- POKEBATTLE's ParseArt defensively strips CR/LF at runtime,
-- but keep the source clean so the column data stays clean too.
-- ============================================================

-- Starters & evolutions
INSERT INTO NHAGENCO1.POKEDEX VALUES (1, 'BULBASAUR', 5, 8, 45, 49, 49, 65, 65, 45, 1,
    '    _    #   / \   #  / o \  # /   __\  ##  (__ \ # \ \___) ##  \____/ #   \__/',
    'Bulba!');

INSERT INTO NHAGENCO1.POKEDEX VALUES (2, 'IVYSAUR', 5, 8, 60, 62, 63, 80, 80, 60, 1,
    '   \_/\_  #  (o  o) #  / _  \  # / / \  \ ##(__) \  ##  \___/  #   \__/',
    'Ivy!');

INSERT INTO NHAGENCO1.POKEDEX VALUES (3, 'VENUSAUR', 5, 8, 80, 82, 83, 100, 100, 80, 1,
    '  \\ __ // # \\(  )/  #  ( oo ) # _/ /\ \_ #(__)(__)# /  /  \  \#/__/\__\#',
    'VENUSAUR!');

INSERT INTO NHAGENCO1.POKEDEX VALUES (4, 'CHARMANDER', 2, NULL, 39, 52, 43, 60, 50, 65, 3,
    '       _ #      ( ) #   (\/)  #   /  \  #  ( oo ) #  _\  /_ # (_/  \_)#      *~',
    'Char!');

INSERT INTO NHAGENCO1.POKEDEX VALUES (5, 'CHARMELEON', 2, NULL, 58, 64, 58, 80, 65, 80, 3,
    '      _  #    _( )_ #   (\/)  #  / oo \  # ( \__/ )# _/ /\ \_#(__)(__)# *~~',
    'CHARR!');

INSERT INTO NHAGENCO1.POKEDEX VALUES (6, 'CHARIZARD', 2, 10, 78, 84, 78, 109, 85, 100, 3,
    '     /\  /\ #    /  \/  \#   (oo)   #  _/    \_ # / /\  /\ \## /(__)(__)\##*~~~  \__#',
    'RAAAWR!');

INSERT INTO NHAGENCO1.POKEDEX VALUES (7, 'SQUIRTLE', 3, NULL, 44, 48, 65, 50, 64, 43, 7,
    '    _____  #   /     \ #  | o   o|#  |   ^  |#   \  --- / #   \_____/ #     |_|_|',
    'Squirtle!');

INSERT INTO NHAGENCO1.POKEDEX VALUES (8, 'WARTORTLE', 3, NULL, 59, 63, 80, 65, 80, 58, 7,
    '    _____  #  //     \\# |  o   o|#  |   ^  |#   \  === / #  ~~\_____/#     |_|_|',
    'WARR!');

INSERT INTO NHAGENCO1.POKEDEX VALUES (9, 'BLASTOISE', 3, NULL, 79, 83, 100, 85, 105, 78, 7,
    '  |=|   |=|#   _____   #  / o o \ # |   ^   |#  \ === /  #  \_____/  # __|_|_|__#',
    'BLAST!');

INSERT INTO NHAGENCO1.POKEDEX VALUES (25, 'PIKACHU', 4, NULL, 35, 55, 30, 50, 40, 90, 5,
    '  |\  /| #  \ \/ / #   (oo)  #  _/  \_ # / \__/ \## \____/ #    ||',
    'Pika!');

INSERT INTO NHAGENCO1.POKEDEX VALUES (26, 'RAICHU', 4, NULL, 60, 90, 55, 90, 80, 100, 5,
    '   /|  |\ #  / \/ \ #  ( oo ) #  _/  \_ #  / __ \ # | (__) |# \______/#   )__(',
    'RAIIII!');

-- Popular Gen 1 Pokemon
INSERT INTO NHAGENCO1.POKEDEX VALUES (94, 'GENGAR', 14, 8, 60, 65, 60, 130, 75, 110, 6,
    '   /\  /\ #  /  \/  \# |  ^  ^ |# | \  w / |#  \____/ #   \    / #    \__/',
    'Kekeke!');

INSERT INTO NHAGENCO1.POKEDEX VALUES (130, 'GYARADOS', 3, 10, 95, 125, 79, 60, 100, 81, 7,
    '     ___  #    /   | #   / oo | #  |  >> | #   \___/  #    |  \\  #    | ~~~#   ~~~~',
    'GRAAAH!');

INSERT INTO NHAGENCO1.POKEDEX VALUES (143, 'SNORLAX', 1, NULL, 160, 110, 65, 65, 110, 30, 2,
    '   _____ #  /     \ # | x   x |#  |  __  |#  | /  \ |#   \____/ #  __|    |_#',
    '...Zzz...');

INSERT INTO NHAGENCO1.POKEDEX VALUES (149, 'DRAGONITE', 15, 10, 91, 134, 95, 100, 100, 80, 5,
    '    /\ /\ #   (    ) #   (oo)  #  _/  \_ # / \  / \##  ( __ ) ## \__/\__/#',
    'DRAAA!');

INSERT INTO NHAGENCO1.POKEDEX VALUES (150, 'MEWTWO', 11, NULL, 106, 110, 90, 154, 90, 130, 6,
    '    ___   #   /   \  #  | o o | #  |  _  | #   \   / #    | |   #   _| |_  #  (___)',
    '......');

INSERT INTO NHAGENCO1.POKEDEX VALUES (151, 'MEW', 11, NULL, 100, 100, 100, 100, 100, 100, 6,
    '   ___  #  (   ) #  ( o ) # /(   )\# \  ^  /#  \   / #   \_/',
    'Mew!');

-- ============================================================
-- POKEMON_MOVES (which Pokemon can learn which moves)
-- ============================================================
CREATE OR REPLACE TABLE NHAGENCO1.POKEMON_MOVES (
    PKMN_ID     SMALLINT       NOT NULL,
    MOVE_ID     SMALLINT       NOT NULL,
    LEARN_LVL   SMALLINT       NOT NULL DEFAULT 1,
    PRIMARY KEY (PKMN_ID, MOVE_ID),
    FOREIGN KEY (PKMN_ID)  REFERENCES NHAGENCO1.POKEDEX(PKMN_ID),
    FOREIGN KEY (MOVE_ID)  REFERENCES NHAGENCO1.MOVES(MOVE_ID)
);

-- Bulbasaur line
INSERT INTO NHAGENCO1.POKEMON_MOVES VALUES (1, 1,   1);   -- Tackle
INSERT INTO NHAGENCO1.POKEMON_MOVES VALUES (1, 40,  7);   -- Vine Whip
INSERT INTO NHAGENCO1.POKEMON_MOVES VALUES (1, 43, 13);   -- Leech Seed
INSERT INTO NHAGENCO1.POKEMON_MOVES VALUES (1, 41, 20);   -- Razor Leaf
INSERT INTO NHAGENCO1.POKEMON_MOVES VALUES (1, 44, 27);   -- Sleep Powder
INSERT INTO NHAGENCO1.POKEMON_MOVES VALUES (1, 42, 34);   -- Solar Beam
INSERT INTO NHAGENCO1.POKEMON_MOVES VALUES (2, 1,   1);   -- Ivysaur: Tackle
INSERT INTO NHAGENCO1.POKEMON_MOVES VALUES (2, 40,  7);   -- Vine Whip
INSERT INTO NHAGENCO1.POKEMON_MOVES VALUES (2, 43, 13);   -- Leech Seed
INSERT INTO NHAGENCO1.POKEMON_MOVES VALUES (2, 41, 20);   -- Razor Leaf
INSERT INTO NHAGENCO1.POKEMON_MOVES VALUES (2, 44, 27);   -- Sleep Powder
INSERT INTO NHAGENCO1.POKEMON_MOVES VALUES (3, 1,   1);   -- Venusaur: Tackle
INSERT INTO NHAGENCO1.POKEMON_MOVES VALUES (3, 40,  7);   -- Vine Whip
INSERT INTO NHAGENCO1.POKEMON_MOVES VALUES (3, 41, 20);   -- Razor Leaf
INSERT INTO NHAGENCO1.POKEMON_MOVES VALUES (3, 42, 34);   -- Solar Beam
INSERT INTO NHAGENCO1.POKEMON_MOVES VALUES (3, 44, 27);   -- Sleep Powder
INSERT INTO NHAGENCO1.POKEMON_MOVES VALUES (3, 4,  38);   -- Body Slam

-- Charmander line
INSERT INTO NHAGENCO1.POKEMON_MOVES VALUES (4, 2,   1);   -- Scratch
INSERT INTO NHAGENCO1.POKEMON_MOVES VALUES (4, 10,  9);   -- Ember
INSERT INTO NHAGENCO1.POKEMON_MOVES VALUES (4, 7,  15);   -- Slash
INSERT INTO NHAGENCO1.POKEMON_MOVES VALUES (4, 11, 31);   -- Flamethrower
INSERT INTO NHAGENCO1.POKEMON_MOVES VALUES (4, 12, 38);   -- Fire Blast
INSERT INTO NHAGENCO1.POKEMON_MOVES VALUES (5, 2,   1);   -- Charmeleon: Scratch
INSERT INTO NHAGENCO1.POKEMON_MOVES VALUES (5, 10,  9);   -- Ember
INSERT INTO NHAGENCO1.POKEMON_MOVES VALUES (5, 7,  15);   -- Slash
INSERT INTO NHAGENCO1.POKEMON_MOVES VALUES (5, 11, 31);   -- Flamethrower
INSERT INTO NHAGENCO1.POKEMON_MOVES VALUES (5, 12, 38);   -- Fire Blast
INSERT INTO NHAGENCO1.POKEMON_MOVES VALUES (6, 2,   1);   -- Charizard: Scratch
INSERT INTO NHAGENCO1.POKEMON_MOVES VALUES (6, 11, 31);   -- Flamethrower
INSERT INTO NHAGENCO1.POKEMON_MOVES VALUES (6, 12, 38);   -- Fire Blast
INSERT INTO NHAGENCO1.POKEMON_MOVES VALUES (6, 81, 40);   -- Earthquake
INSERT INTO NHAGENCO1.POKEMON_MOVES VALUES (6, 7,  15);   -- Slash
INSERT INTO NHAGENCO1.POKEMON_MOVES VALUES (6, 5,  46);   -- Hyper Beam

-- Squirtle line
INSERT INTO NHAGENCO1.POKEMON_MOVES VALUES (7, 1,   1);   -- Tackle
INSERT INTO NHAGENCO1.POKEMON_MOVES VALUES (7, 20,  7);   -- Bubble
INSERT INTO NHAGENCO1.POKEMON_MOVES VALUES (7, 21, 13);   -- Water Gun
INSERT INTO NHAGENCO1.POKEMON_MOVES VALUES (7, 25, 18);   -- Withdraw
INSERT INTO NHAGENCO1.POKEMON_MOVES VALUES (7, 24, 23);   -- Bubble Beam
INSERT INTO NHAGENCO1.POKEMON_MOVES VALUES (7, 22, 31);   -- Surf
INSERT INTO NHAGENCO1.POKEMON_MOVES VALUES (7, 23, 38);   -- Hydro Pump
INSERT INTO NHAGENCO1.POKEMON_MOVES VALUES (8, 1,   1);   -- Wartortle: Tackle
INSERT INTO NHAGENCO1.POKEMON_MOVES VALUES (8, 20,  7);   -- Bubble
INSERT INTO NHAGENCO1.POKEMON_MOVES VALUES (8, 21, 13);   -- Water Gun
INSERT INTO NHAGENCO1.POKEMON_MOVES VALUES (8, 25, 18);   -- Withdraw
INSERT INTO NHAGENCO1.POKEMON_MOVES VALUES (8, 24, 23);   -- Bubble Beam
INSERT INTO NHAGENCO1.POKEMON_MOVES VALUES (8, 22, 31);   -- Surf
INSERT INTO NHAGENCO1.POKEMON_MOVES VALUES (9, 1,   1);   -- Blastoise: Tackle
INSERT INTO NHAGENCO1.POKEMON_MOVES VALUES (9, 22, 31);   -- Surf
INSERT INTO NHAGENCO1.POKEMON_MOVES VALUES (9, 23, 38);   -- Hydro Pump
INSERT INTO NHAGENCO1.POKEMON_MOVES VALUES (9, 50, 42);   -- Ice Beam
INSERT INTO NHAGENCO1.POKEMON_MOVES VALUES (9, 81, 44);   -- Earthquake
INSERT INTO NHAGENCO1.POKEMON_MOVES VALUES (9, 5,  46);   -- Hyper Beam

-- Pikachu / Raichu
INSERT INTO NHAGENCO1.POKEMON_MOVES VALUES (25, 30,  1);  -- Thunder Shock
INSERT INTO NHAGENCO1.POKEMON_MOVES VALUES (25, 6,   1);  -- Quick Attack
INSERT INTO NHAGENCO1.POKEMON_MOVES VALUES (25, 33, 10);  -- Thunder Wave
INSERT INTO NHAGENCO1.POKEMON_MOVES VALUES (25, 31, 26);  -- Thunderbolt
INSERT INTO NHAGENCO1.POKEMON_MOVES VALUES (25, 32, 33);  -- Thunder
INSERT INTO NHAGENCO1.POKEMON_MOVES VALUES (25, 7,  20);  -- Slash

INSERT INTO NHAGENCO1.POKEMON_MOVES VALUES (26, 30,  1);  -- Raichu: Thunder Shock
INSERT INTO NHAGENCO1.POKEMON_MOVES VALUES (26, 6,   1);  -- Quick Attack
INSERT INTO NHAGENCO1.POKEMON_MOVES VALUES (26, 33, 10);  -- Thunder Wave
INSERT INTO NHAGENCO1.POKEMON_MOVES VALUES (26, 31, 26);  -- Thunderbolt
INSERT INTO NHAGENCO1.POKEMON_MOVES VALUES (26, 32, 33);  -- Thunder
INSERT INTO NHAGENCO1.POKEMON_MOVES VALUES (26, 4,  40);  -- Body Slam

-- Gengar
INSERT INTO NHAGENCO1.POKEMON_MOVES VALUES (94, 130,  1); -- Lick
INSERT INTO NHAGENCO1.POKEMON_MOVES VALUES (94, 131, 20); -- Night Shade
INSERT INTO NHAGENCO1.POKEMON_MOVES VALUES (94, 101, 38); -- Psychic
INSERT INTO NHAGENCO1.POKEMON_MOVES VALUES (94, 102, 42); -- Dream Eater
INSERT INTO NHAGENCO1.POKEMON_MOVES VALUES (94, 5,  48);  -- Hyper Beam
INSERT INTO NHAGENCO1.POKEMON_MOVES VALUES (94, 31, 36);  -- Thunderbolt

-- Gyarados
INSERT INTO NHAGENCO1.POKEMON_MOVES VALUES (130, 1,   1);  -- Tackle
INSERT INTO NHAGENCO1.POKEMON_MOVES VALUES (130, 140, 20); -- Dragon Rage
INSERT INTO NHAGENCO1.POKEMON_MOVES VALUES (130, 22,  30); -- Surf
INSERT INTO NHAGENCO1.POKEMON_MOVES VALUES (130, 23,  40); -- Hydro Pump
INSERT INTO NHAGENCO1.POKEMON_MOVES VALUES (130, 31,  38); -- Thunderbolt
INSERT INTO NHAGENCO1.POKEMON_MOVES VALUES (130, 5,   48); -- Hyper Beam

-- Dragonite
INSERT INTO NHAGENCO1.POKEMON_MOVES VALUES (149, 1,    1); -- Tackle
INSERT INTO NHAGENCO1.POKEMON_MOVES VALUES (149, 140, 15); -- Dragon Rage
INSERT INTO NHAGENCO1.POKEMON_MOVES VALUES (149, 33,  20); -- Thunder Wave
INSERT INTO NHAGENCO1.POKEMON_MOVES VALUES (149, 31,  35); -- Thunderbolt
INSERT INTO NHAGENCO1.POKEMON_MOVES VALUES (149, 50,  40); -- Ice Beam
INSERT INTO NHAGENCO1.POKEMON_MOVES VALUES (149, 5,   48); -- Hyper Beam

-- Mew
INSERT INTO NHAGENCO1.POKEMON_MOVES VALUES (151, 3,    1); -- Pound
INSERT INTO NHAGENCO1.POKEMON_MOVES VALUES (151, 101, 20); -- Psychic
INSERT INTO NHAGENCO1.POKEMON_MOVES VALUES (151, 31,  30); -- Thunderbolt
INSERT INTO NHAGENCO1.POKEMON_MOVES VALUES (151, 50,  30); -- Ice Beam
INSERT INTO NHAGENCO1.POKEMON_MOVES VALUES (151, 11,  30); -- Flamethrower
INSERT INTO NHAGENCO1.POKEMON_MOVES VALUES (151, 22,  30); -- Surf

-- Mewtwo
INSERT INTO NHAGENCO1.POKEMON_MOVES VALUES (150, 100,  1); -- Confusion
INSERT INTO NHAGENCO1.POKEMON_MOVES VALUES (150, 101, 30); -- Psychic
INSERT INTO NHAGENCO1.POKEMON_MOVES VALUES (150, 50,  44); -- Ice Beam
INSERT INTO NHAGENCO1.POKEMON_MOVES VALUES (150, 31,  44); -- Thunderbolt
INSERT INTO NHAGENCO1.POKEMON_MOVES VALUES (150, 11,  44); -- Flamethrower
INSERT INTO NHAGENCO1.POKEMON_MOVES VALUES (150, 5,   50); -- Hyper Beam

-- Snorlax
INSERT INTO NHAGENCO1.POKEMON_MOVES VALUES (143, 3,    1); -- Pound
INSERT INTO NHAGENCO1.POKEMON_MOVES VALUES (143, 4,   35); -- Body Slam
INSERT INTO NHAGENCO1.POKEMON_MOVES VALUES (143, 81,  40); -- Earthquake
INSERT INTO NHAGENCO1.POKEMON_MOVES VALUES (143, 5,   48); -- Hyper Beam
INSERT INTO NHAGENCO1.POKEMON_MOVES VALUES (143, 50,  42); -- Ice Beam
INSERT INTO NHAGENCO1.POKEMON_MOVES VALUES (143, 8,   30); -- Strength

-- ============================================================
-- BATTLE_SESSION - One row per active battle
-- ============================================================
CREATE OR REPLACE TABLE NHAGENCO1.BATTLE_SESSION (
    ROOM_CODE   VARCHAR(8)    NOT NULL,
    MODE        CHAR(2)       NOT NULL DEFAULT 'SP',
    JOB_P1      VARCHAR(10),
    JOB_P2      VARCHAR(10),
    STATUS      VARCHAR(10)   NOT NULL DEFAULT 'WAITING',
    TURN_STATE  VARCHAR(10)   NOT NULL DEFAULT 'P1_PICK',
    P1_MOVE     SMALLINT,
    P2_MOVE     SMALLINT,
    P1_RANDOM   DECIMAL(7, 6),
    P2_RANDOM   DECIMAL(7, 6),
    P1_ACC      DECIMAL(7, 6),
    P1_CRT      DECIMAL(7, 6),
    P1_DMG      DECIMAL(7, 6),
    P2_ACC      DECIMAL(7, 6),
    P2_CRT      DECIMAL(7, 6),
    P2_DMG      DECIMAL(7, 6),
    FIRST_ATK   SMALLINT,
    PRIMARY KEY (ROOM_CODE)
);

-- ============================================================
-- BATTLE_POKEMON - All active Pokemon in a battle session
-- ============================================================
CREATE OR REPLACE TABLE NHAGENCO1.BATTLE_POKEMON (
    ROOM_CODE    VARCHAR(8)   NOT NULL,
    PLAYER       SMALLINT     NOT NULL,
    TEAM_SLOT    SMALLINT     NOT NULL,
    PKMN_ID      SMALLINT     NOT NULL,
    NICKNAME     VARCHAR(12),
    LEVEL        SMALLINT     NOT NULL DEFAULT 50,
    CURRENT_HP   SMALLINT     NOT NULL,
    MAX_HP       SMALLINT     NOT NULL,
    STATUS       VARCHAR(10)  NOT NULL DEFAULT 'OK',
    STATUS_TURNS SMALLINT     NOT NULL DEFAULT 0,
    MOVE1        SMALLINT,
    MOVE2        SMALLINT,
    MOVE3        SMALLINT,
    MOVE4        SMALLINT,
    PP1          SMALLINT,
    PP2          SMALLINT,
    PP3          SMALLINT,
    PP4          SMALLINT,
    ATK_STAGE    SMALLINT     NOT NULL DEFAULT 0,
    DEF_STAGE    SMALLINT     NOT NULL DEFAULT 0,
    SPA_STAGE    SMALLINT     NOT NULL DEFAULT 0,
    SPD_STAGE    SMALLINT     NOT NULL DEFAULT 0,
    SPE_STAGE    SMALLINT     NOT NULL DEFAULT 0,
    IS_ACTIVE    CHAR(1)      NOT NULL DEFAULT 'N',
    PRIMARY KEY (ROOM_CODE, PLAYER, TEAM_SLOT),
    FOREIGN KEY (ROOM_CODE) REFERENCES NHAGENCO1.BATTLE_SESSION(ROOM_CODE),
    FOREIGN KEY (PKMN_ID)   REFERENCES NHAGENCO1.POKEDEX(PKMN_ID)
);

-- ============================================================
-- DAMAGE CALCULATION VIEW
-- Pass in attacker stats + move + defender stats via a
-- table function or calculate in RPG using this formula:
--
-- Gen 1 Damage Formula:
-- DMG = ((((2*Level/5+2) * Power * A/D) / 50) + 2)
--       * STAB * TypeEffect * Random(217-255)/255
--
-- Where:
--   A = Attack or Special (based on move type)
--   D = Defense or Special (based on move type)
--   STAB = 1.5 if move type matches attacker type
-- ============================================================

-- ============================================================
-- HELPER VIEW: Full type effectiveness lookup
-- Returns 1.0 for any matchup not explicitly stored
-- ============================================================
CREATE OR REPLACE VIEW NHAGENCO1.TYPE_MATCHUP AS
    SELECT
        A.TYPE_ID   AS ATK_TYPE,
        A.TYPE_NAME AS ATK_NAME,
        D.TYPE_ID   AS DEF_TYPE,
        D.TYPE_NAME AS DEF_NAME,
        COALESCE(E.MULTIPLIER, 1.0) AS MULTIPLIER
    FROM NHAGENCO1.TYPES A
    CROSS JOIN NHAGENCO1.TYPES D
    LEFT JOIN NHAGENCO1.TYPE_EFFECT E
        ON E.ATK_TYPE = A.TYPE_ID
       AND E.DEF_TYPE = D.TYPE_ID;

-- ============================================================
-- HELPER VIEW: Pokemon with type names resolved
-- ============================================================
CREATE OR REPLACE VIEW NHAGENCO1.POKEDEX_FULL AS
    SELECT
        P.PKMN_ID,
        P.PKMN_NAME,
        T1.TYPE_NAME AS TYPE1_NAME,
        T2.TYPE_NAME AS TYPE2_NAME,
        P.HP, P.ATTACK, P.DEFENSE,
        P.SP_ATK, P.SP_DEF, P.SPEED,
        P.ASCII_ART,
        P.BATTLE_CRY
    FROM NHAGENCO1.POKEDEX P
    JOIN NHAGENCO1.TYPES T1 ON T1.TYPE_ID = P.TYPE1
    LEFT JOIN NHAGENCO1.TYPES T2 ON T2.TYPE_ID = P.TYPE2;

-- ============================================================
-- EXAMPLE: Calculate type effectiveness for a move vs a target
-- ============================================================
-- SELECT
--     COALESCE(E1.MULTIPLIER, 1.0) *
--     COALESCE(E2.MULTIPLIER, 1.0) AS TOTAL_EFFECT
-- FROM POKEDEX DEF
-- LEFT JOIN TYPE_EFFECT E1
--     ON E1.ATK_TYPE = :MOVE_TYPE
--    AND E1.DEF_TYPE = DEF.TYPE1
-- LEFT JOIN TYPE_EFFECT E2
--     ON E2.ATK_TYPE = :MOVE_TYPE
--    AND E2.DEF_TYPE = DEF.TYPE2
-- WHERE DEF.PKMN_ID = :DEFENDER_ID;

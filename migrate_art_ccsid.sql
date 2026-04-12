-- Migrate POKEDEX.ASCII_ART to CCSID 37 and re-populate with correct \ and |
-- Run from ACS Run SQL Scripts (JDBC handles Unicode translation properly).
-- Step 1: change column CCSID. Existing substitution chars will survive as-is
-- but that's OK because step 2 overwrites every row.

ALTER TABLE NHAGENCO1.POKEDEX
  ALTER COLUMN ASCII_ART SET DATA TYPE VARCHAR(500) CCSID 37;

-- Step 2: re-insert the art. These literals are the originals from
-- pokemon_battle_engine.sql, with their \ and | intact.

UPDATE NHAGENCO1.POKEDEX SET ASCII_ART =
  '    _    #   / \   #  / o \  # /   __\  ##  (__ \ # \ \___) ##  \____/ #   \__/'
  WHERE PKMN_ID = 1;   -- Bulbasaur

UPDATE NHAGENCO1.POKEDEX SET ASCII_ART =
  '   \_/\_  #  (o  o) #  / _  \  # / / \  \ ##(__) \  ##  \___/  #   \__/'
  WHERE PKMN_ID = 2;   -- Ivysaur

UPDATE NHAGENCO1.POKEDEX SET ASCII_ART =
  '  \\ __ // # \\(  )/  #  ( oo ) # _/ /\ \_ #(__)(__)# /  /  \  \#/__/\__\#'
  WHERE PKMN_ID = 3;   -- Venusaur

UPDATE NHAGENCO1.POKEDEX SET ASCII_ART =
  '       _ #      ( ) #   (\/)  #   /  \  #  ( oo ) #  _\  /_ # (_/  \_)#      *~'
  WHERE PKMN_ID = 4;   -- Charmander

UPDATE NHAGENCO1.POKEDEX SET ASCII_ART =
  '      _  #    _( )_ #   (\/)  #  / oo \  # ( \__/ )# _/ /\ \_#(__)(__)# *~~'
  WHERE PKMN_ID = 5;   -- Charmeleon

UPDATE NHAGENCO1.POKEDEX SET ASCII_ART =
  '     /\  /\ #    \/\/   #   (oo)   #  _/    \_ # / /\  /\ \## /(__)(__)\##*~~~  \__#'
  WHERE PKMN_ID = 6;   -- Charizard

UPDATE NHAGENCO1.POKEDEX SET ASCII_ART =
  '    _____  #   /     \ #  | o   o|#  |   ^  |#   \  --- / #    \_____/#     |_|_|'
  WHERE PKMN_ID = 7;   -- Squirtle

UPDATE NHAGENCO1.POKEDEX SET ASCII_ART =
  '    _____  #  //     \\# |  o   o|#  |   ^  |#   \  === / #  ~~\_____/#     |_|_|'
  WHERE PKMN_ID = 8;   -- Wartortle

UPDATE NHAGENCO1.POKEDEX SET ASCII_ART =
  '  |=|   |=|#   _____   #  / o o \ # |   ^   |#  \ === /  #   \_____/ # __|_|_|__#'
  WHERE PKMN_ID = 9;   -- Blastoise

UPDATE NHAGENCO1.POKEDEX SET ASCII_ART =
  '  |\  /| #  \ \/ / #   (oo)  #  _/  \_ # / \__/ \## \____/ #    ||'
  WHERE PKMN_ID = 25;  -- Pikachu

UPDATE NHAGENCO1.POKEDEX SET ASCII_ART =
  '   /|  |\ #  / \/ \ #  ( oo ) #  _/  \_ #  / __ \ # | (__) |# \______/#   )__('
  WHERE PKMN_ID = 26;  -- Raichu

UPDATE NHAGENCO1.POKEDEX SET ASCII_ART =
  '   /\  /\ #  /  \/  \# |  ^  ^ |# | \  w / |#  \____/ #   \    / #    \__/'
  WHERE PKMN_ID = 94;  -- Gengar

UPDATE NHAGENCO1.POKEDEX SET ASCII_ART =
  '     ___  #    /   | #   / oo | #  |  >> | #   \___/  #    |  \\  #    | ~~~#   ~~~~'
  WHERE PKMN_ID = 130; -- Gyarados

UPDATE NHAGENCO1.POKEDEX SET ASCII_ART =
  '   _____ #  /     \ # | x   x |#  |  __  |#  | /  \ |#   \____/ #  __|    |_#'
  WHERE PKMN_ID = 143; -- Snorlax

UPDATE NHAGENCO1.POKEDEX SET ASCII_ART =
  '    /\ /\ #   (    ) #   (oo)  #  _/  \_ # / \  / \##  ( __ ) ## \__/\__/#'
  WHERE PKMN_ID = 149; -- Dragonite

UPDATE NHAGENCO1.POKEDEX SET ASCII_ART =
  '    ___   #   /   |  #  | o o | #  |  _  | #   \   / #    | |   #   _| |_  #  (___|'
  WHERE PKMN_ID = 150; -- Mewtwo

UPDATE NHAGENCO1.POKEDEX SET ASCII_ART =
  '   ___  #  (   ) #  ( o ) # /(   )\# \  ^  /#  \   / #   \_/'
  WHERE PKMN_ID = 151; -- Mew

-- Art alignment fixes. Run via ACS Run SQL Scripts.

-- Charizard: ear bases now line up under the ears
UPDATE NHAGENCO1.POKEDEX SET ASCII_ART =
  '     /\  /\ #    /  \/  \#   (oo)   #  _/    \_ # / /\  /\ \## /(__)(__)\##*~~~  \__#'
  WHERE PKMN_ID = 6;

-- Squirtle: bottom arc shifted 1 col left to mirror top arc
UPDATE NHAGENCO1.POKEDEX SET ASCII_ART =
  '    _____  #   /     \ #  | o   o|#  |   ^  |#   \  --- / #   \_____/ #     |_|_|'
  WHERE PKMN_ID = 7;

-- Blastoise: bottom arc shifted 1 col left to mirror top arc
UPDATE NHAGENCO1.POKEDEX SET ASCII_ART =
  '  |=|   |=|#   _____   #  / o o \ # |   ^   |#  \ === /  #  \_____/  # __|_|_|__#'
  WHERE PKMN_ID = 9;

-- Mewtwo: fix face left edge (|->\) and close body paren (|->))
UPDATE NHAGENCO1.POKEDEX SET ASCII_ART =
  '    ___   #   /   \  #  | o o | #  |  _  | #   \   / #    | |   #   _| |_  #  (___)'
  WHERE PKMN_ID = 150;

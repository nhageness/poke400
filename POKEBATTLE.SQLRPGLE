**free
// =============================================================
// POKEBATTLE - Gen 1 Pokemon Battle Engine
// Reads teams from BATTLE_SESSION/BATTLE_POKEMON tables.
// Supports SP (vs AI) and MP (vs human) modes.
// Supports full teams with switching on faint.
// =============================================================
ctl-opt dftactgrp(*no) actgrp(*new)
        option(*srcstmt : *nodebugio)
        ccsid(*char : *jobrunmix);

exec sql SET OPTION COMMIT = *NONE;

dcl-f POKEBATTL workstn;

// Program interface - receive room code and player number
dcl-pi *n;
  pRoomCode char(8);
  pPlayer   int(5);
end-pi;

// CL command executor for DLYJOB
dcl-pr QCMDEXC extpgm('QCMDEXC');
  cmd    char(256) const;
  cmdLen packed(15:5) const;
end-pr;

// ----- Template Data Structures -----
dcl-ds move_t qualified template;
  id    int(5);
  name  char(20);
  typ   int(5);
  power int(5);
  acc   int(5);
  pp    int(5);
  curPP int(5);
  phys  char(1);
  effect  char(10);
  effPct  int(5);
end-ds;

dcl-ds pkmn_t qualified template;
  id      int(5);
  name    char(12);
  type1   int(5);
  type2   int(5);
  t1name  char(10);
  t2name  char(10);
  level   int(5);
  hp      int(5);
  maxHp   int(5);
  atk     int(5);
  def     int(5);
  spAtk   int(5);
  spDef   int(5);
  speed   int(5);
  cry     char(30);
  art     varchar(500);
  moves   likeds(move_t) dim(4);
  slot    int(5);
  status  char(10);
  atkStg  int(5);
  defStg  int(5);
  spaStg  int(5);
  spdStg  int(5);
  speStg  int(5);
  accStg  int(5);
  seeded  ind;
  baseSpd int(5);
  color   int(5);
end-ds;

dcl-ds dmg_t qualified template;
  damage  int(5);
  didHit  ind;
  isCrit  ind;
  typeEff packed(5:2);
end-ds;

// ----- Subprocedure Prototypes -----
dcl-pr CalcDamage likeds(dmg_t);
  attacker likeds(pkmn_t) const;
  defender likeds(pkmn_t) const;
  move     likeds(move_t) const;
  pAccRoll packed(7:6) const options(*nopass);
  pCrtRoll packed(7:6) const options(*nopass);
  pDmgRoll packed(7:6) const options(*nopass);
end-pr;

dcl-pr BuildHPBar char(20);
  curHP int(5) const;
  maxHP int(5) const;
end-pr;

dcl-pr ShowMsg;
  m1 char(70) const;
  m2 char(70) const options(*nopass);
  m3 char(70) const options(*nopass);
end-pr;

dcl-pr ParseArt;
  artStr varchar(2000) const;
  l1  char(40);
  l2  char(40);
  l3  char(40);
  l4  char(40);
  l5  char(40);
  l6  char(40);
  l7  char(40);
  l8  char(40);
  l9  char(40);
  l10 char(40);
  l11 char(40);
  l12 char(40);
end-pr;

dcl-pr DoAttack likeds(dmg_t);
  attacker  likeds(pkmn_t);
  defender  likeds(pkmn_t);
  moveIdx   int(5) const;
  isPlayer  ind const;
  accRoll   packed(7:6) const;
  crtRoll   packed(7:6) const;
  dmgRoll   packed(7:6) const;
end-pr;

dcl-pr ApplyEndOfTurn;
  pkmn     likeds(pkmn_t);
  isPlayer ind const;
end-pr;

dcl-pr ApplyStage int(5);
  baseStat int(5) const;
  stage    int(5) const;
end-pr;

dcl-pr Delay;
  secs int(5) const;
end-pr;

dcl-pr LoadActivePkmn ind;
  ds     likeds(pkmn_t);
  room   char(8) const;
  player int(5) const;
end-pr;

dcl-pr SavePkmnState;
  ds     likeds(pkmn_t) const;
  room   char(8) const;
  player int(5) const;
end-pr;

// Cursor-to-selection helpers (field-name based via RTNCSRLOC)
dcl-pr FieldToAction char(1);
  fld char(10) const;
end-pr;

dcl-pr FieldToMoveIdx int(10);
  fld char(10) const;
end-pr;

dcl-pr FieldToSlotIdx int(10);
  fld char(10) const;
end-pr;

// Voluntary action picker procedures
dcl-pr PickMove int(10);
end-pr;

dcl-pr PickSwitchVoluntary int(10);
end-pr;

// ----- Global Variables -----
dcl-ds plyr likeds(pkmn_t) inz;
dcl-ds enmy likeds(pkmn_t) inz;
dcl-ds result likeds(dmg_t) inz;
dcl-ds result2 likeds(dmg_t) inz;

dcl-s battleOn ind inz(*on);
dcl-s moveChoice int(5);
dcl-s turnAction char(1);
dcl-s switchSlot int(10);
dcl-s actionPicked ind;
dcl-s vswSide char(1);
dcl-s vswNewSlot int(5);
dcl-s vswTargetPlayer int(5);
dcl-s vswIsPlayer ind;
dcl-s aiMoveIdx int(5);
dcl-s enmyMoveIdx int(5);
dcl-s i int(5);
dcl-s enmyPlayer int(5);
dcl-s plyrSkipAttack ind;
dcl-s enmySkipAttack ind;
dcl-s enmyAction char(1);
dcl-s enmySwitchSlot int(10);
dcl-s firstSwitcher int(10);
dcl-s wP1Action char(1);
dcl-s wP2Action char(1);
dcl-s wP1Switch int(10);
dcl-s wP2Switch int(10);

dcl-s randVal packed(7:6);
dcl-s battleMode char(2);

// Team tracking
dcl-s plyrAlive int(5);
dcl-s enmyAlive int(5);
dcl-s switchOk ind;
dcl-s plyrFainted ind;
dcl-s seedDmg int(5);
dcl-s enmyFainted ind;

// Switch menu work variables
dcl-s swSlot  int(5) dim(6);
dcl-s swName  char(12) dim(6);
dcl-s swCurHP int(5) dim(6);
dcl-s swMaxHP int(5) dim(6);
dcl-s swCount int(5);
dcl-s swChoice int(5);
dcl-s wSlot   int(5);
dcl-s wSName  char(12);
dcl-s wSCurHP int(5);
dcl-s wSMaxHP int(5);

// SQL work variables for move loading
dcl-s wMvId  int(5);
dcl-s wMvNm  char(20);
dcl-s wMvTyp int(5);
dcl-s wMvPwr int(5);
dcl-s wMvAcc int(5);
dcl-s wMvPP  int(5);
dcl-s wMvPhy char(1);
dcl-s niPwr  int(5);

// MP sync variables
dcl-s turnState char(10);
dcl-s wP1Move int(5);
dcl-s wP2Move int(5);
dcl-s firstAtk int(5);
dcl-s p1Acc packed(7:6);
dcl-s p1Crt packed(7:6);
dcl-s p1Dmg packed(7:6);
dcl-s p2Acc packed(7:6);
dcl-s p2Crt packed(7:6);
dcl-s p2Dmg packed(7:6);
dcl-s myAcc packed(7:6);
dcl-s myCrt packed(7:6);
dcl-s myDmg packed(7:6);
dcl-s opAcc packed(7:6);
dcl-s opCrt packed(7:6);
dcl-s opDmg packed(7:6);
dcl-s wOldActive char(1);

// =============================================================
// MAINLINE
// =============================================================

// Read battle mode from session
exec sql
  SELECT MODE INTO :battleMode
    FROM NHAGENCO1.BATTLE_SESSION
   WHERE ROOM_CODE = :pRoomCode;

// Determine enemy player number
enmyPlayer = 2;
if pPlayer = 2;
  enmyPlayer = 1;
endif;

// Load active Pokemon for both sides
if not LoadActivePkmn(plyr : pRoomCode : pPlayer);
  *inlr = *on;
  return;
endif;
if not LoadActivePkmn(enmy : pRoomCode : enmyPlayer);
  *inlr = *on;
  return;
endif;

// =============================================================
// INITIAL DISPLAY
// =============================================================

ROOMCD = pRoomCode;
BMODE = battleMode;
write HEADER;

exsr RefreshEnemy;

exsr RefreshPlayer;

// Battle entry narration
if battleMode = 'SP';
  ShowMsg('Wild ' + %trim(enmy.name) + ' appeared!');
else;
  ShowMsg('Opponent sent out ' + %trim(enmy.name) + '!');
endif;
if enmy.cry <> *blanks;
  ShowMsg(%trim(enmy.name) + ': ' + %trim(enmy.cry));
endif;
ShowMsg('Go! ' + %trim(plyr.name) + '!');
if plyr.cry <> *blanks;
  ShowMsg(%trim(plyr.name) + ': ' + %trim(plyr.cry));
endif;

// =============================================================
// BATTLE LOOP
// =============================================================
dow battleOn;

  // Reset per-turn flags
  plyrSkipAttack = *off;
  enmySkipAttack = *off;
  turnAction = ' ';
  enmyAction = ' ';
  enmySwitchSlot = 0;

  // Top-level action selection: FIGHT or PKMN switch.
  // ACTMENU loops until the user picks a valid action or quits
  // with F3. F12 inside the popups returns here with no pick.
  actionPicked = *off;
  turnAction = ' ';
  switchSlot = 0;
  dow not actionPicked;
    CURFGT = '>';
    CURPKM = '>';
    exfmt ACTMENU;
    if *in03;
      leave;
    endif;

    select;
      when FieldToAction(CSRFLD) = 'F';
        moveChoice = PickMove();
        if moveChoice > 0;
          turnAction = 'M';
          actionPicked = *on;
        endif;
      when FieldToAction(CSRFLD) = 'P';
        switchSlot = PickSwitchVoluntary();
        if switchSlot > 0;
          turnAction = 'S';
          actionPicked = *on;
        endif;
    endsl;
  enddo;
  if *in03;
    leave;
  endif;

  // -------------------------------------------------------
  // GET OPPONENT MOVE + RESOLVE
  // -------------------------------------------------------
  if battleMode = 'SP';
    // Player voluntary switch: apply before AI attacks.
    // AI still attacks normally against the new active mon.
    if turnAction = 'S';
      vswSide = 'P';
      vswNewSlot = switchSlot;
      exsr ApplyVoluntarySwitch;
      plyrSkipAttack = *on;
    endif;

    // AI picks random damaging move
    exec sql SET :randVal = RAND();
    aiMoveIdx = %int(randVal * 4) + 1;
    if aiMoveIdx > 4;
      aiMoveIdx = 4;
    endif;
    for i = 1 to 4;
      if enmy.moves(aiMoveIdx).power > 0
         and enmy.moves(aiMoveIdx).id <> 0;
        leave;
      endif;
      aiMoveIdx += 1;
      if aiMoveIdx > 4;
        aiMoveIdx = 1;
      endif;
    endfor;
    enmyMoveIdx = aiMoveIdx;

    // Determine turn order (random on tie)
    if plyr.speed > enmy.speed;
      firstAtk = pPlayer;
    elseif plyr.speed < enmy.speed;
      firstAtk = enmyPlayer;
    else;
      exec sql SET :randVal = RAND();
      if randVal < 0.5;
        firstAtk = pPlayer;
      else;
        firstAtk = enmyPlayer;
      endif;
    endif;

    // Generate randoms for both sides
    exec sql SET :myAcc = RAND();
    exec sql SET :myCrt = RAND();
    exec sql SET :myDmg = RAND();
    exec sql SET :opAcc = RAND();
    exec sql SET :opCrt = RAND();
    exec sql SET :opDmg = RAND();

  else;
    // MP: write our move, wait for opponent, get shared randoms
    exsr MPExchangeMoves;
    if not battleOn;
      leave;
    endif;

    // MP switch priority: apply voluntary switches before attacks
    if turnAction = 'S' and enmyAction = 'S';
      // Both switching - order by Speed of the OUTGOING active mon
      if plyr.speed > enmy.speed;
        firstSwitcher = pPlayer;
      elseif plyr.speed < enmy.speed;
        firstSwitcher = enmyPlayer;
      else;
        exec sql SET :randVal = RAND();
        if randVal < 0.5;
          firstSwitcher = pPlayer;
        else;
          firstSwitcher = enmyPlayer;
        endif;
      endif;

      if firstSwitcher = pPlayer;
        vswSide = 'P';
        vswNewSlot = switchSlot;
        exsr ApplyVoluntarySwitch;
        vswSide = 'E';
        vswNewSlot = enmySwitchSlot;
        exsr ApplyVoluntarySwitch;
      else;
        vswSide = 'E';
        vswNewSlot = enmySwitchSlot;
        exsr ApplyVoluntarySwitch;
        vswSide = 'P';
        vswNewSlot = switchSlot;
        exsr ApplyVoluntarySwitch;
      endif;

      // No attacks happen on a double-switch turn
      plyrSkipAttack = *on;
      enmySkipAttack = *on;

    elseif turnAction = 'S';
      // Only player switches - goes first, opponent attacks new mon
      vswSide = 'P';
      vswNewSlot = switchSlot;
      exsr ApplyVoluntarySwitch;
      plyrSkipAttack = *on;

    elseif enmyAction = 'S';
      // Only opponent switches - goes first, player attacks new mon
      vswSide = 'E';
      vswNewSlot = enmySwitchSlot;
      exsr ApplyVoluntarySwitch;
      enmySkipAttack = *on;

    endif;
  endif;

  exsr ResolveTurn;

  // -------------------------------------------------------
  // END-OF-TURN EFFECTS (same speed order as attacks)
  // -------------------------------------------------------
  if firstAtk = pPlayer;
    exsr EndOfTurnLeechSeed_Plyr;
    if plyr.hp > 0;
      ApplyEndOfTurn(plyr : *on);
    endif;
    exsr EndOfTurnLeechSeed_Enmy;
    if enmy.hp > 0;
      ApplyEndOfTurn(enmy : *off);
    endif;
  else;
    exsr EndOfTurnLeechSeed_Enmy;
    if enmy.hp > 0;
      ApplyEndOfTurn(enmy : *off);
    endif;
    exsr EndOfTurnLeechSeed_Plyr;
    if plyr.hp > 0;
      ApplyEndOfTurn(plyr : *on);
    endif;
  endif;

  // -------------------------------------------------------
  // FAINT CHECKING (handles simultaneous faints)
  // -------------------------------------------------------
  plyrFainted = (plyr.hp <= 0);
  enmyFainted = (enmy.hp <= 0);

  // Both fainted = check who has remaining team
  if plyrFainted and enmyFainted;
    ShowMsg(%trim(enmy.name) + ' fainted!');
    ShowMsg(%trim(plyr.name) + ' fainted!');
    SavePkmnState(plyr : pRoomCode : pPlayer);
    SavePkmnState(enmy : pRoomCode : enmyPlayer);

    // Force HP=0 for fainted active Pokemon (belt & suspenders)
    exec sql
      UPDATE NHAGENCO1.BATTLE_POKEMON
         SET CURRENT_HP = 0
       WHERE ROOM_CODE = :pRoomCode
         AND PLAYER = :pPlayer AND IS_ACTIVE = 'Y';
    exec sql
      UPDATE NHAGENCO1.BATTLE_POKEMON
         SET CURRENT_HP = 0
       WHERE ROOM_CODE = :pRoomCode
         AND PLAYER = :enmyPlayer AND IS_ACTIVE = 'Y';

    exec sql
      SELECT COUNT(*) INTO :plyrAlive
        FROM NHAGENCO1.BATTLE_POKEMON
       WHERE ROOM_CODE = :pRoomCode
         AND PLAYER = :pPlayer AND CURRENT_HP > 0;
    exec sql
      SELECT COUNT(*) INTO :enmyAlive
        FROM NHAGENCO1.BATTLE_POKEMON
       WHERE ROOM_CODE = :pRoomCode
         AND PLAYER = :enmyPlayer AND CURRENT_HP > 0;

    if plyrAlive = 0 and enmyAlive = 0;
      ShowMsg('It''s a draw!');
      Delay(2);
      battleOn = *off;
    elseif plyrAlive = 0;
      ShowMsg('You lost...');
      Delay(2);
      battleOn = *off;
    elseif enmyAlive = 0;
      ShowMsg('You win!');
      Delay(2);
      battleOn = *off;
    else;
      // Both need to switch
      exsr HandleEnemySwitch;
      exsr HandlePlayerSwitch;
    endif;

  elseif enmyFainted;
    ShowMsg(%trim(enmy.name) + ' fainted!');
    SavePkmnState(enmy : pRoomCode : enmyPlayer);

    exec sql
      UPDATE NHAGENCO1.BATTLE_POKEMON
         SET CURRENT_HP = 0
       WHERE ROOM_CODE = :pRoomCode
         AND PLAYER = :enmyPlayer AND IS_ACTIVE = 'Y';

    exec sql
      SELECT COUNT(*) INTO :enmyAlive
        FROM NHAGENCO1.BATTLE_POKEMON
       WHERE ROOM_CODE = :pRoomCode
         AND PLAYER = :enmyPlayer AND CURRENT_HP > 0;

    if enmyAlive = 0;
      ShowMsg('You win!');
      Delay(2);
      battleOn = *off;
    else;
      exsr HandleEnemySwitch;
    endif;

  elseif plyrFainted;
    ShowMsg(%trim(plyr.name) + ' fainted!');
    SavePkmnState(plyr : pRoomCode : pPlayer);

    exec sql
      UPDATE NHAGENCO1.BATTLE_POKEMON
         SET CURRENT_HP = 0
       WHERE ROOM_CODE = :pRoomCode
         AND PLAYER = :pPlayer AND IS_ACTIVE = 'Y';

    exec sql
      SELECT COUNT(*) INTO :plyrAlive
        FROM NHAGENCO1.BATTLE_POKEMON
       WHERE ROOM_CODE = :pRoomCode
         AND PLAYER = :pPlayer AND CURRENT_HP > 0;

    if plyrAlive = 0;
      ShowMsg('You lost...');
      Delay(2);
      battleOn = *off;
    else;
      exsr HandlePlayerSwitch;
    endif;
  endif;

  // Save state after each turn
  if battleOn;
    SavePkmnState(plyr : pRoomCode : pPlayer);
    SavePkmnState(enmy : pRoomCode : enmyPlayer);
  endif;

  // MP: P1 resets turn state for next round
  if battleOn and battleMode = 'MP' and pPlayer = 1;
    exec sql
      UPDATE NHAGENCO1.BATTLE_SESSION
         SET TURN_STATE = 'P1_PICK',
             P1_MOVE = NULL, P2_MOVE = NULL,
             P1_ACTION = NULL, P2_ACTION = NULL,
             P1_SWITCH_SLOT = NULL, P2_SWITCH_SLOT = NULL
       WHERE ROOM_CODE = :pRoomCode;
  endif;

enddo;

// MP: mark session done
if battleMode = 'MP';
  exec sql
    UPDATE NHAGENCO1.BATTLE_SESSION
       SET STATUS = 'DONE'
     WHERE ROOM_CODE = :pRoomCode;
endif;

*inlr = *on;
return;

// =============================================================
// SUBROUTINES
// =============================================================

// --- Leech Seed: drain player, heal enemy ---
begsr EndOfTurnLeechSeed_Plyr;
  if plyr.seeded and plyr.hp > 0;
    seedDmg = plyr.maxHp / 16;
    if seedDmg < 1;
      seedDmg = 1;
    endif;
    plyr.hp -= seedDmg;
    if plyr.hp < 0;
      plyr.hp = 0;
    endif;
    ShowMsg(%trim(plyr.name) + '''s health is sapped'
          + ' by Leech Seed!');
    PLHPBR = BuildHPBar(plyr.hp : plyr.maxHp);
    PLCRHP = plyr.hp;
    write PLAYER;
    Delay(1);

    // Heal the other side
    enmy.hp += seedDmg;
    if enmy.hp > enmy.maxHp;
      enmy.hp = enmy.maxHp;
    endif;
    OPHPBR = BuildHPBar(enmy.hp : enmy.maxHp);
    OPCRHP = enmy.hp;
    write OPPONENT;
  endif;
endsr;

// --- Leech Seed: drain enemy, heal player ---
begsr EndOfTurnLeechSeed_Enmy;
  if enmy.seeded and enmy.hp > 0;
    seedDmg = enmy.maxHp / 16;
    if seedDmg < 1;
      seedDmg = 1;
    endif;
    enmy.hp -= seedDmg;
    if enmy.hp < 0;
      enmy.hp = 0;
    endif;
    ShowMsg(%trim(enmy.name) + '''s health is sapped'
          + ' by Leech Seed!');
    OPHPBR = BuildHPBar(enmy.hp : enmy.maxHp);
    OPCRHP = enmy.hp;
    write OPPONENT;
    Delay(1);

    // Heal the other side
    plyr.hp += seedDmg;
    if plyr.hp > plyr.maxHp;
      plyr.hp = plyr.maxHp;
    endif;
    PLHPBR = BuildHPBar(plyr.hp : plyr.maxHp);
    PLCRHP = plyr.hp;
    write PLAYER;
  endif;
endsr;

// --- Resolve a turn: both attacks in speed order ---
begsr ResolveTurn;
  if firstAtk = pPlayer;
    if not plyrSkipAttack;
      result = DoAttack(plyr : enmy : moveChoice : *on
                       : myAcc : myCrt : myDmg);
    endif;
    if enmy.hp > 0 and not enmySkipAttack;
      result2 = DoAttack(enmy : plyr : enmyMoveIdx : *off
                        : opAcc : opCrt : opDmg);
    endif;
  else;
    if not enmySkipAttack;
      result2 = DoAttack(enmy : plyr : enmyMoveIdx : *off
                        : opAcc : opCrt : opDmg);
    endif;
    if plyr.hp > 0 and not plyrSkipAttack;
      result = DoAttack(plyr : enmy : moveChoice : *on
                       : myAcc : myCrt : myDmg);
    endif;
  endif;
endsr;

// --- MP: Exchange moves with opponent ---
begsr MPExchangeMoves;
  // Write our action (move or switch) to session
  if pPlayer = 1;
    if turnAction = 'M';
      wP1Action = 'M';
      wP1Move = plyr.moves(moveChoice).id;
      wP1Switch = 0;
    else;
      wP1Action = 'S';
      wP1Move = 0;
      wP1Switch = switchSlot;
    endif;
    exec sql
      UPDATE NHAGENCO1.BATTLE_SESSION
         SET P1_ACTION = :wP1Action,
             P1_MOVE = :wP1Move,
             P1_SWITCH_SLOT = :wP1Switch
       WHERE ROOM_CODE = :pRoomCode;
  else;
    if turnAction = 'M';
      wP2Action = 'M';
      wP2Move = plyr.moves(moveChoice).id;
      wP2Switch = 0;
    else;
      wP2Action = 'S';
      wP2Move = 0;
      wP2Switch = switchSlot;
    endif;
    exec sql
      UPDATE NHAGENCO1.BATTLE_SESSION
         SET P2_ACTION = :wP2Action,
             P2_MOVE = :wP2Move,
             P2_SWITCH_SLOT = :wP2Switch
       WHERE ROOM_CODE = :pRoomCode;
  endif;

  ShowMsg('Waiting for opponent...');

  // Poll until opponent's action is set
  if pPlayer = 1;
    wP2Action = ' ';
    dow wP2Action = ' ';
      Delay(1);
      exec sql
        SELECT COALESCE(P2_ACTION, ' '),
               COALESCE(P2_MOVE, 0),
               COALESCE(P2_SWITCH_SLOT, 0)
          INTO :wP2Action, :wP2Move, :wP2Switch
          FROM NHAGENCO1.BATTLE_SESSION
         WHERE ROOM_CODE = :pRoomCode;
    enddo;
    enmyAction = wP2Action;
    enmySwitchSlot = wP2Switch;
  else;
    wP1Action = ' ';
    dow wP1Action = ' ';
      Delay(1);
      exec sql
        SELECT COALESCE(P1_ACTION, ' '),
               COALESCE(P1_MOVE, 0),
               COALESCE(P1_SWITCH_SLOT, 0)
          INTO :wP1Action, :wP1Move, :wP1Switch
          FROM NHAGENCO1.BATTLE_SESSION
         WHERE ROOM_CODE = :pRoomCode;
    enddo;
    enmyAction = wP1Action;
    enmySwitchSlot = wP1Switch;
  endif;

  // Find opponent's move index only when they chose to attack
  enmyMoveIdx = 0;
  if enmyAction = 'M';
    if pPlayer = 1;
      for i = 1 to 4;
        if enmy.moves(i).id = wP2Move;
          enmyMoveIdx = i;
          leave;
        endif;
      endfor;
    else;
      for i = 1 to 4;
        if enmy.moves(i).id = wP1Move;
          enmyMoveIdx = i;
          leave;
        endif;
      endfor;
    endif;
    if enmyMoveIdx = 0;
      enmyMoveIdx = 1;
    endif;
  endif;

  // P1 generates random rolls and speed order
  if pPlayer = 1;
    exec sql SET :p1Acc = RAND();
    exec sql SET :p1Crt = RAND();
    exec sql SET :p1Dmg = RAND();
    exec sql SET :p2Acc = RAND();
    exec sql SET :p2Crt = RAND();
    exec sql SET :p2Dmg = RAND();

    // Speed order (P1's perspective: plyr=P1, enmy=P2)
    if plyr.speed > enmy.speed;
      firstAtk = 1;
    elseif plyr.speed < enmy.speed;
      firstAtk = 2;
    else;
      exec sql SET :randVal = RAND();
      if randVal < 0.5;
        firstAtk = 1;
      else;
        firstAtk = 2;
      endif;
    endif;

    exec sql
      UPDATE NHAGENCO1.BATTLE_SESSION
         SET P1_ACC = :p1Acc, P1_CRT = :p1Crt, P1_DMG = :p1Dmg,
             P2_ACC = :p2Acc, P2_CRT = :p2Crt, P2_DMG = :p2Dmg,
             FIRST_ATK = :firstAtk,
             TURN_STATE = 'RESOLVE'
       WHERE ROOM_CODE = :pRoomCode;
  else;
    // P2 polls until P1 resolves
    turnState = *blanks;
    dow turnState <> 'RESOLVE';
      Delay(1);
      exec sql
        SELECT TURN_STATE INTO :turnState
          FROM NHAGENCO1.BATTLE_SESSION
         WHERE ROOM_CODE = :pRoomCode;
    enddo;

    // Read shared randoms
    exec sql
      SELECT P1_ACC, P1_CRT, P1_DMG,
             P2_ACC, P2_CRT, P2_DMG, FIRST_ATK
        INTO :p1Acc, :p1Crt, :p1Dmg,
             :p2Acc, :p2Crt, :p2Dmg, :firstAtk
        FROM NHAGENCO1.BATTLE_SESSION
       WHERE ROOM_CODE = :pRoomCode;
  endif;

  // Map P1/P2 randoms to my/opponent based on which player we are
  if pPlayer = 1;
    myAcc = p1Acc;
    myCrt = p1Crt;
    myDmg = p1Dmg;
    opAcc = p2Acc;
    opCrt = p2Crt;
    opDmg = p2Dmg;
  else;
    myAcc = p2Acc;
    myCrt = p2Crt;
    myDmg = p2Dmg;
    opAcc = p1Acc;
    opCrt = p1Crt;
    opDmg = p1Dmg;
  endif;
endsr;

// --- Refresh opponent display ---
begsr RefreshEnemy;
  OPNAME = enmy.name;
  OPLVL = 'Lv' + %trim(%char(enmy.level));
  if enmy.type2 <> 0;
    OPTYPE = %trim(enmy.t1name) + '/' + %trim(enmy.t2name);
  else;
    OPTYPE = enmy.t1name;
  endif;
  OPHPBR = BuildHPBar(enmy.hp : enmy.maxHp);
  OPCRHP = enmy.hp;
  OPMXHP = enmy.maxHp;
  if enmy.status <> 'OK' and enmy.status <> *blanks;
    OPSTAT = enmy.status;
  else;
    OPSTAT = *blanks;
  endif;
  ParseArt(enmy.art : OPART1 : OPART2 : OPART3 : OPART4 : OPART5
                     : OPART6 : OPART7 : OPART8 : OPART9 : OPARTA
                     : OPARTB : OPARTC);

  // Opponent color indicators: 40=GRN 41=WHT 42=RED 43=TRQ 44=YLW 45=PNK 46=BLU
  *in40 = *off;
  *in41 = *off;
  *in42 = *off;
  *in43 = *off;
  *in44 = *off;
  *in45 = *off;
  *in46 = *off;
  select;
    when enmy.color = 1;
      *in40 = *on;
    when enmy.color = 2;
      *in41 = *on;
    when enmy.color = 3;
      *in42 = *on;
    when enmy.color = 4;
      *in43 = *on;
    when enmy.color = 5;
      *in44 = *on;
    when enmy.color = 6;
      *in45 = *on;
    when enmy.color = 7;
      *in46 = *on;
    other;
      *in40 = *on;
  endsl;

  write OPPONENT;
endsr;

// --- Refresh player display ---
begsr RefreshPlayer;
  PLNAME = plyr.name;
  PLLVL = 'Lv' + %trim(%char(plyr.level));
  if plyr.type2 <> 0;
    PLTYPE = %trim(plyr.t1name) + '/' + %trim(plyr.t2name);
  else;
    PLTYPE = plyr.t1name;
  endif;
  PLHPBR = BuildHPBar(plyr.hp : plyr.maxHp);
  PLCRHP = plyr.hp;
  PLMXHP = plyr.maxHp;
  if plyr.status <> 'OK' and plyr.status <> *blanks;
    PLSTAT = plyr.status;
  else;
    PLSTAT = *blanks;
  endif;
  ParseArt(plyr.art : PLART1 : PLART2 : PLART3 : PLART4 : PLART5
                     : PLART6 : PLART7 : PLART8 : PLART9 : PLARTA
                     : PLARTB : PLARTC);

  // Player color indicators: 30=GRN 31=WHT 32=RED 33=TRQ 34=YLW 35=PNK 36=BLU
  *in30 = *off;
  *in31 = *off;
  *in32 = *off;
  *in33 = *off;
  *in34 = *off;
  *in35 = *off;
  *in36 = *off;
  select;
    when plyr.color = 1;
      *in30 = *on;
    when plyr.color = 2;
      *in31 = *on;
    when plyr.color = 3;
      *in32 = *on;
    when plyr.color = 4;
      *in33 = *on;
    when plyr.color = 5;
      *in34 = *on;
    when plyr.color = 6;
      *in35 = *on;
    when plyr.color = 7;
      *in36 = *on;
    other;
      *in30 = *on;
  endsl;

  write PLAYER;
endsr;


// --- Handle enemy switching after faint ---
begsr HandleEnemySwitch;
  if battleMode = 'SP';
    // AI: auto-switch to next alive
    exec sql
      UPDATE NHAGENCO1.BATTLE_POKEMON
         SET IS_ACTIVE = 'N'
       WHERE ROOM_CODE = :pRoomCode
         AND PLAYER = :enmyPlayer;
    exec sql
      UPDATE NHAGENCO1.BATTLE_POKEMON
         SET IS_ACTIVE = 'Y'
       WHERE ROOM_CODE = :pRoomCode
         AND PLAYER = :enmyPlayer
         AND CURRENT_HP > 0
         AND TEAM_SLOT = (
           SELECT MIN(TEAM_SLOT)
             FROM NHAGENCO1.BATTLE_POKEMON
            WHERE ROOM_CODE = :pRoomCode
              AND PLAYER = :enmyPlayer
              AND CURRENT_HP > 0);

    LoadActivePkmn(enmy : pRoomCode : enmyPlayer);
    exsr RefreshEnemy;
    ShowMsg('Opponent sent out ' + %trim(enmy.name) + '!');
    if enmy.cry <> *blanks;
      ShowMsg(%trim(enmy.name) + ': ' + %trim(enmy.cry));
    endif;
  else;
    // MP: wait for opponent to switch (they get PickSwitch on their end)
    ShowMsg('Waiting for opponent to choose...');
    wOldActive = 'N';
    dow wOldActive <> 'Y';
      Delay(1);
      // Check if opponent has set a new active Pokemon
      exec sql
        SELECT IS_ACTIVE INTO :wOldActive
          FROM NHAGENCO1.BATTLE_POKEMON
         WHERE ROOM_CODE = :pRoomCode
           AND PLAYER = :enmyPlayer
           AND CURRENT_HP > 0
           AND IS_ACTIVE = 'Y';
      if sqlcode <> 0;
        wOldActive = 'N';
      endif;
    enddo;

    LoadActivePkmn(enmy : pRoomCode : enmyPlayer);
    exsr RefreshEnemy;
    ShowMsg('Opponent sent out ' + %trim(enmy.name) + '!');
    if enmy.cry <> *blanks;
      ShowMsg(%trim(enmy.name) + ': ' + %trim(enmy.cry));
    endif;
  endif;
endsr;

// --- Handle player switching after faint ---
begsr HandlePlayerSwitch;
  exsr PickSwitch;
  if *in03;
    battleOn = *off;
  else;
    exsr RefreshPlayer;
    ShowMsg('Go! ' + %trim(plyr.name) + '!');
    if plyr.cry <> *blanks;
      ShowMsg(%trim(plyr.name) + ': ' + %trim(plyr.cry));
    endif;
  endif;
endsr;

// --- Pick switch Pokemon after faint ---
begsr PickSwitch;
  swCount = 0;

  exec sql DECLARE c_switch CURSOR FOR
    SELECT bp.TEAM_SLOT, p.PKMN_NAME, bp.CURRENT_HP, bp.MAX_HP
      FROM NHAGENCO1.BATTLE_POKEMON bp
      JOIN NHAGENCO1.POKEDEX p ON p.PKMN_ID = bp.PKMN_ID
     WHERE bp.ROOM_CODE = :pRoomCode
       AND bp.PLAYER = :pPlayer
       AND bp.CURRENT_HP > 0
       AND bp.IS_ACTIVE = 'N'
     ORDER BY bp.TEAM_SLOT;

  exec sql OPEN c_switch;
  for i = 1 to 6;
    exec sql FETCH c_switch
      INTO :wSlot, :wSName, :wSCurHP, :wSMaxHP;
    if sqlcode <> 0;
      leave;
    endif;
    swCount += 1;
    swSlot(swCount) = wSlot;
    swName(swCount) = wSName;
    swCurHP(swCount) = wSCurHP;
    swMaxHP(swCount) = wSMaxHP;
  endfor;
  exec sql CLOSE c_switch;

  SW1NAM = *blanks;
  SW1HP  = *blanks;
  SW2NAM = *blanks;
  SW2HP  = *blanks;
  SW3NAM = *blanks;
  SW3HP  = *blanks;
  SW4NAM = *blanks;
  SW4HP  = *blanks;
  SW5NAM = *blanks;
  SW5HP  = *blanks;
  SW6NAM = *blanks;
  SW6HP  = *blanks;

  for i = 1 to swCount;
    select;
      when i = 1;
        SW1NAM = %trim(%char(i)) + '.' + %trim(swName(i));
        SW1HP = %trim(%char(swCurHP(i))) + '/'
              + %trim(%char(swMaxHP(i)));
      when i = 2;
        SW2NAM = %trim(%char(i)) + '.' + %trim(swName(i));
        SW2HP = %trim(%char(swCurHP(i))) + '/'
              + %trim(%char(swMaxHP(i)));
      when i = 3;
        SW3NAM = %trim(%char(i)) + '.' + %trim(swName(i));
        SW3HP = %trim(%char(swCurHP(i))) + '/'
              + %trim(%char(swMaxHP(i)));
      when i = 4;
        SW4NAM = %trim(%char(i)) + '.' + %trim(swName(i));
        SW4HP = %trim(%char(swCurHP(i))) + '/'
              + %trim(%char(swMaxHP(i)));
      when i = 5;
        SW5NAM = %trim(%char(i)) + '.' + %trim(swName(i));
        SW5HP = %trim(%char(swCurHP(i))) + '/'
              + %trim(%char(swMaxHP(i)));
      when i = 6;
        SW6NAM = %trim(%char(i)) + '.' + %trim(swName(i));
        SW6HP = %trim(%char(swCurHP(i))) + '/'
              + %trim(%char(swMaxHP(i)));
    endsl;
  endfor;

  switchOk = *off;
  dow not switchOk;
    SWSEL = ' ';
    exfmt SWITCHMN;

    if *in03;
      leavesr;
    endif;

    if SWSEL < '1' or SWSEL > '6';
      iter;
    endif;
    swChoice = %int(SWSEL);
    if swChoice > swCount;
      iter;
    endif;

    switchOk = *on;
  enddo;

  exec sql
    UPDATE NHAGENCO1.BATTLE_POKEMON
       SET IS_ACTIVE = 'N'
     WHERE ROOM_CODE = :pRoomCode
       AND PLAYER = :pPlayer;

  wSlot = swSlot(swChoice);
  exec sql
    UPDATE NHAGENCO1.BATTLE_POKEMON
       SET IS_ACTIVE = 'Y'
     WHERE ROOM_CODE = :pRoomCode
       AND PLAYER = :pPlayer
       AND TEAM_SLOT = :wSlot;

  LoadActivePkmn(plyr : pRoomCode : pPlayer);
endsr;

// --- ApplyVoluntarySwitch: swap active Pokemon for one side ---
//     Reads globals: vswSide ('P' player / 'E' enemy), vswNewSlot.
//     Saves outgoing state, flips IS_ACTIVE, reloads DS, clears
//     volatile (stat stages / Leech Seed), and runs entry WRITE seq.
//     Mainline subr (not proc) so it can EXSR RefreshPlayer/Enemy.
begsr ApplyVoluntarySwitch;
  if vswSide = 'P';
    vswTargetPlayer = pPlayer;
    vswIsPlayer = *on;
  else;
    vswTargetPlayer = enmyPlayer;
    vswIsPlayer = *off;
  endif;

  // Save the outgoing active Pokemon's HP/PP/status
  if vswIsPlayer;
    SavePkmnState(plyr : pRoomCode : pPlayer);
  else;
    SavePkmnState(enmy : pRoomCode : enmyPlayer);
  endif;

  // Flip IS_ACTIVE in the DB
  exec sql
    UPDATE NHAGENCO1.BATTLE_POKEMON
       SET IS_ACTIVE = 'N'
     WHERE ROOM_CODE = :pRoomCode
       AND PLAYER = :vswTargetPlayer
       AND IS_ACTIVE = 'Y';
  exec sql
    UPDATE NHAGENCO1.BATTLE_POKEMON
       SET IS_ACTIVE = 'Y'
     WHERE ROOM_CODE = :pRoomCode
       AND PLAYER = :vswTargetPlayer
       AND TEAM_SLOT = :vswNewSlot;

  // Reload DS from the new active row and reset volatile state.
  // Persistent status (burn/poison/etc) lives in the DB row and
  // comes back with the reload; only wipe RPG-only fields.
  if vswIsPlayer;
    LoadActivePkmn(plyr : pRoomCode : pPlayer);
    plyr.atkStg = 0;
    plyr.defStg = 0;
    plyr.spaStg = 0;
    plyr.spdStg = 0;
    plyr.speStg = 0;
    plyr.accStg = 0;
    plyr.seeded = *off;
    exsr RefreshPlayer;
    ShowMsg('Go! ' + %trim(plyr.name) + '!');
    if plyr.cry <> *blanks;
      ShowMsg(%trim(plyr.name) + ': ' + %trim(plyr.cry));
    endif;
  else;
    LoadActivePkmn(enmy : pRoomCode : enmyPlayer);
    enmy.atkStg = 0;
    enmy.defStg = 0;
    enmy.spaStg = 0;
    enmy.spdStg = 0;
    enmy.speStg = 0;
    enmy.accStg = 0;
    enmy.seeded = *off;
    exsr RefreshEnemy;
    ShowMsg('Enemy sent out ' + %trim(enmy.name) + '!');
    if enmy.cry <> *blanks;
      ShowMsg(%trim(enmy.name) + ': ' + %trim(enmy.cry));
    endif;
  endif;
endsr;

// =============================================================
// SUBPROCEDURES
// =============================================================

// -------------------------------------------------------------
// DoAttack - Execute one side's attack with damage + display
// Returns damage result. Modifies attacker PP and defender HP.
// -------------------------------------------------------------
dcl-proc DoAttack;
  dcl-pi *n likeds(dmg_t);
    attacker  likeds(pkmn_t);
    defender  likeds(pkmn_t);
    moveIdx   int(5) const;
    isPlayer  ind const;
    accRoll   packed(7:6) const;
    crtRoll   packed(7:6) const;
    dmgRoll   packed(7:6) const;
  end-pi;

  dcl-ds res likeds(dmg_t) inz;
  dcl-s statusRoll packed(7:6);
  dcl-s mvEffect char(10);
  dcl-s healAmt  int(5);
  dcl-s recoilAmt int(5);

  // --- Status check: can this Pokemon act? ---
  if attacker.status = 'PARALYZE';
    exec sql SET :statusRoll = RAND();
    if statusRoll < 0.25;
      ShowMsg(%trim(attacker.name) + ' is paralyzed!'
            + ' It can''t move!');
      return res;
    endif;
  endif;

  if attacker.status = 'SLEEP';
    exec sql SET :statusRoll = RAND();
    if statusRoll < 0.667;
      ShowMsg(%trim(attacker.name) + ' is fast asleep!');
      return res;
    else;
      attacker.status = 'OK';
      ShowMsg(%trim(attacker.name) + ' woke up!');
      if isPlayer;
        PLSTAT = *blanks;
        write PLAYER;
      else;
        OPSTAT = *blanks;
        write OPPONENT;
      endif;
    endif;
  endif;

  if attacker.status = 'FREEZE';
    exec sql SET :statusRoll = RAND();
    if statusRoll < 0.90;
      ShowMsg(%trim(attacker.name) + ' is frozen solid!');
      return res;
    else;
      attacker.status = 'OK';
      ShowMsg(%trim(attacker.name) + ' thawed out!');
      if isPlayer;
        PLSTAT = *blanks;
        write PLAYER;
      else;
        OPSTAT = *blanks;
        write OPPONENT;
      endif;
    endif;
  endif;

  // Decrement PP
  attacker.moves(moveIdx).curPP -= 1;

  ShowMsg(%trim(attacker.name) + ' used '
        + %trim(attacker.moves(moveIdx).name) + '!');

  mvEffect = attacker.moves(moveIdx).effect;

  // --- Status-only moves (power = 0) ---
  if attacker.moves(moveIdx).power = 0;

    // Accuracy check for status moves
    exec sql SET :statusRoll = RAND();
    if (statusRoll * 100) >= attacker.moves(moveIdx).acc;
      ShowMsg(%trim(attacker.name) + '''s attack missed!');
      return res;
    endif;
    res.didHit = *on;

    select;
      // Status infliction (Thunder Wave, Sleep Powder, Toxic)
      when mvEffect = 'PARALYZE'
        or mvEffect = 'SLEEP'
        or mvEffect = 'FREEZE';
        if defender.status = 'OK';
          defender.status = mvEffect;
          select;
            when defender.status = 'BURN';
              ShowMsg(%trim(defender.name) + ' was burned!');
            when defender.status = 'POISON';
              ShowMsg(%trim(defender.name) + ' was poisoned!');
            when defender.status = 'PARALYZE';
              ShowMsg(%trim(defender.name) + ' is paralyzed!');
            when defender.status = 'SLEEP';
              ShowMsg(%trim(defender.name) + ' fell asleep!');
            when defender.status = 'FREEZE';
              ShowMsg(%trim(defender.name) + ' was frozen!');
          endsl;
          if isPlayer;
            OPSTAT = defender.status;
            write OPPONENT;
          else;
            PLSTAT = defender.status;
            write PLAYER;
          endif;
        else;
          ShowMsg('But it failed!');
        endif;

      when mvEffect = 'BAD PSN';
        if defender.status = 'OK';
          defender.status = 'POISON';
          ShowMsg(%trim(defender.name) + ' was badly poisoned!');
          if isPlayer;
            OPSTAT = 'POISON';
            write OPPONENT;
          else;
            PLSTAT = 'POISON';
            write PLAYER;
          endif;
        else;
          ShowMsg('But it failed!');
        endif;

      // Stat boosts (Withdraw = DEF UP)
      when mvEffect = 'DEF UP';
        if attacker.defStg < 6;
          attacker.defStg += 1;
          ShowMsg(%trim(attacker.name) + '''s defense rose!');
        else;
          ShowMsg(%trim(attacker.name) + '''s defense won''t go higher!');
        endif;

      // Stat drops on opponent
      when mvEffect = 'ACC DOWN';
        if defender.accStg > -6;
          defender.accStg -= 1;
          ShowMsg(%trim(defender.name) + '''s accuracy fell!');
        else;
          ShowMsg(%trim(defender.name) + '''s accuracy won''t go lower!');
        endif;

      when mvEffect = 'SPD DOWN';
        if defender.speStg > -6;
          defender.speStg -= 1;
          ShowMsg(%trim(defender.name) + '''s speed fell!');
        else;
          ShowMsg(%trim(defender.name) + '''s speed won''t go lower!');
        endif;

      // Fixed damage moves with no power
      when mvEffect = 'FIXED DMG';
        // Seismic Toss / Night Shade: damage = attacker level
        res.damage = attacker.level;
        res.typeEff = 1;
        defender.hp -= res.damage;
        if defender.hp < 0;
          defender.hp = 0;
        endif;
        if isPlayer;
      OPHPBR = BuildHPBar(defender.hp : defender.maxHp);
      OPCRHP = defender.hp;
      write OPPONENT;
    else;
      PLHPBR = BuildHPBar(defender.hp : defender.maxHp);
      PLCRHP = defender.hp;
      write PLAYER;
    endif;
    Delay(1);

      when mvEffect = 'FIXED 40';
        // Dragon Rage: always 40
        res.damage = 40;
        res.typeEff = 1;
        defender.hp -= res.damage;
        if defender.hp < 0;
          defender.hp = 0;
        endif;
        if isPlayer;
      OPHPBR = BuildHPBar(defender.hp : defender.maxHp);
      OPCRHP = defender.hp;
      write OPPONENT;
    else;
      PLHPBR = BuildHPBar(defender.hp : defender.maxHp);
      PLCRHP = defender.hp;
      write PLAYER;
    endif;
    Delay(1);

      when mvEffect = 'DRAIN';
        // Leech Seed: seed the defender
        if not defender.seeded;
          defender.seeded = *on;
          ShowMsg(%trim(defender.name) + ' was seeded!');
        else;
          ShowMsg('But it failed!');
        endif;

      other;
        ShowMsg('But nothing happened!');
    endsl;

    return res;
  endif;

  // --- Damaging moves ---
  res = CalcDamage(attacker : defender : attacker.moves(moveIdx)
                  : accRoll : crtRoll : dmgRoll);

  if not res.didHit;
    ShowMsg(%trim(attacker.name) + '''s attack missed!');
    return res;
  endif;

  if res.typeEff = 0;
    ShowMsg('It doesn''t affect ' + %trim(defender.name) + '...');
    return res;
  endif;

  // Apply damage
  defender.hp -= res.damage;
  if defender.hp < 0;
    defender.hp = 0;
  endif;

  if isPlayer;
    OPHPBR = BuildHPBar(defender.hp : defender.maxHp);
    OPCRHP = defender.hp;
    write OPPONENT;
  else;
    PLHPBR = BuildHPBar(defender.hp : defender.maxHp);
    PLCRHP = defender.hp;
    write PLAYER;
  endif;
  Delay(1);

  if res.isCrit;
    ShowMsg('A critical hit!');
  endif;
  if res.typeEff > 1;
    ShowMsg('It''s super effective!');
  elseif res.typeEff < 1;
    ShowMsg('It''s not very effective...');
  endif;

  // --- Post-damage effects ---

  // Recoil (Submission: 1/4 damage dealt)
  if mvEffect = 'RECOIL' and res.damage > 0;
    recoilAmt = res.damage / 4;
    if recoilAmt < 1;
      recoilAmt = 1;
    endif;
    attacker.hp -= recoilAmt;
    if attacker.hp < 0;
      attacker.hp = 0;
    endif;
    ShowMsg(%trim(attacker.name) + ' is hit with recoil!');
    if isPlayer;
      PLHPBR = BuildHPBar(attacker.hp : attacker.maxHp);
      PLCRHP = attacker.hp;
      write PLAYER;
    else;
      OPHPBR = BuildHPBar(attacker.hp : attacker.maxHp);
      OPCRHP = attacker.hp;
      write OPPONENT;
    endif;
    Delay(1);
  endif;

  // Drain (Dream Eater: heal 1/2 damage dealt)
  if mvEffect = 'DRAIN' and res.damage > 0
     and defender.hp >= 0;
    healAmt = res.damage / 2;
    if healAmt < 1;
      healAmt = 1;
    endif;
    attacker.hp += healAmt;
    if attacker.hp > attacker.maxHp;
      attacker.hp = attacker.maxHp;
    endif;
    ShowMsg(%trim(attacker.name) + ' drained energy!');
    if isPlayer;
      PLHPBR = BuildHPBar(attacker.hp : attacker.maxHp);
      PLCRHP = attacker.hp;
      write PLAYER;
    else;
      OPHPBR = BuildHPBar(attacker.hp : attacker.maxHp);
      OPCRHP = attacker.hp;
      write OPPONENT;
    endif;
    Delay(1);
  endif;

  // Stat drops from damaging moves (Psychic = SPDEF DN, Bubble Beam = SPD DOWN)
  if defender.hp > 0;
    select;
      when mvEffect = 'SPDEF DN';
        exec sql SET :statusRoll = RAND();
        if statusRoll * 100 < attacker.moves(moveIdx).effPct;
          if defender.spdStg > -6;
            defender.spdStg -= 1;
            ShowMsg(%trim(defender.name) + '''s sp. defense fell!');
          endif;
        endif;

      when mvEffect = 'SPD DOWN';
        exec sql SET :statusRoll = RAND();
        if statusRoll * 100 < attacker.moves(moveIdx).effPct;
          if defender.speStg > -6;
            defender.speStg -= 1;
            ShowMsg(%trim(defender.name) + '''s speed fell!');
          endif;
        endif;
    endsl;
  endif;

  // Status effects from damaging moves (Ember burn, Thunderbolt paralyze, etc.)
  if defender.hp > 0 and defender.status = 'OK';
    select;
      when mvEffect = 'BURN'
        or mvEffect = 'POISON'
        or mvEffect = 'PARALYZE'
        or mvEffect = 'SLEEP'
        or mvEffect = 'FREEZE';

        exec sql SET :statusRoll = RAND();
        if statusRoll * 100 < attacker.moves(moveIdx).effPct;
          defender.status = mvEffect;
          select;
            when defender.status = 'BURN';
              ShowMsg(%trim(defender.name) + ' was burned!');
            when defender.status = 'POISON';
              ShowMsg(%trim(defender.name) + ' was poisoned!');
            when defender.status = 'PARALYZE';
              ShowMsg(%trim(defender.name) + ' is paralyzed!');
            when defender.status = 'SLEEP';
              ShowMsg(%trim(defender.name) + ' fell asleep!');
            when defender.status = 'FREEZE';
              ShowMsg(%trim(defender.name) + ' was frozen!');
          endsl;
          if isPlayer;
            OPSTAT = defender.status;
            write OPPONENT;
          else;
            PLSTAT = defender.status;
            write PLAYER;
          endif;
        endif;
    endsl;
  endif;

  return res;
end-proc;

// -------------------------------------------------------------
// ApplyEndOfTurn - Burn/poison damage at end of turn
// -------------------------------------------------------------
dcl-proc ApplyEndOfTurn;
  dcl-pi *n;
    pkmn     likeds(pkmn_t);
    isPlayer ind const;
  end-pi;

  dcl-s tickDmg int(5);

  if pkmn.status <> 'BURN' and pkmn.status <> 'POISON';
    return;
  endif;

  if pkmn.hp <= 0;
    return;
  endif;

  // 1/16 of max HP per turn
  tickDmg = pkmn.maxHp / 16;
  if tickDmg < 1;
    tickDmg = 1;
  endif;

  pkmn.hp -= tickDmg;
  if pkmn.hp < 0;
    pkmn.hp = 0;
  endif;

  if pkmn.status = 'BURN';
    ShowMsg(%trim(pkmn.name) + ' is hurt by its burn!');
  else;
    ShowMsg(%trim(pkmn.name) + ' is hurt by poison!');
  endif;

  // Refresh display
  if isPlayer;
    PLHPBR = BuildHPBar(pkmn.hp : pkmn.maxHp);
    PLCRHP = pkmn.hp;
    write PLAYER;
  else;
    OPHPBR = BuildHPBar(pkmn.hp : pkmn.maxHp);
    OPCRHP = pkmn.hp;
    write OPPONENT;
  endif;
  Delay(1);
end-proc;

// -------------------------------------------------------------
// LoadActivePkmn - Load active Pokemon from battle tables
// -------------------------------------------------------------
dcl-proc LoadActivePkmn;
  dcl-pi *n ind;
    ds     likeds(pkmn_t);
    room   char(8) const;
    player int(5) const;
  end-pi;

  dcl-s wId    int(5);
  dcl-s wName  char(12);
  dcl-s wT1    int(5);
  dcl-s wT2    int(5);
  dcl-s wT1nm  char(10);
  dcl-s wT2nm  char(10);
  dcl-s wHP    int(5);
  dcl-s wAtk   int(5);
  dcl-s wDef   int(5);
  dcl-s wSpA   int(5);
  dcl-s wSpD   int(5);
  dcl-s wSpeed int(5);
  dcl-s wCry   char(30);
  dcl-s wArt   varchar(500);
  dcl-s wColor int(5);
  dcl-s wCurHP int(5);
  dcl-s wMaxHP int(5);
  dcl-s wLevel int(5);
  dcl-s wTeamSlot int(5);
  dcl-s niT2   int(5);
  dcl-s niT2nm int(5);
  dcl-s niCry  int(5);
  dcl-s niArt  int(5);

  dcl-s wMv1 int(5);
  dcl-s wMv2 int(5);
  dcl-s wMv3 int(5);
  dcl-s wMv4 int(5);
  dcl-s wPP1 int(5);
  dcl-s wPP2 int(5);
  dcl-s wPP3 int(5);
  dcl-s wPP4 int(5);
  dcl-s niMv1 int(5);
  dcl-s niMv2 int(5);
  dcl-s niMv3 int(5);
  dcl-s niMv4 int(5);
  dcl-s niPP1 int(5);
  dcl-s niPP2 int(5);
  dcl-s niPP3 int(5);
  dcl-s niPP4 int(5);

  dcl-s wMvId  int(5);
  dcl-s wMvNm  char(20);
  dcl-s wMvTyp int(5);
  dcl-s wMvPwr int(5);
  dcl-s wMvAcc int(5);
  dcl-s wMvPP  int(5);
  dcl-s wMvPhy char(1);
  dcl-s wMvEff char(10);
  dcl-s wMvEPct int(5);
  dcl-s niPwr  int(5);
  dcl-s niEff  int(5);
  dcl-s niEPct int(5);
  dcl-s k int(5);
  dcl-s mvIds int(5) dim(4);
  dcl-s mvPPs int(5) dim(4);
  dcl-s wStatus char(10);

  exec sql
    SELECT bp.PKMN_ID, p.PKMN_NAME, p.TYPE1,
           p.TYPE2, t1.TYPE_NAME, t2.TYPE_NAME,
           p.HP, p.ATTACK, p.DEFENSE,
           p.SP_ATK, p.SP_DEF, p.SPEED, p.COLOR,
           p.BATTLE_CRY, p.ASCII_ART,
           bp.CURRENT_HP, bp.MAX_HP, bp.LEVEL, bp.TEAM_SLOT,
           bp.MOVE1, bp.MOVE2, bp.MOVE3, bp.MOVE4,
           bp.PP1, bp.PP2, bp.PP3, bp.PP4,
           bp.STATUS
      INTO :wId, :wName, :wT1,
           :wT2 :niT2, :wT1nm, :wT2nm :niT2nm,
           :wHP, :wAtk, :wDef,
           :wSpA, :wSpD, :wSpeed, :wColor,
           :wCry :niCry, :wArt :niArt,
           :wCurHP, :wMaxHP, :wLevel, :wTeamSlot,
           :wMv1 :niMv1, :wMv2 :niMv2,
           :wMv3 :niMv3, :wMv4 :niMv4,
           :wPP1 :niPP1, :wPP2 :niPP2,
           :wPP3 :niPP3, :wPP4 :niPP4,
           :wStatus
      FROM NHAGENCO1.BATTLE_POKEMON bp
      JOIN NHAGENCO1.POKEDEX p ON p.PKMN_ID = bp.PKMN_ID
      JOIN NHAGENCO1.TYPES t1 ON t1.TYPE_ID = p.TYPE1
      LEFT JOIN NHAGENCO1.TYPES t2 ON t2.TYPE_ID = p.TYPE2
     WHERE bp.ROOM_CODE = :room
       AND bp.PLAYER = :player
       AND bp.IS_ACTIVE = 'Y';

  if sqlcode <> 0;
    return *off;
  endif;

  clear ds;
  ds.id = wId;
  ds.name = wName;
  ds.type1 = wT1;
  ds.type2 = 0;
  if niT2 >= 0;
    ds.type2 = wT2;
  endif;
  ds.t1name = wT1nm;
  ds.t2name = *blanks;
  if niT2nm >= 0;
    ds.t2name = wT2nm;
  endif;
  ds.cry = *blanks;
  if niCry >= 0;
    ds.cry = wCry;
  endif;
  ds.art = '';
  if niArt >= 0;
    ds.art = wArt;
  endif;
  ds.level = wLevel;
  ds.hp = wCurHP;
  ds.maxHp = wMaxHP;
  ds.slot = wTeamSlot;
  ds.status = wStatus;
  ds.color = wColor;

  ds.atk = (wAtk * 2 * wLevel) / 100 + 5;
  ds.def = (wDef * 2 * wLevel) / 100 + 5;
  ds.spAtk = (wSpA * 2 * wLevel) / 100 + 5;
  ds.spDef = (wSpD * 2 * wLevel) / 100 + 5;
  ds.speed = (wSpeed * 2 * wLevel) / 100 + 5;
  ds.baseSpd = wSpeed;

  clear ds.moves;
  mvIds(1) = 0;
  mvIds(2) = 0;
  mvIds(3) = 0;
  mvIds(4) = 0;
  mvPPs(1) = 0;
  mvPPs(2) = 0;
  mvPPs(3) = 0;
  mvPPs(4) = 0;

  if niMv1 >= 0;
    mvIds(1) = wMv1;
    if niPP1 >= 0;
      mvPPs(1) = wPP1;
    endif;
  endif;
  if niMv2 >= 0;
    mvIds(2) = wMv2;
    if niPP2 >= 0;
      mvPPs(2) = wPP2;
    endif;
  endif;
  if niMv3 >= 0;
    mvIds(3) = wMv3;
    if niPP3 >= 0;
      mvPPs(3) = wPP3;
    endif;
  endif;
  if niMv4 >= 0;
    mvIds(4) = wMv4;
    if niPP4 >= 0;
      mvPPs(4) = wPP4;
    endif;
  endif;

  for k = 1 to 4;
    if mvIds(k) > 0;
      wMvId = mvIds(k);
      exec sql
        SELECT MOVE_ID, MOVE_NAME, TYPE_ID,
               POWER, ACCURACY, PP, IS_PHYSICAL,
               EFFECT, EFFECT_PCT
          INTO :wMvId, :wMvNm, :wMvTyp,
               :wMvPwr :niPwr, :wMvAcc, :wMvPP, :wMvPhy,
               :wMvEff :niEff, :wMvEPct :niEPct
          FROM NHAGENCO1.MOVES
         WHERE MOVE_ID = :wMvId;

      if sqlcode = 0;
        ds.moves(k).id = wMvId;
        ds.moves(k).name = wMvNm;
        ds.moves(k).typ = wMvTyp;
        ds.moves(k).power = 0;
        if niPwr >= 0;
          ds.moves(k).power = wMvPwr;
        endif;
        ds.moves(k).acc = wMvAcc;
        ds.moves(k).pp = wMvPP;
        ds.moves(k).curPP = mvPPs(k);
        ds.moves(k).phys = wMvPhy;
        ds.moves(k).effect = *blanks;
        if niEff >= 0;
          ds.moves(k).effect = wMvEff;
        endif;
        ds.moves(k).effPct = 0;
        if niEPct >= 0;
          ds.moves(k).effPct = wMvEPct;
        endif;
      endif;
    endif;
  endfor;

  return *on;
end-proc;

// -------------------------------------------------------------
// SavePkmnState - Write HP and PP back to BATTLE_POKEMON
// -------------------------------------------------------------
dcl-proc SavePkmnState;
  dcl-pi *n;
    ds     likeds(pkmn_t) const;
    room   char(8) const;
    player int(5) const;
  end-pi;

  dcl-s sHP   int(5);
  dcl-s sPP1  int(5);
  dcl-s sPP2  int(5);
  dcl-s sPP3  int(5);
  dcl-s sPP4  int(5);
  dcl-s sSlot int(5);
  dcl-s sRoom char(8);
  dcl-s sPlyr int(5);
  dcl-s sStat char(10);

  sHP = ds.hp;
  sPP1 = ds.moves(1).curPP;
  sPP2 = ds.moves(2).curPP;
  sPP3 = ds.moves(3).curPP;
  sPP4 = ds.moves(4).curPP;
  sSlot = ds.slot;
  sRoom = room;
  sPlyr = player;
  sStat = ds.status;

  exec sql
    UPDATE NHAGENCO1.BATTLE_POKEMON
       SET CURRENT_HP = :sHP,
           PP1 = :sPP1,
           PP2 = :sPP2,
           PP3 = :sPP3,
           PP4 = :sPP4,
           STATUS = :sStat
     WHERE ROOM_CODE = :sRoom
       AND PLAYER = :sPlyr
       AND TEAM_SLOT = :sSlot;
end-proc;

// -------------------------------------------------------------
// CalcDamage - Gen 1 damage formula
// Optional pre-rolled randoms for MP determinism
// -------------------------------------------------------------
dcl-proc CalcDamage;
  dcl-pi *n likeds(dmg_t);
    atk likeds(pkmn_t) const;
    def likeds(pkmn_t) const;
    mv  likeds(move_t) const;
    pAccRoll packed(7:6) const options(*nopass);
    pCrtRoll packed(7:6) const options(*nopass);
    pDmgRoll packed(7:6) const options(*nopass);
  end-pi;

  dcl-ds res likeds(dmg_t) inz;
  dcl-s atkStat int(5);
  dcl-s defStat int(5);
  dcl-s baseDmg packed(9:2);
  dcl-s stab    packed(3:1);
  dcl-s tEff    packed(5:2);
  dcl-s rndFact packed(5:3);
  dcl-s critChance packed(5:3);
  dcl-s accRoll packed(7:6);
  dcl-s critRoll packed(7:6);
  dcl-s dmgRoll packed(7:6);
  dcl-s lvl     int(5);

  dcl-s lMvTyp   int(5);
  dcl-s lMvPwr   int(5);
  dcl-s lMvAcc   int(5);
  dcl-s lDefT1   int(5);
  dcl-s lDefT2   int(5);
  dcl-s lAtkT1   int(5);
  dcl-s lAtkT2   int(5);
  dcl-s lAtkSpd  int(5);

  lMvTyp  = mv.typ;
  lMvPwr  = mv.power;
  lMvAcc  = mv.acc;
  lDefT1  = def.type1;
  lDefT2  = def.type2;
  lAtkT1  = atk.type1;
  lAtkT2  = atk.type2;
  lAtkSpd = atk.baseSpd;

  res.didHit = *off;
  res.isCrit = *off;
  res.damage = 0;
  res.typeEff = 1;

  // Accuracy check - use pre-rolled or fresh
  if %parms >= 4;
    accRoll = pAccRoll;
  else;
    exec sql SET :accRoll = RAND();
  endif;
  if (accRoll * 100) >= lMvAcc;
    return res;
  endif;
  res.didHit = *on;

  // Type effectiveness lookup
  exec sql
    SELECT COALESCE(e1.MULTIPLIER, 1.0) *
           COALESCE(e2.MULTIPLIER, 1.0)
      INTO :tEff
      FROM SYSIBM.SYSDUMMY1
      LEFT JOIN NHAGENCO1.TYPE_EFFECT e1
        ON e1.ATK_TYPE = :lMvTyp AND e1.DEF_TYPE = :lDefT1
      LEFT JOIN NHAGENCO1.TYPE_EFFECT e2
        ON e2.ATK_TYPE = :lMvTyp AND e2.DEF_TYPE = :lDefT2;
  res.typeEff = tEff;

  if tEff = 0;
    return res;
  endif;

  if mv.phys = 'Y';
    atkStat = atk.atk;
    defStat = def.def;
  else;
    atkStat = atk.spAtk;
    defStat = def.spDef;
  endif;

  lvl = atk.level;

  // Critical hit check
  if %parms >= 5;
    critRoll = pCrtRoll;
  else;
    exec sql SET :critRoll = RAND();
  endif;
  critChance = lAtkSpd / 512;
  // HIGH CRIT moves double the crit chance
  if mv.effect = 'HIGH CRIT';
    critChance = critChance * 2;
    if critChance > 1;
      critChance = 1;
    endif;
  endif;
  if critRoll < critChance;
    res.isCrit = *on;
    lvl = lvl * 2;
  endif;

  // Apply stat stages (ignored on crits per Gen 1)
  if not res.isCrit;
    if mv.phys = 'Y';
      atkStat = ApplyStage(atkStat : atk.atkStg);
      defStat = ApplyStage(defStat : def.defStg);
    else;
      atkStat = ApplyStage(atkStat : atk.spaStg);
      defStat = ApplyStage(defStat : def.spdStg);
    endif;
  endif;

  baseDmg = ((2 * lvl / 5 + 2) * lMvPwr * atkStat / defStat)
            / 50 + 2;

  stab = 1.0;
  if lMvTyp = lAtkT1 or lMvTyp = lAtkT2;
    stab = 1.5;
  endif;

  // Damage roll
  if %parms >= 6;
    dmgRoll = pDmgRoll;
  else;
    exec sql SET :dmgRoll = RAND();
  endif;
  rndFact = (217 + dmgRoll * 38) / 255;

  res.damage = %int(baseDmg * stab * tEff * rndFact);
  if res.damage < 1 and tEff > 0;
    res.damage = 1;
  endif;

  return res;
end-proc;

// -------------------------------------------------------------
// ApplyStage - Apply stat stage multiplier (-6 to +6)
// Gen 1: stages 2/2, 3/2, 4/2, 5/2, 6/2, 7/2, 8/2
//        and inverse for negatives
// -------------------------------------------------------------
dcl-proc ApplyStage;
  dcl-pi *n int(5);
    baseStat int(5) const;
    stage    int(5) const;
  end-pi;

  dcl-s num int(5);
  dcl-s den int(5);

  if stage = 0;
    return baseStat;
  endif;

  if stage > 0;
    num = 2 + stage;
    den = 2;
  else;
    num = 2;
    den = 2 - stage;
  endif;

  return baseStat * num / den;
end-proc;

// -------------------------------------------------------------
// Delay - Park cursor on MSGLINE then delay
// -------------------------------------------------------------
dcl-proc Delay;
  dcl-pi *n;
    secs int(5) const;
  end-pi;

  dcl-s cmd char(30);

  cmd = 'DLYJOB DLY(' + %trim(%char(secs)) + ')';
  QCMDEXC(cmd : %len(%trim(cmd)));
end-proc;

// -------------------------------------------------------------
// BuildHPBar - 20-char visual HP bar
// -------------------------------------------------------------
dcl-proc BuildHPBar;
  dcl-pi *n char(20);
    curHP int(5) const;
    maxHP int(5) const;
  end-pi;

  dcl-s bar char(20);
  dcl-s filled int(5);
  dcl-s j int(5);

  if maxHP <= 0;
    return '....................';
  endif;

  filled = (curHP * 20) / maxHP;
  if curHP > 0 and filled = 0;
    filled = 1;
  endif;

  bar = *blanks;
  for j = 1 to 20;
    if j <= filled;
      %subst(bar:j:1) = '=';
    else;
      %subst(bar:j:1) = '-';
    endif;
  endfor;

  return bar;
end-proc;

// -------------------------------------------------------------
// ShowMsg - Write narration message and pause
// -------------------------------------------------------------
dcl-proc ShowMsg;
  dcl-pi *n;
    m1 char(70) const;
    m2 char(70) const options(*nopass);
    m3 char(70) const options(*nopass);
  end-pi;

  MSG1 = m1;
  if %parms >= 2;
    MSG2 = m2;
  else;
    MSG2 = *blanks;
  endif;
  if %parms >= 3;
    MSG3 = m3;
  else;
    MSG3 = *blanks;
  endif;

  write MSGLINE;
  Delay(2);
end-proc;

// -------------------------------------------------------------
// ParseArt - Split #-delimited art string into 12 lines
// -------------------------------------------------------------
dcl-proc ParseArt;
  dcl-pi *n;
    artStr varchar(2000) const;
    l1  char(40);
    l2  char(40);
    l3  char(40);
    l4  char(40);
    l5  char(40);
    l6  char(40);
    l7  char(40);
    l8  char(40);
    l9  char(40);
    l10 char(40);
    l11 char(40);
    l12 char(40);
  end-pi;

  dcl-s lines char(40) dim(12);
  dcl-s lineNum int(5);
  dcl-s startPos int(5);
  dcl-s pos int(5);
  dcl-s artLen int(5);
  dcl-s cleanArt varchar(2000);

  // Strip embedded control chars (CR/LF/NL) so they can't be
  // interpreted as 5250 field attribute bytes. These sneak in
  // when art is pasted into the DB across multiple lines.
  cleanArt = %xlate(x'0D25150A' : '    ' : artStr);

  clear lines;
  lineNum = 1;
  startPos = 1;
  artLen = %len(cleanArt);

  if artLen = 0;
    l1 = *blanks;
    l2 = *blanks;
    l3 = *blanks;
    l4 = *blanks;
    l5 = *blanks;
    l6 = *blanks;
    l7 = *blanks;
    l8 = *blanks;
    l9 = *blanks;
    l10 = *blanks;
    l11 = *blanks;
    l12 = *blanks;
    return;
  endif;

  for pos = 1 to artLen;
    if %subst(cleanArt : pos : 1) = '#';
      if lineNum <= 12;
        if pos > startPos;
          lines(lineNum) = %subst(cleanArt : startPos : pos - startPos);
        endif;
        lineNum += 1;
      endif;
      startPos = pos + 1;
    endif;
  endfor;

  if startPos <= artLen and lineNum <= 12;
    lines(lineNum) = %subst(cleanArt : startPos : artLen - startPos + 1);
  endif;

  l1  = lines(1);
  l2  = lines(2);
  l3  = lines(3);
  l4  = lines(4);
  l5  = lines(5);
  l6  = lines(6);
  l7  = lines(7);
  l8  = lines(8);
  l9  = lines(9);
  l10 = lines(10);
  l11 = lines(11);
  l12 = lines(12);
end-proc;

// -------------------------------------------------------------
// FieldToAction - Map CSRFLD field name to action letter
// 'F' = fight, 'P' = pkmn, ' ' = invalid
// -------------------------------------------------------------
dcl-proc FieldToAction;
  dcl-pi *n char(1);
    fld char(10) const;
  end-pi;
  select;
    when %trim(fld) = 'CURFGT';
      return 'F';
    when %trim(fld) = 'CURPKM';
      return 'P';
  endsl;
  return ' ';
end-proc;

// -------------------------------------------------------------
// FieldToMoveIdx - Map CSRFLD name to move 1-4, 0 if invalid
// -------------------------------------------------------------
dcl-proc FieldToMoveIdx;
  dcl-pi *n int(10);
    fld char(10) const;
  end-pi;
  select;
    when %trim(fld) = 'CURMV1';
      return 1;
    when %trim(fld) = 'CURMV2';
      return 2;
    when %trim(fld) = 'CURMV3';
      return 3;
    when %trim(fld) = 'CURMV4';
      return 4;
  endsl;
  return 0;
end-proc;

// -------------------------------------------------------------
// FieldToSlotIdx - Map CSRFLD name to slot 1-6, 0 if invalid
// -------------------------------------------------------------
dcl-proc FieldToSlotIdx;
  dcl-pi *n int(10);
    fld char(10) const;
  end-pi;
  select;
    when %trim(fld) = 'PW1NAM';
      return 1;
    when %trim(fld) = 'PW2NAM';
      return 2;
    when %trim(fld) = 'PW3NAM';
      return 3;
    when %trim(fld) = 'PW4NAM';
      return 4;
    when %trim(fld) = 'PW5NAM';
      return 5;
    when %trim(fld) = 'PW6NAM';
      return 6;
  endsl;
  return 0;
end-proc;

// -------------------------------------------------------------
// PickMove - Display MOVEMENU popup, return chosen move 1-4 or 0
// -------------------------------------------------------------
dcl-proc PickMove;
  dcl-pi *n int(10);
  end-pi;
  dcl-s choice int(10);

  dow *on;
    MV1NAM = plyr.moves(1).name;
    MV1PP = %trim(%char(plyr.moves(1).curPP)) + '/'
          + %trim(%char(plyr.moves(1).pp));
    MV2NAM = plyr.moves(2).name;
    MV2PP = %trim(%char(plyr.moves(2).curPP)) + '/'
          + %trim(%char(plyr.moves(2).pp));
    MV3NAM = plyr.moves(3).name;
    MV3PP = %trim(%char(plyr.moves(3).curPP)) + '/'
          + %trim(%char(plyr.moves(3).pp));
    MV4NAM = plyr.moves(4).name;
    MV4PP = %trim(%char(plyr.moves(4).curPP)) + '/'
          + %trim(%char(plyr.moves(4).pp));

    CURMV1 = '>';
    CURMV2 = '>';
    CURMV3 = '>';
    CURMV4 = '>';
    exfmt MOVEMENU;
    if *in12;
      return 0;
    endif;

    choice = FieldToMoveIdx(CSRFLD);
    if choice < 1 or choice > 4;
      iter;
    endif;

    if plyr.moves(choice).id = 0;
      ShowMsg('No move.');
      iter;
    endif;
    if plyr.moves(choice).curPP <= 0;
      ShowMsg('No PP left!');
      iter;
    endif;

    return choice;
  enddo;
end-proc;

// -------------------------------------------------------------
// PickSwitchVoluntary - Display PKMNWIN popup, return team slot or 0
// -------------------------------------------------------------
dcl-proc PickSwitchVoluntary;
  dcl-pi *n int(10);
  end-pi;
  dcl-s choice int(10);
  dcl-s i int(10);
  dcl-s slotName char(12);
  dcl-s slotHp  int(10);
  dcl-s slotMax int(10);
  dcl-s slotActive char(1);
  dcl-ds slots qualified dim(6);
    name char(12);
    hp int(10);
    mx int(10);
    active char(1);
    present ind;
  end-ds;

  for i = 1 to 6;
    clear slots(i);
    exec sql
      SELECT p.PKMN_NAME, bp.CURRENT_HP, bp.MAX_HP, bp.IS_ACTIVE
        INTO :slotName, :slotHp, :slotMax, :slotActive
        FROM NHAGENCO1.BATTLE_POKEMON bp
        JOIN NHAGENCO1.POKEDEX p ON bp.PKMN_ID = p.PKMN_ID
       WHERE bp.ROOM_CODE = :pRoomCode
         AND bp.PLAYER = :pPlayer
         AND bp.TEAM_SLOT = :i;
    if sqlcode = 0;
      slots(i).name = slotName;
      slots(i).hp = slotHp;
      slots(i).mx = slotMax;
      slots(i).active = slotActive;
      slots(i).present = *on;
    endif;
  endfor;

  dow *on;
    // Slot 1
    if slots(1).present;
      PW1NAM = slots(1).name;
      PW1HP = %trim(%char(slots(1).hp)) + '/'
            + %trim(%char(slots(1).mx));
      if slots(1).hp <= 0;
        *in90 = *on;
      else;
        *in90 = *off;
      endif;
    else;
      PW1NAM = *blanks;
      PW1HP = *blanks;
      *in90 = *off;
    endif;

    // Slot 2
    if slots(2).present;
      PW2NAM = slots(2).name;
      PW2HP = %trim(%char(slots(2).hp)) + '/'
            + %trim(%char(slots(2).mx));
      if slots(2).hp <= 0;
        *in91 = *on;
      else;
        *in91 = *off;
      endif;
    else;
      PW2NAM = *blanks;
      PW2HP = *blanks;
      *in91 = *off;
    endif;

    // Slot 3
    if slots(3).present;
      PW3NAM = slots(3).name;
      PW3HP = %trim(%char(slots(3).hp)) + '/'
            + %trim(%char(slots(3).mx));
      if slots(3).hp <= 0;
        *in92 = *on;
      else;
        *in92 = *off;
      endif;
    else;
      PW3NAM = *blanks;
      PW3HP = *blanks;
      *in92 = *off;
    endif;

    // Slot 4
    if slots(4).present;
      PW4NAM = slots(4).name;
      PW4HP = %trim(%char(slots(4).hp)) + '/'
            + %trim(%char(slots(4).mx));
      if slots(4).hp <= 0;
        *in93 = *on;
      else;
        *in93 = *off;
      endif;
    else;
      PW4NAM = *blanks;
      PW4HP = *blanks;
      *in93 = *off;
    endif;

    // Slot 5
    if slots(5).present;
      PW5NAM = slots(5).name;
      PW5HP = %trim(%char(slots(5).hp)) + '/'
            + %trim(%char(slots(5).mx));
      if slots(5).hp <= 0;
        *in94 = *on;
      else;
        *in94 = *off;
      endif;
    else;
      PW5NAM = *blanks;
      PW5HP = *blanks;
      *in94 = *off;
    endif;

    // Slot 6
    if slots(6).present;
      PW6NAM = slots(6).name;
      PW6HP = %trim(%char(slots(6).hp)) + '/'
            + %trim(%char(slots(6).mx));
      if slots(6).hp <= 0;
        *in95 = *on;
      else;
        *in95 = *off;
      endif;
    else;
      PW6NAM = *blanks;
      PW6HP = *blanks;
      *in95 = *off;
    endif;

    exfmt PKMNWIN;
    if *in12;
      return 0;
    endif;

    choice = FieldToSlotIdx(CSRFLD);
    if choice < 1 or choice > 6;
      iter;
    endif;
    if not slots(choice).present;
      ShowMsg('Empty slot.');
      iter;
    endif;
    if slots(choice).hp <= 0;
      ShowMsg('Can''t send out a fainted Pokemon!');
      iter;
    endif;
    if slots(choice).active = 'Y';
      ShowMsg('Already in battle!');
      iter;
    endif;

    return choice;
  enddo;
end-proc;

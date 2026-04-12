**free
// =============================================================
// POKEMENU - Pokemon Battle Menu & Team Selection
// Handles mode selection and team building, then populates
// BATTLE_SESSION/BATTLE_POKEMON and calls POKEBATTLE.
// =============================================================
ctl-opt dftactgrp(*no) actgrp(*new)
        option(*srcstmt : *nodebugio);

exec sql SET OPTION COMMIT = *NONE;

dcl-f POKEMENUD workstn;

// Call POKEBATTLE with room code + player number
dcl-pr POKEBATTLE extpgm('POKEBATTLE');
  pRoomCode char(8);
  pPlayer   int(5);
end-pr;

// CL command executor for DLYJOB
dcl-pr QCMDEXC extpgm('QCMDEXC');
  cmd    char(256) const;
  cmdLen packed(15:5) const;
end-pr;

// ----- Constants -----
dcl-c MAX_TEAM 6;
dcl-c MAX_ROSTER 18;

// ----- Global Variables -----
dcl-s running ind inz(*on);
dcl-s i int(5);
dcl-s j int(5);

// Roster data (loaded from POKEDEX)
dcl-s rCount int(5);
dcl-s rId    int(5) dim(18);
dcl-s rName  char(12) dim(18);
dcl-s rT1nm  char(10) dim(18);
dcl-s rT2nm  char(10) dim(18);
dcl-s rHP    int(5) dim(18);
dcl-s rAtk   int(5) dim(18);
dcl-s rDef   int(5) dim(18);
dcl-s rSpA   int(5) dim(18);
dcl-s rSpD   int(5) dim(18);
dcl-s rSpeed int(5) dim(18);

// SQL work variables
dcl-s wId    int(5);
dcl-s wName  char(12);
dcl-s wT1nm  char(10);
dcl-s wT2nm  char(10);
dcl-s niT2nm int(5);
dcl-s wHP    int(5);
dcl-s wAtk   int(5);
dcl-s wDef   int(5);
dcl-s wSpA   int(5);
dcl-s wSpD   int(5);
dcl-s wSpeed int(5);

// Team selections
dcl-s plyrTeam int(5) dim(6);
dcl-s plyrCnt  int(5);
dcl-s enmyTeam int(5) dim(6);
dcl-s enmyCnt  int(5);

dcl-s selVal char(2);
dcl-s selNum int(5);
dcl-s randVal packed(7:6);
dcl-s teamStr char(60);
dcl-s lineStr char(70);

// Battle session variables
dcl-s roomCode char(8);
dcl-s wBaseHP int(5);
dcl-s calcHP  int(5);
dcl-s wMvId   int(5);
dcl-s wMvPP   int(5);
dcl-s wMvId1  int(5);
dcl-s wMvId2  int(5);
dcl-s wMvId3  int(5);
dcl-s wMvId4  int(5);
dcl-s wPP1    int(5);
dcl-s wPP2    int(5);
dcl-s wPP3    int(5);
dcl-s wPP4    int(5);
dcl-s wPkmnId int(5);
dcl-s LVL     int(5) inz(50);
dcl-s activeFlg char(1);
dcl-s k int(5);
dcl-s playerNum int(5) inz(1);
dcl-s battleMode char(2);
dcl-s insPlayer int(5);
dcl-s wStatus char(10);
dcl-s wP2Job  char(10);
dcl-s pollCnt int(5);
dcl-s roomFound int(5);
dcl-s initStatus char(10);
dcl-s tCount int(5);
dcl-s tId    int(5);

// =============================================================
// MAINLINE
// =============================================================

// Force job CCSID to 37 so backslash and pipe in DB data survive
// SQL read -> variable -> display field -> device. Inherited by
// POKEBATTLE since it runs in the same job.
QCMDEXC('CHGJOB CCSID(37)' : 16);

// Load roster from POKEDEX
exsr LoadRoster;

// One-time splash screen explaining terminal setup
SPLKEY = ' ';
exfmt SPLASH;
if *in03;
  *inlr = *on;
  return;
endif;

// Main menu loop
dow running;
  MNSEL = ' ';
  exfmt MAINMENU;

  if *in03;
    leave;
  endif;

  select;
    when MNSEL = '1';
      exsr SinglePlayer;
    when MNSEL = '2';
      exsr MultiPlayer;
  endsl;
enddo;

*inlr = *on;
return;

// =============================================================
// SUBROUTINES
// =============================================================

// --- Load Pokemon roster from POKEDEX ---
begsr LoadRoster;
  rCount = 0;

  exec sql DECLARE c_roster CURSOR FOR
    SELECT p.PKMN_ID, p.PKMN_NAME,
           t1.TYPE_NAME, t2.TYPE_NAME,
           p.HP, p.ATTACK, p.DEFENSE,
           p.SP_ATK, p.SP_DEF, p.SPEED
      FROM NHAGENCO1.POKEDEX p
      JOIN NHAGENCO1.TYPES t1 ON t1.TYPE_ID = p.TYPE1
      LEFT JOIN NHAGENCO1.TYPES t2 ON t2.TYPE_ID = p.TYPE2
     ORDER BY p.PKMN_ID
     FETCH FIRST 18 ROWS ONLY;

  exec sql OPEN c_roster;

  for i = 1 to MAX_ROSTER;
    exec sql FETCH c_roster
      INTO :wId, :wName, :wT1nm, :wT2nm :niT2nm,
           :wHP, :wAtk, :wDef, :wSpA, :wSpD, :wSpeed;
    if sqlcode <> 0;
      leave;
    endif;
    rCount += 1;
    rId(i) = wId;
    rName(i) = wName;
    rT1nm(i) = wT1nm;
    if niT2nm >= 0;
      rT2nm(i) = wT2nm;
    else;
      rT2nm(i) = *blanks;
    endif;
    rHP(i) = wHP;
    rAtk(i) = wAtk;
    rDef(i) = wDef;
    rSpA(i) = wSpA;
    rSpD(i) = wSpD;
    rSpeed(i) = wSpeed;
  endfor;

  exec sql CLOSE c_roster;
endsr;

// --- Single Player flow ---
begsr SinglePlayer;
  clear plyrTeam;
  plyrCnt = 0;
  exsr PickTeam;
  if *in03 or *in12;
    leavesr;
  endif;
  if plyrCnt = 0;
    leavesr;
  endif;

  clear enmyTeam;
  enmyCnt = 0;
  exsr PickEnemyTeam;
  if *in03 or *in12;
    leavesr;
  endif;
  if enmyCnt = 0;
    leavesr;
  endif;

  battleMode = 'SP';
  exsr CreateBattle;

  // Insert both teams
  insPlayer = 1;
  exsr InsertTeam;
  insPlayer = 2;
  exsr InsertTeam;

  playerNum = 1;
  POKEBATTLE(roomCode : playerNum);
  exsr CleanupBattle;
endsr;

// --- Multiplayer flow ---
begsr MultiPlayer;
  MPSEL = ' ';
  MPMSG = *blanks;
  exfmt MPMENU;

  if *in03 or *in12;
    leavesr;
  endif;

  select;
    when MPSEL = '1';
      exsr MPCreate;
    when MPSEL = '2';
      exsr MPJoinRm;
  endsl;
endsr;

// --- MP Create Room (Player 1) ---
begsr MPCreate;
  // Pick your team first
  clear plyrTeam;
  plyrCnt = 0;
  exsr PickTeam;
  if *in03 or *in12;
    leavesr;
  endif;
  if plyrCnt = 0;
    leavesr;
  endif;

  // Generate 4-digit room code for MP (1000-9999)
  exec sql SET :randVal = RAND();
  selNum = %int(randVal * 8999) + 1000;
  roomCode = %char(selNum);

  battleMode = 'MP';
  exsr CreateSession;

  // Insert P1 team
  insPlayer = 1;
  exsr InsertTeam;

  // Show room code and wait for P2
  MPCODE = roomCode;
  MPWMSG = 'Waiting for opponent...';
  write MPWAIT;

  wStatus = *blanks;
  dow %trim(wStatus) <> 'READY';
    QCMDEXC('DLYJOB DLY(2)' : 13);

    exec sql
      SELECT TRIM(STATUS) INTO :wStatus
        FROM NHAGENCO1.BATTLE_SESSION
       WHERE ROOM_CODE = :roomCode;
  enddo;

  // Update status to IN_BATTLE
  exec sql
    UPDATE NHAGENCO1.BATTLE_SESSION
       SET STATUS = 'IN_BATTLE'
     WHERE ROOM_CODE = :roomCode;

  playerNum = 1;
  POKEBATTLE(roomCode : playerNum);
  exsr CleanupBattle;
endsr;

// --- MP Join Room (Player 2) ---
begsr MPJoinRm;
  battleMode = 'MP';
  MJCODE = *blanks;
  MJMSG = *blanks;

  dow *in03 = *off and *in12 = *off;
    exfmt MPJOIN;

    if *in03 or *in12;
      leavesr;
    endif;

    roomCode = MJCODE;

    // Check room exists and is waiting
    exec sql
      SELECT COUNT(*) INTO :roomFound
        FROM NHAGENCO1.BATTLE_SESSION
       WHERE ROOM_CODE = :roomCode
         AND TRIM(STATUS) = 'WAITING';

    if roomFound = 0;
      MJMSG = 'Room not found or already in use.';
      iter;
    endif;

    leave;
  enddo;

  if *in03 or *in12;
    leavesr;
  endif;

  // Pick your team
  clear plyrTeam;
  plyrCnt = 0;
  exsr PickTeam;
  if *in03 or *in12;
    leavesr;
  endif;
  if plyrCnt = 0;
    leavesr;
  endif;

  // Insert P2 team
  insPlayer = 2;
  exsr InsertTeam;

  // Signal P1 that we're ready
  exec sql
    UPDATE NHAGENCO1.BATTLE_SESSION
       SET STATUS = 'READY'
     WHERE ROOM_CODE = :roomCode;

  playerNum = 2;
  POKEBATTLE(roomCode : playerNum);
  // P1 handles cleanup
endsr;

// --- Create battle session (SP generates room code, MP already has one) ---
begsr CreateBattle;
  if battleMode = 'SP';
    exec sql
      SET :roomCode =
        'SP' || LPAD(LTRIM(CHAR(INT(RAND() * 999999))), 6, '0');
  endif;
  exsr CreateSession;
endsr;

// --- Insert session row ---
begsr CreateSession;
  if battleMode = 'SP';
    initStatus = 'IN_BATTLE';
  else;
    initStatus = 'WAITING';
  endif;

  exec sql
    INSERT INTO NHAGENCO1.BATTLE_SESSION
      (ROOM_CODE, MODE, STATUS, TURN_STATE)
    VALUES (:roomCode, :battleMode, :initStatus, 'P1_PICK');
endsr;

// --- Insert a team into BATTLE_POKEMON ---
// Uses insPlayer (1 or 2) to determine which team array and player #
// For insPlayer=1: uses plyrTeam/plyrCnt
// For insPlayer=2 in SP: uses enmyTeam/enmyCnt
// For insPlayer=2 in MP: P2 uses plyrTeam/plyrCnt (their own pick)
begsr InsertTeam;
  if insPlayer = 1;
    tCount = plyrCnt;
  else;
    if battleMode = 'SP';
      tCount = enmyCnt;
    else;
      tCount = plyrCnt;
    endif;
  endif;

  for i = 1 to tCount;
    if insPlayer = 1;
      tId = plyrTeam(i);
    else;
      if battleMode = 'SP';
        tId = enmyTeam(i);
      else;
        tId = plyrTeam(i);
      endif;
    endif;
    wPkmnId = tId;

    if i = 1;
      activeFlg = 'Y';
    else;
      activeFlg = 'N';
    endif;

    exec sql
      SELECT HP INTO :wBaseHP
        FROM NHAGENCO1.POKEDEX
       WHERE PKMN_ID = :wPkmnId;
    calcHP = (wBaseHP * 2 * LVL) / 100 + LVL + 10;

    wMvId1 = 0;
    wMvId2 = 0;
    wMvId3 = 0;
    wMvId4 = 0;
    wPP1 = 0;
    wPP2 = 0;
    wPP3 = 0;
    wPP4 = 0;

    exec sql DECLARE c_tmv CURSOR FOR
      SELECT m.MOVE_ID, m.PP
        FROM NHAGENCO1.POKEMON_MOVES pm
        JOIN NHAGENCO1.MOVES m ON m.MOVE_ID = pm.MOVE_ID
       WHERE pm.PKMN_ID = :wPkmnId
         AND pm.LEARN_LVL <= :LVL
       ORDER BY pm.LEARN_LVL DESC
       FETCH FIRST 4 ROWS ONLY;

    exec sql OPEN c_tmv;
    for k = 1 to 4;
      exec sql FETCH c_tmv INTO :wMvId, :wMvPP;
      if sqlcode <> 0;
        leave;
      endif;
      select;
        when k = 1;
          wMvId1 = wMvId;
          wPP1 = wMvPP;
        when k = 2;
          wMvId2 = wMvId;
          wPP2 = wMvPP;
        when k = 3;
          wMvId3 = wMvId;
          wPP3 = wMvPP;
        when k = 4;
          wMvId4 = wMvId;
          wPP4 = wMvPP;
      endsl;
    endfor;
    exec sql CLOSE c_tmv;

    exec sql
      INSERT INTO NHAGENCO1.BATTLE_POKEMON
        (ROOM_CODE, PLAYER, TEAM_SLOT, PKMN_ID,
         LEVEL, CURRENT_HP, MAX_HP,
         MOVE1, MOVE2, MOVE3, MOVE4,
         PP1, PP2, PP3, PP4, IS_ACTIVE)
      VALUES (:roomCode, :insPlayer, :i, :wPkmnId,
              :LVL, :calcHP, :calcHP,
              :wMvId1, :wMvId2, :wMvId3, :wMvId4,
              :wPP1, :wPP2, :wPP3, :wPP4,
              :activeFlg);
  endfor;
endsr;

// --- Clean up battle session rows ---
begsr CleanupBattle;
  exec sql
    DELETE FROM NHAGENCO1.BATTLE_POKEMON
     WHERE ROOM_CODE = :roomCode;
  exec sql
    DELETE FROM NHAGENCO1.BATTLE_SESSION
     WHERE ROOM_CODE = :roomCode;
endsr;

// --- Pick player team ---
begsr PickTeam;
  exsr ShowRoster;
  PKTITLE = 'Choose YOUR team (up to 6)';

  dow plyrCnt < MAX_TEAM;
    // Build team display string
    teamStr = 'Team:';
    for j = 1 to plyrCnt;
      for i = 1 to rCount;
        if rId(i) = plyrTeam(j);
          teamStr = %trim(teamStr) + ' ' + %trim(rName(i));
          leave;
        endif;
      endfor;
    endfor;
    PKTEAM = teamStr;
    PKMSG = *blanks;
    PKSEL = *blanks;

    exfmt PKPROMPT;

    if *in03 or *in12;
      leavesr;
    endif;

    selVal = PKSEL;

    // Done selecting
    if selVal = '0' or selVal = '0 ';
      if plyrCnt > 0;
        leave;
      endif;
      PKMSG = 'Pick at least 1 Pokemon!';
      iter;
    endif;

    // Random fill
    if selVal = 'R' or selVal = 'r'
       or selVal = 'R ' or selVal = 'r ';
      dow plyrCnt < MAX_TEAM;
        exec sql SET :randVal = RAND();
        selNum = %int(randVal * rCount) + 1;
        if selNum > rCount;
          selNum = rCount;
        endif;
        // Check not already on team
        for j = 1 to plyrCnt;
          if plyrTeam(j) = rId(selNum);
            selNum = 0;
            leave;
          endif;
        endfor;
        if selNum > 0;
          plyrCnt += 1;
          plyrTeam(plyrCnt) = rId(selNum);
        endif;
      enddo;
      leave;
    endif;

    // Numeric selection
    monitor;
      selNum = %int(selVal);
    on-error;
      PKMSG = 'Invalid selection.';
      iter;
    endmon;

    if selNum < 1 or selNum > rCount;
      PKMSG = 'Enter 1-' + %trim(%char(rCount));
      iter;
    endif;

    // Check not already on team
    for j = 1 to plyrCnt;
      if plyrTeam(j) = rId(selNum);
        PKMSG = %trim(rName(selNum)) + ' is already on your team!';
        selNum = 0;
        leave;
      endif;
    endfor;
    if selNum = 0;
      iter;
    endif;

    plyrCnt += 1;
    plyrTeam(plyrCnt) = rId(selNum);
    PKMSG = %trim(rName(selNum)) + ' added!';
  enddo;
endsr;

// --- Pick enemy team ---
begsr PickEnemyTeam;
  exsr ShowRoster;
  PKTITLE = 'Choose OPPONENT team (up to 6, R=random)';

  dow enmyCnt < MAX_TEAM;
    teamStr = 'Opponent:';
    for j = 1 to enmyCnt;
      for i = 1 to rCount;
        if rId(i) = enmyTeam(j);
          teamStr = %trim(teamStr) + ' ' + %trim(rName(i));
          leave;
        endif;
      endfor;
    endfor;
    PKTEAM = teamStr;
    PKMSG = *blanks;
    PKSEL = *blanks;

    exfmt PKPROMPT;

    if *in03 or *in12;
      leavesr;
    endif;

    selVal = PKSEL;

    // Done selecting
    if selVal = '0' or selVal = '0 ';
      if enmyCnt > 0;
        leave;
      endif;
      PKMSG = 'Pick at least 1 Pokemon!';
      iter;
    endif;

    // Random fill
    if selVal = 'R' or selVal = 'r'
       or selVal = 'R ' or selVal = 'r ';
      dow enmyCnt < MAX_TEAM;
        exec sql SET :randVal = RAND();
        selNum = %int(randVal * rCount) + 1;
        if selNum > rCount;
          selNum = rCount;
        endif;
        for j = 1 to enmyCnt;
          if enmyTeam(j) = rId(selNum);
            selNum = 0;
            leave;
          endif;
        endfor;
        if selNum > 0;
          enmyCnt += 1;
          enmyTeam(enmyCnt) = rId(selNum);
        endif;
      enddo;
      leave;
    endif;

    monitor;
      selNum = %int(selVal);
    on-error;
      PKMSG = 'Invalid selection.';
      iter;
    endmon;

    if selNum < 1 or selNum > rCount;
      PKMSG = 'Enter 1-' + %trim(%char(rCount));
      iter;
    endif;

    for j = 1 to enmyCnt;
      if enmyTeam(j) = rId(selNum);
        PKMSG = %trim(rName(selNum)) + ' already picked!';
        selNum = 0;
        leave;
      endif;
    endfor;
    if selNum = 0;
      iter;
    endif;

    enmyCnt += 1;
    enmyTeam(enmyCnt) = rId(selNum);
    PKMSG = %trim(rName(selNum)) + ' added!';
  enddo;
endsr;

// --- Populate roster display fields ---
begsr ShowRoster;
  for i = 1 to rCount;
    lineStr = *blanks;

    // Row number (right-justified in 2 chars)
    if i < 10;
      %subst(lineStr:1:2) = ' ' + %char(i);
    else;
      %subst(lineStr:1:2) = %char(i);
    endif;

    // Name
    %subst(lineStr:5:12) = rName(i);

    // Type
    if rT2nm(i) <> *blanks;
      %subst(lineStr:18:15) = %trim(rT1nm(i)) + '/' + %trim(rT2nm(i));
    else;
      %subst(lineStr:18:10) = rT1nm(i);
    endif;

    // Stats (editc Z returns 5 chars for int5, right-justified)
    %subst(lineStr:34:5) = %editc(rHP(i) : 'Z');
    %subst(lineStr:39:5) = %editc(rAtk(i) : 'Z');
    %subst(lineStr:44:5) = %editc(rDef(i) : 'Z');
    %subst(lineStr:49:5) = %editc(rSpA(i) : 'Z');
    %subst(lineStr:54:5) = %editc(rSpD(i) : 'Z');
    %subst(lineStr:59:5) = %editc(rSpeed(i) : 'Z');

    select;
      when i = 1;
        PK01 = lineStr;
      when i = 2;
        PK02 = lineStr;
      when i = 3;
        PK03 = lineStr;
      when i = 4;
        PK04 = lineStr;
      when i = 5;
        PK05 = lineStr;
      when i = 6;
        PK06 = lineStr;
      when i = 7;
        PK07 = lineStr;
      when i = 8;
        PK08 = lineStr;
      when i = 9;
        PK09 = lineStr;
      when i = 10;
        PK10 = lineStr;
      when i = 11;
        PK11 = lineStr;
      when i = 12;
        PK12 = lineStr;
      when i = 13;
        PK13 = lineStr;
      when i = 14;
        PK14 = lineStr;
      when i = 15;
        PK15 = lineStr;
      when i = 16;
        PK16 = lineStr;
      when i = 17;
        PK17 = lineStr;
      when i = 18;
        PK18 = lineStr;
    endsl;
  endfor;

  // Clear unused rows
  for i = (rCount + 1) to MAX_ROSTER;
    select;
      when i = 1;
        PK01 = *blanks;
      when i = 2;
        PK02 = *blanks;
      when i = 3;
        PK03 = *blanks;
      when i = 4;
        PK04 = *blanks;
      when i = 5;
        PK05 = *blanks;
      when i = 6;
        PK06 = *blanks;
      when i = 7;
        PK07 = *blanks;
      when i = 8;
        PK08 = *blanks;
      when i = 9;
        PK09 = *blanks;
      when i = 10;
        PK10 = *blanks;
      when i = 11;
        PK11 = *blanks;
      when i = 12;
        PK12 = *blanks;
      when i = 13;
        PK13 = *blanks;
      when i = 14;
        PK14 = *blanks;
      when i = 15;
        PK15 = *blanks;
      when i = 16;
        PK16 = *blanks;
      when i = 17;
        PK17 = *blanks;
      when i = 18;
        PK18 = *blanks;
    endsl;
  endfor;

  write PKLIST;
endsr;

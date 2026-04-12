# Cursor-Pointer Menus Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use executing-plans to implement this plan task-by-task.

**Ticket:** none (side project)

**Goal:** Convert the battle action menu, move menu, and party popout from input-capable label fields to constant labels with adjacent 1-char `>` pointer slots, and consolidate forced-switch onto the `PKMNWIN` popout.

**Architecture:** Labels become DDS constant text (uneditable by construction). Each selectable option gets a named 1-char input field (`CUR*`) one column to its left, prepopulated with `>` on every `WRITE`. Tab/Backtab stays the selection mechanism; the user binds physical arrow keys to Tab/Backtab client-side in Mocha. `RTNCSRLOC` field-name dispatch moves from the label fields to the new `CUR*` fields. `SWITCHMN` is deleted; post-faint forced switches reuse `PKMNWIN` with a new `FORCED` indicator that hides the F12/back affordance. Fainted party slots have their pointer blanked, and RPG rejects a faint-slot selection as a belt-and-suspenders check.

**Tech Stack:** SQLRPGLE, DDS display file, DB2 for i, Mocha 5250 emulator. IBM i 7.5 on pub400.com.

**Standards:** Project `CLAUDE.md` (5250 WRITE/EXFMT pacing; single self-contained battle program; DDS constraints from memory: 5 leading spaces, no `|` or `\`, REPLACE(\*YES), no multi-stmt-per-line in /free RPG).

---

## Scope

**Files:**
- Modify: `POKEBATTL.DSPF`
- Modify: `POKEBATTLE.SQLRPGLE`
- Create: `docs/mocha-arrow-keymap.md`

**Formats affected:**
- `ACTMENU` — battle action picker (FIGHT / PKMN today; ITEM/RUN not wired)
- `MOVEMENU` — 4-move selection popup
- `PKMNWIN` — voluntary switch popup (3x2 grid, 6 slots)
- `SWITCHMN` — **deleted**, callers retargeted to `PKMNWIN`

**Field renames/additions:**
- `ACTMENU`: `ACTFGT`, `ACTPKM` change from `B` 5A/4A to DDS constants `'FIGHT'` / `'PKMN'`. New `CURFGT`, `CURPKM` (1A `B`) placed one column to the left of each label.
- `MOVEMENU`: `MV1NAM`–`MV4NAM` change from `B` 16A to `O` 16A. New `CURMV1`–`CURMV4` (1A `B`) one column to the left of each.
- `PKMNWIN`: `PW1NAM`–`PW6NAM` change from `B` 12A to `O` 12A. New `CURPW1`–`CURPW6` (1A `B`) one column to the left of each. New `FORCED` (1A `H` hidden) indicator; when `*ON`, the `'F12=Back'` affordance text and `CA12` return are suppressed (set `CA12` to return an indicator RPG ignores when `FORCED = '1'`; simpler: RPG just re-enters `PKMNWIN` if it sees the F12 indicator while `forcedSwitch` is true).

**Out of scope:** ITEM/RUN actions, overworld, any non-menu screens, sound.

---

## Verification

No automated tests — this is an IBM i side project with green-screen UX. Verification per task is:

1. Upload DSPF via `node pub400_dspf.js` (compiles with `REPLACE(*YES)`).
2. Upload + compile RPG via `node pub400_deploy.js` (or the project's existing deploy script).
3. Playtest on Mocha 5250 against pub400: start an SP battle, reach the target menu, exercise the interaction.
4. For MP-affecting changes, run two Mocha sessions against the same room code and confirm both jobs see consistent behavior.

Any compile error → `build-fix` cycle, no moving forward.

Commit after each task only if the task successfully compiled and the relevant menu was playtested. Commits follow the project's existing short-sentence style (no Jira prefix, no Co-Authored-By line — per memory).

---

## Task 1: ACTMENU — labels become constants + add CURFGT / CURPKM pointer slots

**Files:**
- Modify: `POKEBATTL.DSPF` (record format `ACTMENU`, lines ~354-371)

**Changes:**
- Replace `ACTFGT 5A B 26 10 DSPATR(HI) DSPATR(PC)` with a DDS constant `26 11'FIGHT'` (shift label right by 1 col to leave room for pointer at col 10). Keep `DSPATR(HI)`.
- Replace `ACTPKM 4A B 26 30 DSPATR(HI)` with constant `26 31'PKMN'`.
- Add `CURFGT 1A B 26 10 DSPATR(HI) DSPATR(PC)`. `DSPATR(PC)` stays on CURFGT so the initial cursor lands there on first `EXFMT`.
- Add `CURPKM 1A B 26 30 DSPATR(HI)`.
- Leave the `'Move cursor, Enter=Pick'` instruction text; update wording if desired.

**Playtest:**
- SP battle → reach ACTMENU → confirm `>` appears next to both FIGHT and PKMN.
- Cursor initially parks on CURFGT (the `>` next to FIGHT).
- Tab moves to CURPKM. Shift+Tab moves back.
- Try typing a letter into the label — should be impossible (constant).
- Try typing into the `>` slot — accepts 1 char; harmless because RPG ignores the value.
- Press Enter with cursor on each slot; for now the RPG still reads old `ACTFGT`/`ACTPKM` names so Task 2 must follow before this is functional. Don't commit Task 1 standalone — commit Task 1 + Task 2 together.

## Task 2: RPG — ACTMENU cursor dispatch + pointer repaint

**Files:**
- Modify: `POKEBATTLE.SQLRPGLE`

**Changes:**
- Delete `ACTFGT = 'FIGHT';` and `ACTPKM = 'PKMN';` assignments (lines ~325-326). Labels are constants now.
- Before every `exfmt ACTMENU`, set `CURFGT = '>'` and `CURPKM = '>'`.
- `FieldToAction` subprocedure (line ~2216): replace `'ACTFGT'` → `'CURFGT'` and `'ACTPKM'` → `'CURPKM'` in the `when %trim(fld) = ...` branches.

**Verification / playtest:**
- Compile DSPF (Task 1), then RPG.
- SP battle → ACTMENU → cursor on FIGHT slot → Enter → move list appears.
- Back out (F12), Tab to PKMN, Enter → party popout appears.

**Commit:** `Convert ACTMENU to constant labels with cursor pointer slots`

## Task 3: MOVEMENU — move names become output + add CURMV1–CURMV4

**Files:**
- Modify: `POKEBATTL.DSPF` (record format `MOVEMENU`, lines ~308-331)

**Changes:**
- Change `MV1NAM 16A B 2 3` → `MV1NAM 16A O 2 5` (shift right **2 cols** to clear CURMV1's trailing attribute byte — see `feedback_5250_attr_bytes` memory; the CPD7866 warning is the signal). Remove the `DSPATR(PC)` line attached to `MV1NAM`.
- Repeat for `MV2NAM` (col 33), `MV3NAM` (row 3 col 5), `MV4NAM` (row 3 col 33).
- Add `CURMV1 1A B 2 3 DSPATR(HI) DSPATR(PC)`.
- Add `CURMV2 1A B 2 31 DSPATR(HI)`.
- Add `CURMV3 1A B 3 3 DSPATR(HI)`.
- Add `CURMV4 1A B 3 31 DSPATR(HI)`.
- `PC` attribute moves from `MV1NAM` to `CURMV1` so initial cursor lands on the first move pointer.
- **Window size check:** MOVEMENU is `WINDOW(10 30 7 60)` — 60 cols wide. MV2NAM at col 33 width 16 = cols 33-48, MV2PP at col 50 stays put. Fits.

**No commit yet** — paired with Task 4.

## Task 4: RPG — MOVEMENU cursor dispatch + pointer repaint

**Files:**
- Modify: `POKEBATTLE.SQLRPGLE`

**Changes:**
- Before every `exfmt MOVEMENU`, set `CURMV1 = '>'; CURMV2 = '>'; CURMV3 = '>'; CURMV4 = '>';` (one stmt per line per project style).
- `FieldToMoveIdx` (line ~2233): replace `'MV1NAM'`→`'CURMV1'` .. `'MV4NAM'`→`'CURMV4'`.
- `MV1NAM = plyr.moves(1).name;` etc. still assign output values — no change there, just the field type changed from B to O in DDS.

**Playtest:**
- SP battle → FIGHT → move menu opens → `>` next to every move.
- Cursor starts on move 1. Tab cycles. Enter on each move confirms correct move fires.
- F12 returns to ACTMENU as before.

**Commit:** `Convert MOVEMENU to constant move names with cursor pointer slots`

## Task 5: PKMNWIN — party names become output + add CURPW1–CURPW6 + FORCED indicator

**Files:**
- Modify: `POKEBATTL.DSPF` (record format `PKMNWIN`, lines ~373-406)

**Changes:**
- Change `PW1NAM 12A B 3 3` → `PW1NAM 12A O 3 5`. Remove `DSPATR(PC)` line on PW1NAM. (Shift right **2 cols** to clear CURPW1's trailing attribute byte — see `feedback_5250_attr_bytes` memory.)
- Repeat for PW2NAM (3 28), PW3NAM (5 5), PW4NAM (5 28), PW5NAM (7 5), PW6NAM (7 28). Each shifted right by 2 cols.
- PW*HP fields (currently at cols 18, 41) may need to shift right by 2 as well to clear the PW*NAM trailing attribute byte — verify during implementation.
- Add `CURPW1 1A B 3 3 DSPATR(HI) DSPATR(PC)`.
- Add `CURPW2 1A B 3 26 DSPATR(HI)`.
- Add `CURPW3 1A B 5 3 DSPATR(HI)`.
- Add `CURPW4 1A B 5 26 DSPATR(HI)`.
- Add `CURPW5 1A B 7 3 DSPATR(HI)`.
- Add `CURPW6 1A B 7 26 DSPATR(HI)`.
- Move the existing `90`–`95` fainted `DSPATR(HI RI)` indicators from `PWxNAM` to `CURPWx` (so the fainted highlight follows the pointer slot as well — or keep on both; decide during implementation).
- Add `FORCED 1A H` hidden field for RPG control.
- Add a conditional title line: when `FORCED = '1'` display `'Choose a Pokemon (must switch):'`, else keep `'Choose a Pokemon:'`. Implement via an indicator driven by RPG before `exfmt`. If that's awkward in DDS, leave the constant text as-is and drive the hint via an additional message row.
- The existing `CA12(12 'F12=Back')` stays — RPG enforces the forced-switch policy (see Task 6).

**No commit yet** — paired with Task 6.

## Task 6: RPG — PKMNWIN cursor dispatch, pointer repaint, fainted-slot blanking, forced-switch enforcement

**Files:**
- Modify: `POKEBATTLE.SQLRPGLE`

**Changes:**
- Before every `exfmt PKMNWIN`, set each `CURPWn` slot:
  - `'>'` if slot `n` is populated AND not fainted.
  - `' '` (blank) otherwise. This covers empty slots and fainted Pokémon — no pointer, signalling unselectable.
- `FieldToSlotIdx` (line ~2253): replace `'PW1NAM'`→`'CURPW1'` .. `'PW6NAM'`→`'CURPW6'`.
- After reading `CSRFLD`, resolve the slot index. If the selected slot is fainted OR empty, re-show a brief message and loop back to `exfmt PKMNWIN` without changing turn state (defensive — the blank pointer should prevent this, but user could still park cursor on a fainted row and press Enter).
- Forced-switch flag: where `SWITCHMN` was previously used (lines ~1115-1125), set a local `forcedSwitch = *on` boolean, set `FORCED = '1'`, and call the same PKMNWIN routine. When `forcedSwitch` is true and the user presses F12, ignore it (loop back to `exfmt`) — the user must pick a valid non-fainted slot. If every remaining slot is fainted, the battle ends (existing loss logic).
- For the voluntary path, `FORCED = '0'` and F12 returns as normal.

**Playtest:**
- SP battle → PKMN action → PKMNWIN opens → `>` next to every living slot, blank for fainted/empty slots.
- Tab cycles through all 6 slots regardless of fainted status (Tab is field-level, not our concern). Enter on a living slot switches. Enter on a fainted slot re-prompts.
- F12 cancels and returns to ACTMENU.
- Trigger a faint (let player Pokémon die). Verify post-faint prompt opens `PKMNWIN` (not `SWITCHMN`), F12 does nothing, fainted slot blocked, living slot switches in.

**Commit:** `Convert PKMNWIN to cursor pointer slots and route forced switches through it`

## Task 7: Delete SWITCHMN format and remove its RPG callsites

**Files:**
- Modify: `POKEBATTL.DSPF`
- Modify: `POKEBATTLE.SQLRPGLE`

**Changes:**
- Delete the entire `SWITCHMN` record format from `POKEBATTL.DSPF` (lines ~333-352).
- Delete the `ERASE(SWITCHMN)` keyword from `MSGLINE` (line ~298).
- Remove any remaining `SWITCHMN`, `SWSEL`, `SW1NAM`–`SW6NAM`, `SW1HP`–`SW6HP` references from `POKEBATTLE.SQLRPGLE`. Task 6 already retargets the forced-switch call to `PKMNWIN`, so this is dead-code removal.
- Per memory (`feedback_rpg_freeform_one_stmt_per_line`), keep one stmt per line when cleaning up.

**Playtest:**
- Compile DSPF + RPG clean.
- Full SP battle → voluntary switch works → force-switch (faint) works → all via `PKMNWIN`.
- No broken references in compile.

**Commit:** `Delete SWITCHMN record format and dead references`

## Task 8: MP regression check

**Files:** none (playtest only)

**Verification:**
- Two Mocha sessions, same room code. Run a full MP battle.
- Both players reach ACTMENU, MOVEMENU, and (at least one) PKMNWIN path.
- Confirm shared-random damage resolution still works.
- Confirm the `exchange BATTLE_SESSION switch action` path from commit `d2fd11a` still resolves correctly with the new forced-switch flow in PKMNWIN.

**If regressions found:** stop, file the specifics in the plan, invoke `systematic-debugging`. Do not paper over.

**Commit (if no regressions):** none — this is a verification task.

## Task 9: Mocha arrow-key keymap doc

**Files:**
- Create: `docs/mocha-arrow-keymap.md`

**Contents:**
- Short how-to for opening Mocha keyboard settings, locating the physical Up/Down/Left/Right arrow entries, and remapping them to the 5250 `Field Advance` (Tab) and `Field Backspace` (Backtab) functions. Screenshot placeholders OK; mark as TODO if you want to add screenshots later from the laptop.
- Note that this is per-workstation config and not enforced by the server.
- Note that without the remap, Tab/Shift+Tab still work as the canonical input — the remap is purely ergonomic.
- Explain why it's needed (native 5250 arrow keys are cell-level cursor movement, not field-level jumps).
- Keep under 60 lines.

**Commit:** `Add Mocha arrow-key remap doc for directional menu navigation`

---

## Refinement Pass

### Task R1: Lint and Format

No formatter for SQLRPGLE/DDS on this project. Skip — manual review only.

### Task R2: Reduce Complexity

**Skill:** `reduce-complexity`
Scan the changed regions of `POKEBATTLE.SQLRPGLE` (cursor dispatch, PKMNWIN repaint, forced-switch flow). Look for nesting >3, methods >30 lines, compound booleans. The pointer-blanking block for 6 slots is a likely extraction candidate — consider a small helper proc `SetPointer(slotIdx : Boolean)` → void that sets `CURPW*` based on slot state. Apply only if genuinely clearer.

**Commit (if changes made):** `Reduce complexity in PKMNWIN pointer repaint`

### Task R3: Improve Readability

**Skill:** `improve-readability`
Check the `FieldToXxx` subprocedures — now that field names are `CUR*` prefixed, verify the proc names and variable names still read well. Verify the `forcedSwitch` flag is named consistently across callsites.

**Commit (if changes made):** `Improve readability in cursor dispatch subprocedures`

### Task R4: Make It DRY

**Skill:** `make-it-dry`
`CURFGT = '>'; CURPKM = '>';` and the 4-move and 6-slot equivalents are three separate repaint blocks. If a shared helper doesn't fit (different field names, different counts), leave them alone — rule of three doesn't apply across dissimilar shapes.

**Commit (if changes made):** `Extract shared pointer-repaint helper`

### Task R5: Standards Alignment

Loaded tech standards (`scheels-devs`) are .NET/React — do not apply. The applicable standard set is project `CLAUDE.md` plus the DDS/RPG rules captured in user memory. Manually verify:
- DDS source keeps 5 leading spaces.
- No `|` or `\` in DDS literals.
- DSPF compiled with `REPLACE(*YES)` (existing script handles this).
- RPG free-format keeps one stmt per line.
- Commits are concise, no Co-Authored-By line.

**Commit (if corrections needed):** `Align DDS/RPG changes with project conventions`

---

## Notes / Risks

- **PC attribute placement:** `DSPATR(PC)` must live on exactly one field per format to set initial cursor position. I've placed it on `CURFGT`, `CURMV1`, and `CURPW1`. Double-check the existing format doesn't already set PC elsewhere when moving it.
- **Column math:** See `feedback_5250_attr_bytes` memory. Every 1-char `B` field reserves a trailing attribute byte, so the adjacent constant or field must start at col+2, not col+1. ACTMENU hit this during Task 1 (labels invisible until shifted from col 11/31 to col 12/32). Task 3 and Task 5 column values already bake in the +2 offset.
- **Fainted-slot pointer blanking** relies on RPG knowing which slots are fainted before `exfmt`. The existing fainted indicator logic (`PWxFNT` / indicators 90-95) already has this information — reuse it.
- **F12 enforcement on forced switch** is RPG-side, not DDS-side. The DSPF still declares `CA12`; RPG just loops on the indicator when `forcedSwitch = *on`.
- **MP sync:** the forced-switch path touches `BATTLE_SESSION` for cross-job switch exchange (per commit `d2fd11a`). Task 6 must not break that — if the forced-switch code path changes shape, re-check the exchange logic.
- **Memory: `feedback_dspf_compile`** — compile with `DFRWRT(*NO)`, `FRCDTA`, `CLRL(*NO)`, `REPLACE(*YES)`. Existing script handles it.
- **Memory: `feedback_dds_ccsid_chars`** — don't put `|` or `\` in any DDS literal. `>` is safe.

---

## Out-of-Scope / Deferred

- Live pointer movement (`>` that visually follows Tab in real time) — not possible on 5250 without a host round-trip per keypress; native blinking cursor serves as the "current position" indicator.
- Arrow-key handling without Mocha keymap (would need RPG-side cursor management via F-keys) — deferred unless the keymap approach proves insufficient.
- ITEM / RUN actions — not yet wired in `ACTMENU`; will follow the same pattern when added.

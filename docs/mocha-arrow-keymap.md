# Mocha 5250 — Arrow Key Remap for Menu Navigation

The cursor-pointer menus (FIGHT/PKMN, move selection, party switch) navigate between options using the 5250 **Tab** (Field Advance) and **Shift+Tab** (Field Backspace) keys. Remap the physical arrow keys to those 5250 functions to get directional navigation without adding complexity to the host code.

## Why this is client-side, not server-side

5250 has no built-in "arrow key = next field" concept. Native arrow keys move the cursor one character cell at a time. The 5250 datastream has no way for the host to rebind them. Field-to-field navigation only exists through Tab/Backtab.

The Mocha emulator handles keyboard mapping entirely on the workstation. Nothing changes in DDS or RPG. Other workstations (or other emulators) won't inherit this mapping — it's a per-install setting.

Without the remap, Tab and Shift+Tab still work as the canonical navigation keys. The remap is purely ergonomic.

## Remap steps (Mocha 5250)

1. Open Mocha 5250.
2. Open the keyboard settings: **Edit → Keyboard** (or **Preferences → Keyboard**, depending on version).
3. Find the physical arrow key entries:
   - **Right Arrow**
   - **Down Arrow**
   - **Left Arrow**
   - **Up Arrow**
4. Rebind each one to a 5250 function:
   - Right / Down → `Field Advance` (Tab)
   - Left / Up → `Field Backspace` (Backtab / Shift+Tab)
5. Save the keyboard profile.

Both Right and Down map to Tab because 5250 has only forward/backward field navigation — there is no 2D concept of "next field to the right" vs "next field below." The field order is determined by screen position and DDS declaration order, and Tab just walks it.

## Test it

1. Start a battle. Reach the FIGHT/PKMN action menu.
2. Press Right (or Down) — cursor should jump from `> FIGHT` to `> PKMN`.
3. Press Left (or Up) — cursor should jump back.
4. Press Enter on the desired option.

If the arrow keys still move the cursor one cell at a time, the remap didn't save — reopen the keyboard settings and confirm the bindings.

## Reverting

If the arrow remap interferes with other 5250 applications, remove the bindings in the keyboard settings and the arrows return to native cell-level cursor movement. Tab/Shift+Tab always work regardless.

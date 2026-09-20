# Changelog

### [2026-09-21 08:47] Added

**Tech:** `scripts/touch_controls.gd`, `scripts/garden.gd/gameplay_active` — adaptive touch controls and mobile layouts.

**Dev:** Added capability-based detection without JavaScript eval, tracked multi-touch gestures, analogue walking, centre aiming, repeated care actions, placement controls, lift undo, responsive menus, touch onboarding, virtual keyboard support, browser photo downloads and saved control/display preferences. Mobile graphics reduce resolution, shadows and distant detail; focus loss clears gestures and saves progress. Desktop gameplay no longer depends on touch requiring pointer lock.

**Plain:** Phones and tablets can play with a thumbstick, drag-to-look, large tool buttons and menus made for touch.

**Why:** Makes the same garden accessible without a keyboard or mouse while preserving desktop controls and browser security protections.

### [2026-09-21 08:12] Added

**Tech:** `scripts/garden_art.gd/sign_board`, `scripts/garden.gd/sign_editor_page` — correctly oriented garden labels and custom signs.

**Dev:** Replaced labels behind boards with outward-facing, single-sided text on both faces; added a 64-character plain-text editor, opaque colour picker, placement previews, free edits, and backward-compatible saved sign text and colour. Signs use existing rotation, move and remove tools.

**Plain:** Garden signs read correctly, and you can place your own signs with personal messages and text colours.

**Why:** Makes the garden easier to navigate and gives players another way to make it their own.

### [2026-09-21 08:01] Added

**Tech:** `scripts/experience.gd/settings_page`, `scripts/garden.gd/apply_mouse_look` — independent horizontal and vertical mouse inversion.

**Dev:** Grouped inversion switches under Mouse Look, added a saved `invert_x` preference, and retained the existing `invert_y` key so older saves preserve their vertical setting; both axes apply to walking and photo-mode look.

**Plain:** You can now reverse left/right and up/down mouse movement separately in Settings.

**Why:** Makes camera controls easier to find and adapt to your preferred way of looking around.

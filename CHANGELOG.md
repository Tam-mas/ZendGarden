# Changelog

### [2026-09-26 08:13] Fixed

**Tech:** `garden.gd/fulfill_order`, `load_game`, `catalogue.gd` — saved order IDs, menu labels, and shop additions.

**Dev:** Canonicalized saved inventory/order lookup IDs, added a real JSON-roundtrip delivery regression, halved next-morning transition speed, replaced unsupported menu glyphs with text, clarified Remove, and added a 3-petal limestone stone. Documented shop functions and added an unlisted testing entry.

**Plain:** Saved basket items work for orders, menu prices are readable, and the shop includes a small stone.

**Why:** Fixes blocked deliveries and clarifies the garden tools and purchases.

### [2026-09-26 07:47] Changed

**Tech:** `garden.gd/collect_plant`, `garden_care.gd/collect_wild`, `garden_visitors.gd` — shared collection and visible order inventory.

**Dev:** Disabled kangaroo visits, shared mature-plant yields between pruning and gathering, persisted daily border collection, surfaced baskets in Shop and Orders, disabled incomplete deliveries, and reserved active-order stock when selling surplus. Added order lifecycle, duplicate reward, collection and save regressions.

**Plain:** Pruning now collects items for orders, your basket is easy to find, and only rabbits visit for now.

**Why:** Makes collecting and fulfilling requests clear and prevents accidental sale of requested items.

### [2026-09-23 18:54] Added

**Tech:** `scripts/garden_care.gd`, `scripts/garden_visitors.gd`, `scripts/garden.gd` — outdoor care, animal visits, shop hives and arrow navigation.

**Dev:** Added persistent three-cut outdoor pruning with safe bed pruning, visible rake furrows and upgrade widening with footprint checks, temporary rabbit/kangaroo groups including a joey, and saved hive ornaments with daytime bees. Clarified seed unlock costs and seasonal growth; tomatoes remain plantable year-round. Added gameplay regressions for these features and arrow input.

**Plain:** Clear overgrown paths, rake visible trails, welcome rabbits and kangaroos, place a beehive, and walk using the arrow keys.

**Why:** Makes garden care understandable and useful while adding more life and flexible controls.

### [2026-09-21 13:37] Fixed

**Tech:** `web/shell.html`, `web/viewport.js` — visible-viewport layout and optional fullscreen.

**Dev:** Removed the canvas from document flow, replaced the centred grid launch overlay with a scrollable flex layout, and size both against VisualViewport with resize/orientation handling and safe-area insets. Added a user-initiated fullscreen button with a non-blocking fallback while retaining the existing CSP.

**Plain:** The welcome screen and game fill the available iPad browser area, with the play button reachable and fullscreen available on supported browsers.

**Why:** Lets tablet players reach and play the game instead of seeing a clipped welcome screen below a blank area.

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

# Playing Zend Garden

[Play in your browser](https://zendgarden.pages.dev) · [About the game](../README.md)

### Your first planting

Press **Tab** to open the menus and choose a plant from the seed selection. Aim down at a garden plot and click to plant where the preview appears. Switch to the watering tool to tend it, then keep exploring or press **G** to move on to the next morning. The in-game guide explains the tools and garden systems in more detail.

## Controls

| Control | Action |
| --- | --- |
| **W A S D** or **arrow keys** | Walk |
| **Mouse** | Look around |
| **Shift** | Walk faster |
| **Tab** | Open menus / return to looking around |
| **Left click** | Use the selected tool at the centre crosshair |
| **1–9** | Select wander, plant, water, prune, harvest, move, remove, rake, or hoe |
| **[ / ]** with pruners | Shrink / expand the square within purchased limits |
| **R** with the hoe | Switch between raising and lowering ground |
| **L** | Change the target plant layer where plants overlap |
| **G** | Advance to the next morning |
| **E** | Greet a nearby companion |
| **Q / E** while placing a structure | Rotate it |
| **Mouse wheel** | Adjust the field of view |
| **P** | Enter or leave photo mode |
| **W A S D / Q E** in photo mode | Fly horizontally / down and up |
| **Right mouse drag** in photo mode | Look around |
| **F12** or **Capture** | Save a screenshot |
| **Escape** | Open settings, dismiss the welcome guide, or leave photo mode |

## Life in the garden

A normal in-game day lasts about **10 minutes**, and each season lasts **12 days**. Different plants grow at different speeds, with sunlight, water, and the season affecting their progress. Dormant plants keep their growth progress, and a greenhouse can protect seasonal planting. Trees also provide shade for the plants beneath them.

You can advance to the next morning whenever you want. The garden does not progress while the game is closed, so you can return without having missed anything.

Settings include reduced motion, mouse sensitivity, independent left/right and up/down mouse inversion, field of view, separate audio volume controls, and an option to pause while menus are open.

Move **Music volume** all the way down to silence the music completely; **Nature volume** controls birds, water, rain and other surroundings separately. **Settings → What’s new** shows short notes about meaningful improvements and the current update number. Returning players see new notes once, and can close them with the ×, the bottom button or Escape. Your garden remembers the dismissal.

### Pruning, paths, and visitors

Pruning and gathering a mature plant both add one item to **Your basket**, then the plant must regrow before yielding again. Decorative border plants provide one item per day through either tool. See your collected items in **Shop** or **Orders**; ready orders have an enabled Deliver button. Delivery consumes the requested items and awards petals once, with another request arriving two days later. **Sell spare harvest** keeps the items needed for current orders.

**Gather (5)** collects every ready plant in the highlighted square, including plants sharing a position on different layers. Hold the left mouse button and sweep your aim across the garden to keep collecting; unready plants stay untouched. On touch, hold **Gather** while looking around. The Shop’s **Gather reach** upgrades increase the square from **1.3 m → 2.1 m → 2.9 m**. They cost **45 petals from day 3**, then **90 petals from day 18**, independently of pruner upgrades. Border plants still provide only one item per day.

Outside garden beds, three pruning cuts remove a plant. Planted varieties recover one cut each morning; cleared decorative border plants stay cleared. Pruning inside beds remains safe. To clear lawn grass, use the rake: it leaves a grooved earth path, and upgraded rakes can widen an existing patch. Move or prune plants before raking underneath them. New patches can reveal up to four petals per day.

Tomato seeds cost **23 petals** to unlock. You can plant them in any season; they grow in **summer and autumn**, or year-round inside a greenhouse. The seed selection now explains when you need more petals.

Rabbits occasionally visit open areas. Kangaroo visits are currently disabled. Buy a **Beehive for 65 petals** from the shop and place it to attract its own daytime bees.

Manually watering ground grants **20% faster growth for one in-game day** (ten minutes while the game clock is running). It also benefits plants placed on that soil during the boost. Rewatering refreshes the duration without stacking; rain and soaker systems only provide normal water. Darkened soil marks the active area. Growth is still applied at each new morning.

Each pruner upgrade increases the maximum square’s **side length by 10%**: 1.30 m → 1.43 m → 1.573 m. Equip pruners with **4**, then use **[ / ]** to shrink or expand the square, down to 0.40 m and up to your purchased limit.

The **hoe is included**. Equip it with **9**, press **R** to switch between raising and lowering, then click or hold on unlocked dry ground. Work across a slope to level it. Soil, grass, planting positions and walking collision follow the reshaped surface. Water crossings and structure foundations are protected. Terrain offsets are limited to three metres, with a lower limit above water level. Terrain, watering timers, pruning size and hoe direction are saved.

Lady beetles visit gardens with at least two flower plants or one produce plant. They crawl around those plants during daylight and rest at night.

## Saves and photos

Your garden saves automatically every 20 seconds and when a new day starts. You can also save manually from the menu. The desktop game saves when it closes normally; in the browser, use Save before closing the tab.

The garden’s new home is **zend.garden**. Once the move is enabled, visiting the old
**zend.tammas.com** address in the same browser can carry your garden across while
keeping its original copy there. If you already have a different garden at the new
address, you can choose which to continue. Bookmark the new home for future visits;
this does not synchronise progress between devices or browsers.

The save file is named `garden_v1.json`; screenshots are stored in the `photos` folder alongside it. Standard save locations are:

| System | Garden data folder |
| --- | --- |
| macOS | `~/Library/Application Support/Godot/app_userdata/Zend Garden/` |
| Windows | `%APPDATA%\Godot\app_userdata\Zend Garden\` |
| Linux | `~/.local/share/godot/app_userdata/Zend Garden/` |

Some installations use different locations; see [Godot's user data paths](https://docs.godotengine.org/en/stable/tutorials/io/data_paths.html). Back up your save before experimenting with development changes or starting a fresh garden.

### Personal garden signs

Open **Shop → Custom garden sign** to write up to 64 characters and choose a text colour. Each sign costs 15 petals. Place it on the ground and use **Q/E** to rotate it; the lettering is readable from both sides. Use the **Edit sign** buttons in the Shop to change existing signs for free, or the usual move and remove tools to rearrange them. Your signs are saved with your garden.

### Playing on a phone or tablet

Touch controls appear automatically in portrait or landscape. Hold the **WALK** stick at the lower left and drag the view with your other thumb to look around at the same time. **Tools** and the large action button stay at the lower right. Aim with the centre dot, then tap the action button; hold **Gather**, **Water**, **Rake** or the hoe action to repeat while you look around.

The top bar shows your day and petals, with **Seeds** and **Garden** shortcuts. The tool card explains your selected action, and its extra options sit in a row above the bottom controls. With pruners, use **Smaller / Larger**; tap the plant-layer button to change the target layer. With the hoe, tap **Switch to lower / raise**. Placement offers rotation controls, **Done** returns to walking, and removing a plant or ornament offers **Undo lift** for 12 seconds.

**Garden** opens seeds, the shop, orders, settings, next morning and photo mode. Menus pause movement, and controls reset when the app loses focus or the screen changes orientation. Text fields support the on-screen keyboard, and browser photos download to your device.

In **Settings**, choose Auto, Touch or Keyboard & mouse controls; switch to a left-handed layout; adjust touch-control size, look sensitivity and inversion; and choose graphics quality or 3D resolution. The automatic mobile graphics preset reduces rendering resolution, disables sun shadows, and limits distant decorative meshes. Menus stay at full resolution.

Mobile layouts and simultaneous touch input are covered by automated tests and browser emulation. Performance and on-screen keyboard behaviour still need testing on physical iOS and Android devices, particularly with large gardens. Saves stay with the browser profile and site address; they do not automatically sync across devices or domains.

## Shop reference

Prices are in petals. Select a structure in Shop, then aim at open ground to place it. **Q/E** rotates it; **Move** relocates it. **Remove** (formerly “Lift”) removes a plant or ornament; it does not raise the ground. Removing an ornament refunds its purchase price. Plants do not refund petals, but unlocked seeds stay available. Use the hoe to raise or lower the ground.

| Item | Price | Function |
| --- | ---: | --- |
| Path stone | 3 | Places one small limestone stone for a decorative border or path. |
| Terracotta pot | 25 | Decorative pot. |
| Garden bench | 45 | Decorative seating for a quiet garden corner. |
| Stone lantern | 55 | Glows after dusk. |
| Climbing arbor | 65 | Supports nearby climbing plants. |
| Timber pergola | 100 | Larger frame supporting nearby climbing plants. |
| Glass greenhouse | 120 | Lets plants within 4 metres grow year-round and protects their growing conditions. |
| Lily pond | 75 | Attracts frogs and dragonflies; can hold fish. |
| Bird bath | 40 | Birds land, dip and splash in daylight; nearby calls follow the nature-volume setting. |
| Beehive | 65 | Adds four daytime bees around the hive. |
| Custom garden sign | 15 | Places a sign with your text and colour; existing signs can be edited for free. |
| Stock nearest pond with fish | 20 | Adds decorative fish to an unstocked pond in the current garden area. |
| Soaker system | 45 per bed | From day 7, restores the bed’s plants’ water every morning. |
| Gentle auto-pruner | 45 per bed | From day 7, removes stress from the bed’s plants each morning; does not collect items. |
| Expand bed capacity | 65 | Adds 80 planting capacity to the current bed; repeatable. |
| Watering can upgrades | 45, then 90 | Wider watering area and a longer-lasting water supply. |
| Gather reach upgrades | 45, then 90 | From days 3 and 18; expands the gathering square to 2.1 m, then 2.9 m. Hold Gather to sweep across ready plants. |
| Pruning shears upgrades | 45, then 90 | 10% longer pruning-square sides per upgrade and greater stress reduction; resize with [ / ]. |
| Planting trowel upgrades | 45, then 90 | Shorter delay between planting actions. |
| Garden rake upgrades | 45, then 90 | Wider raked paths and more petals per new patch, within the four-petal daily limit. |
| Open next garden | Varies | Opens the next plot early and discovers three seed varieties; the shop shows its price. Plots also open as days pass. |

First tool upgrades unlock on day 3; second upgrades unlock on day 18. Seed varieties are bought in **Seeds**, where each variety’s unlock price is shown. Unlocking a variety lets you plant it repeatedly without paying for each plant.

Pressing **G** advances to the next morning with a 12-second transition. The reduced-motion setting retains its quick transition option.

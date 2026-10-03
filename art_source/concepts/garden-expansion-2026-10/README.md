# Garden structure and animal concepts

Date: 3 October 2026. Branch: `codex/garden-structure-and-animal-concepts`.

Six original labeled reference sheets generated with the built-in image generation tool. The images explore future 3D art direction; no runtime models, mechanics, save fields or player update numbers change in this concept pass. Exact generation prompts are in [prompts.md](prompts.md).

## Ten proposed structures

These are additions to the eleven current shop furnishings, not replacements. The uses below are proposed mechanics for a later implementation.

| No. | Structure | Appearance | Proposed garden use |
| --- | --- | --- | --- |
| 01 | Potting bench | Weathered oak, zinc top, drawers, pots and open storage | A propagation/work station for cuttings and seed preparation. |
| 02 | Compost bays | Three slatted timber compartments with removable fronts | Turn gathered clippings into a modest soil-care resource. |
| 03 | Rain barrel | Timber staves, metal hoops, screened lid and brass tap | Collect rain and offer a nearby watering-can refill point. |
| 04 | Raised bed frames | Modular timber borders in two heights | Frame planted beds and give small crops a deliberate layout. |
| 05 | Trellis screen | Three freestanding lattice panels with stone feet | Train climbers and divide intimate garden rooms. |
| 06 | Hexagonal gazebo | Open timber posts, shingle roof and built-in seating | A shaded place to rest and invite companions. |
| 07 | Arched footbridge | Shallow timber arch, railings and stone landings | A placeable crossing over narrow water or a low swale; existing scenery bridges remain separate. |
| 08 | Stone fountain | Two limestone tiers and a small catch basin | Gentle water movement and local ambience. |
| 09 | Garden swing | Braced timber A-frame, chained slatted seat | A resting viewpoint with optional slow movement. |
| 10 | Insect hotel | Roofed timber cabinet with reed bundles, drilled wood and twig chambers | A habitat feature for future wildlife interactions, distinct from the existing beehive. |

## Structure sheets

- [All ten structures](01-structures-overview.png): numbered overview.
- [Working garden](02-working-garden.png): structures 01–05, with alternate/construction views.
- [Quiet corners](03-quiet-corners.png): structures 06–10, with alternate views.

The overview establishes the shared direction. Detail sheets explore that direction; small differences in generated proportions are alternatives to resolve when authoring models. Use oak, limestone, terracotta, zinc and aged brass, restrained weathering, real contact points and silhouettes readable from normal play distance. Gazebo and bridge placement must provide navigable routes; raised frames need to work with existing plant placement and save compatibility. Rain collection, propagation and compost are proposals, not existing systems.

## Complete animal inventory and behaviour briefs

All twelve `assets/wildlife/*.glb` models and both `assets/companions/*.glb` models are covered. The kangaroo-with-joey asset is a mother carrying a baby, not a standalone baby model. The catalogue mentions moth attraction, but there is no existing moth model; it is not counted as an existing animal.

| Existing asset | New appearance direction | Existing role and poses informing the sheet |
| --- | --- | --- |
| `cat.glb` | Ginger mackerel tabby, cream paws/chest, amber-green eyes, sage collar | Wander safe paths, visit the player, respond to come/settle, enjoy petting and stretch in daytime. |
| `dog.glb` | Sable-and-white collie, white blaze/ruff, tipped ears, sage collar | Wander paths, visit, respond to come/settle, enjoy petting, sniff and wag. |
| `rabbit.glb` | Small agouti rabbit, cream underside and cotton tail | Timed open-ground visits, pauses and low hops away from beds. |
| `kangaroo.glb` | Tawny adult with powerful hindquarters, long feet and balancing tail | Supported visitor model and group movement with pauses/low hops. The current automatic visitor timer spawns rabbits; kangaroo spawning is supported separately. |
| `kangaroo_joey.glb` | Adult mother with a small joey peeking from the pouch | Mother variant in a kangaroo visitor group; secure pouch in movement. |
| `songbird.glb` | Warm-brown sparrow-like bird with buff chest | Trees/baths attract it; fly in, perch, drink, bathe and leave the bath during daylight. |
| `native_bird.glb` | Grey/olive honeyeater-inspired bird with yellow accents and curved beak | Native plants attract it; also visits and bathes at bird baths. This is a new visual direction, not an exact species claim. |
| `frog.glb` | Mottled olive pond frog with folded hind legs and splayed toes | Ground-level pond visitor, shown crouching and beginning a low hop. |
| `fish.glb` | Copper-and-cream koi-like fish with a tapered body and delicate fins | Appears only in stocked ponds and swims looping curves, readable from above. |
| `bee.glb` | Golden fuzzy bee with dark bands and clear wings | Visits flower-rich gardens; placed hives bring their own daylight bees. |
| `butterfly.glb` | Ochre wings, dark scalloped margins and pale edge spots | Visits flower-rich gardens; flight and perched pose references. |
| `dragonfly.glb` | Slender teal body, compound eyes and four veined wings | Pond-associated flying visitor; hovering and skimming references. |
| `firefly.glb` | Dark beetle with localized yellow-green abdominal light | Moss-associated visitor visible at dusk/night. |
| `lady_beetle.glb` | Scarlet domed wing cases, flush black spots, cream pronotum markings | Daylight crawler near flowers or produce, with articulated legs. |

## Animal sheets

- [Companions and visitors](04-companions-and-visitors.png): cat, dog, rabbit, kangaroo, mother with joey.
- [Birds and pond life](05-birds-and-pond-life.png): songbird, native bird, frog, pond fish.
- [Small wildlife](06-small-wildlife.png): bee, butterfly, dragonfly, firefly, lady beetle.

Animals are enlarged independently for clear inspection; these sheets are not relative-size charts. Each panel includes a primary appearance and behaviour pose. The redesigns were generated from text descriptions of identity and role, without using the old mesh renders as visual targets. These images are art references, not topology, rigging or exact anatomical specifications. Check small limb/wing details when building meshes; maintain readable silhouettes, plausible joints and separate animated parts.

Behaviour sources: [`scripts/companion.gd`](../../../scripts/companion.gd), [`scripts/garden_visitors.gd`](../../../scripts/garden_visitors.gd), [`scripts/bath_life.gd`](../../../scripts/bath_life.gd), [`scripts/garden.gd`](../../../scripts/garden.gd). Identity sources: [`build_companions.py`](../../build_companions.py), [`build_wildlife.py`](../../build_wildlife.py). Existing furniture list: [`scripts/catalogue.gd`](../../../scripts/catalogue.gd).

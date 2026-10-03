# New wildlife and existing structure concepts

Date: 3 October 2026. Branch: `codex/more-wildlife-and-structure-concepts`.

Twelve additional animal ideas and seven original labeled reference sheets: three wildlife sheets, three covering all eleven existing shop furnishings, and one covering five permanent scenery groups. Each selected image is 1536 × 1024. The exact generation prompts, reference roles and insect-sheet correction are in [prompts.md](prompts.md).

This is a concept-art and design-brief pass. Animal behaviors below are proposals for later development. No runtime meshes, spawn rules, saved gardens, gameplay or player update versions change here. The earlier [ten new structure concepts and fourteen existing animal redesigns](../garden-expansion-2026-10/README.md) remain available separately.

## Twelve additional animals

All twelve are additions to the existing asset inventory. The blue-banded bee is a separate native visitor with a different appearance and movement from the current generic bee. The four named bird species extend the current songbird and generic native-bird models. The moth is new: the plant catalogue mentions moth attraction, but there is no current moth model.

| No. | Animal and appearance | Proposed movement and personality | Proposed visits, habitat and response to the player |
| --- | --- | --- | --- |
| 01 | **Short-beaked echidna** — cream-tipped spines through dark coarse fur, long tubular snout, short clawed legs. | Methodical, solitary forager. Takes short uneven steps, noses leaf litter and pauses beside fallen timber. | Occasional visits to quiet native borders on cooler mornings or evenings. Stops and tucks down if the player comes too close; resumes after the player backs away. |
| 02 | **Bare-nosed wombat** — heavy grey-brown barrel body, broad dark bare nose, rounded ears and short strong legs. | Slow and lumbering during relaxed visits. Long grazing pauses, weight shifting before each step, a steady familiar route. | Mostly dusk and overcast visits to grassy edges. Gives the player a long wary pause, then ambles toward cover. The slow gait is a calm game personality, not a claim that real wombats cannot run. |
| 03 | **Red fox** — slender russet body, black lower legs, cream chest and white-tipped bushy tail. | Extremely shy observer. Stands briefly, listens with alert ears, looks back and quietly withdraws. | Rare dusk sightings at the distant tree line only. A long visit cooldown preserves the surprise. Never enters the central beds or approaches for petting; withdraws when the player approaches its viewing area. It is not grouped with native Australian wildlife. |
| 04 | **Superb fairy-wren** — blue-and-black breeding male with upright slender tail; warm-brown female variation. | Energetic tiny ground hopper, quick tail flicks, short low flights between shrubs. | Small group visits to dense low native planting during daylight. Stays near cover; slips into shrubs when approached. Patient standing still allows a closer view. |
| 05 | **Laughing kookaburra** — cream/brown large-headed kingfisher, dark eye stripe, sturdy beak and barred tail. | Patient lookout. Holds a high perch, slowly turns its head, occasionally opens its beak for a laugh. | Infrequent tree or pergola visits around dawn and late afternoon. One short call followed by a long quiet interval. Flies to a farther perch when approached closely. |
| 06 | **Rainbow lorikeet** — green wings/tail, blue head and belly, orange-red chest and hooked orange beak. | Sociable and acrobatic. Arrives in pairs, hangs sideways or upside down to inspect blossoms, then leaves together. | Brief daytime visits to flowering trees. Soft short chatter, longer periods feeding quietly; takes off as a pair if startled. Nectar visiting supplies the behavioral pose rather than ground walking. |
| 07 | **Australian magpie** — black-and-white body, pale pointed beak, red-brown eyes and strong walking legs. | Deliberate lawn walker. Tilts its head, probes the grass, and sings from a low rail. | Returns to open grass at morning intervals. A future familiarity state could reduce its stand-off distance after repeated calm visits. Avoid a swooping or crop-damage mechanic in this tranquil garden. |
| 08 | **Blue-banded bee** — tawny fuzzy thorax, dark abdomen with turquoise hair bands, clear paired wings. | Fast darting movement with brief hovering, then a curled vibrating pose at flower anthers. | Warm daylight among flowering plants. Short solitary visits, independent of the existing hive. Moves to another blossom when the watering spray reaches its flower. |
| 09 | **Hoverfly** — yellow/black bands, large fly eyes, tiny antennae and one pair of clear wings. | Holds almost perfectly still in the air, suddenly darts sideways, then hovers again. | Frequent but brief daytime visits above flowers and vegetable borders. Maintains a small buffer around moving tools. Its flight differs from the bee's flower-to-flower buzzing. |
| 10 | **Praying mantis** — leaf-green elongated body, triangular head, folded grasping forelegs and four walking legs. | Watchful stem sitter. Remains still, slowly tracks movement with its head and climbs with measured steps. | Uncommon appearances in tall grass and sturdy stems. Freezes when noticed; slowly moves behind a leaf if the player crowds it. Observation supplies interest without combat or visible predation. |
| 11 | **Spiny leaf insect** — tan dried-leaf form, leaf-like leg lobes, small spines and curled abdomen. | Camouflaged discovery animal. Sways gently like a dry leaf and makes very slow climbing movements. | Rare resident-like visits on eucalyptus foliage. Stays still when approached; subtle swaying helps a patient player notice it. Ground and plant lighting must keep it visible enough to discover. |
| 12 | **Emperor gum moth** — large buff-brown scaled wings, four eye spots, fuzzy thorax and feathery antennae. | Slow broad fluttering and long bark-resting poses, distinct from daytime butterfly flitting. | Rare dusk/night appearance around eucalyptus and the existing soft lantern light. Lands nearby after a few loops, then departs; pauses during daytime. Do not give the adult a nectar-feeding animation. |

Visit timings, rarity, familiarity and player reactions are deliberate game-design choices. Keep wildlife calm and varied, with no damage to crops or destructive digging. Ground visitors should follow safe terrain routes, avoid beds/structures and preserve room for companions. Flying visitors need bounded routes and reliable perches. Give calls and visual visits separate cooldowns so the garden remains quiet. Future implementation should budget simultaneous visitors and vary idle pauses rather than merely changing the speed of one shared wandering animation.

## Animal sheets

- [New mammals](01-new-mammals.png): echidna, wombat and fox, including the fox's distant woodland vignette.
- [Four new birds](02-four-new-birds.png): fairy-wren, kookaburra, lorikeet and magpie, with contrasting poses and the fairy-wren's female variation.
- [Five new insects](03-five-new-insects.png): blue-banded bee, hoverfly, mantis, spiny leaf insect and emperor gum moth.

Subjects are enlarged independently to show detail. These are concept references rather than relative-size charts or rigging specifications. The selected insect sheet includes a targeted correction to shorten the hoverfly antennae. Check small feet, wings and joint connections against real references when building meshes.

## All eleven current placeable structures

Inventory checked against [`GardenCatalogue.furnishings()`](../../../scripts/catalogue.gd) and [`build_shop.py`](../../build_shop.py). The current rendered-model reference is preserved in [references/current-shop-models.png](references/current-shop-models.png), with a separate [current greenhouse portrait](references/current-greenhouse.png). Each image uses those existing shapes as the starting point, then adds fine grain, wear, joinery, stone pores, glazing or water detail.

| Current name | Runtime kind | Shape to preserve | Reference sheet |
| --- | --- | --- | --- |
| Garden bench | `bench` | Four seat slats, two back slats, wooden armrests and dark iron frame/legs. | [Timber structures](04-existing-timber-structures.png) |
| Climbing arbor | `arbor` | Shallow rectangular portal, four posts on stone feet, side diamond trellis and flat exposed rafters. | [Timber structures](04-existing-timber-structures.png) |
| Timber pergola | `pergola` | Deeper square four-post open canopy with exposed rafters and side trellis. | [Timber structures](04-existing-timber-structures.png) |
| Beehive | `hive` | Two stacked rectangular brood boxes, flat overhanging metal cap, low four-leg stand and landing board. | [Timber structures](04-existing-timber-structures.png) |
| Lily pond | `pond` | Small circular ground-level pool, irregular stone ring, lily pads and pink flowers. | [Stone and water](05-existing-stone-and-water.png) |
| Bird bath | `bath` | Shallow circular stone bowl, slim turned pedestal and broad round foot. | [Stone and water](05-existing-stone-and-water.png) |
| Stone lantern | `lantern` | Round pedestal/base, square four-window hearth, flared round roof and small finial. | [Stone and water](05-existing-stone-and-water.png) |
| Path stone | `stone` | One thin, flat, irregular rounded limestone stepping stone. | [Stone and water](05-existing-stone-and-water.png) |
| Glass greenhouse | `greenhouse` | Rectangular timber/glass house with straight pitched gable roof, sloped glazing and one glass door. | [Glass and garden objects](06-existing-greenhouse-pot-and-sign.png) |
| Terracotta pot | `pot` | Plain tapered round clay vessel, thick flared rim and soil inside. | [Glass and garden objects](06-existing-greenhouse-pot-and-sign.png) |
| Custom garden sign | `sign` | Low wide horizontal framed oak board on two short posts, cream lettering and bronze rivets. | [Glass and garden objects](06-existing-greenhouse-pot-and-sign.png) |

The arbor remains much shallower than the pergola. Neither gains a solid roof. The greenhouse keeps its current gable form and correctly sloping glass roof; the hive retains its flat cap. The sign keeps two posts, and the bench keeps its metal support frame. Existing footprints, grounding and collision clearances should govern any later model replacement.

## Permanent garden scenery

[Existing garden scenery](07-existing-garden-scenery.png) extends coverage beyond the shop inventory:

| Scenery group | Current shape retained | Existing implementation |
| --- | --- | --- |
| Garden shed / pavilion | Enclosed plaster box, curved hipped shingle roof, one door with arched stone surround, two tall narrow front windows and three steps. | [`build_environment.py`](../../build_environment.py), `GardenPavilion` and `PavilionShingleRoof`. |
| Timber footbridges | Flat straight deck, crosswise timber planks, three posts per side and one top rail; both current crossings share this design. | [`garden.gd`](../../../scripts/garden.gd), `make_bridge()`; placed in [`landscape.gd`](../../../scripts/landscape.gd). |
| Limestone boundary wall | Low three-course staggered wall of irregular pale stones. | [`build_environment.py`](../../build_environment.py), `LimestonePathsAndWalls`. |
| Bed edging and stone paths | Ground-level square beds edged with one low stone row, with loosely spaced flat path stones. | [`build_environment.py`](../../build_environment.py), `PlantableLoam` and `LimestonePathsAndWalls`. |
| Distant lakeside cottages | Small rectangular plaster bodies under simple pitched gable terracotta roofs. | [`build_environment.py`](../../build_environment.py), `DistantLakesideHamlets`. |

The [current garden screenshot](references/current-garden.png) provides context for the borders and partly obscured shed; the complete permanent shapes were checked in their source geometry. Smaller decorative details in generated scenery are art exploration. Preserve the actual roof profiles, footprints and support layout when authoring models. The scenery sheet's shed height caption refers to its roughly 3 m wall height, not its approximately 4.9 m roof-top height. The existing straight bridges are separate from the previously proposed new arched footbridge.

## Wildlife research references

Appearance and general natural behavior were checked against the primary sources below. Visit rarity, approach distances, animation timing, calm temperament and familiarity remain proposed game mechanics. No source photography was copied into the generated wildlife images.

- Echidna's long snout and foraging: [NSW Environment and Heritage — Echidnas](https://www.environment.nsw.gov.au/topics/animals-and-plants/native-animals/native-animal-facts/land-mammals/echidnas).
- Wombat's body, grazing and activity: [Australian Museum — Bare-nosed Wombat](https://australian.museum/learn/animals/mammals/bare-nosed-wombat/).
- Bird identities and appearances: [Superb Fairy-wren](https://birdlife.org.au/bird-profiles/superb-fairy-wren/), [Laughing Kookaburra](https://birdlife.org.au/bird-profiles/laughing-kookaburra/), [Rainbow Lorikeet](https://birdlife.org.au/bird-profiles/rainbow-lorikeet/) and [Australian Magpie](https://birdlife.org.au/bird-profiles/australian-magpie/) — BirdLife Australia.
- Turquoise banding and buzz pollination: [Australian Museum — Common Blue-banded Bee](https://australian.museum/learn/animals/insects/common-blue-banded-bee/).
- Fly anatomy and hovering: [Australian Museum — Hover flies](https://australian.museum/learn/animals/insects/hover-flies/).
- Mantis anatomy and watchful stillness: [Australian Museum — Praying mantises](https://australian.museum/learn/animals/insects/praying-mantises-order-mantodea/).
- Spiny leaf insect's camouflage: [Australian Museum — Leaf and Stick Insects](https://australian.museum/learn/animals/insects/leaf-and-stick-insects-order-phasmatodea/).
- Moth wing reference and night light attraction: [Australian Museum — Moths, butterflies and skippers](https://australian.museum/learn/animals/insects/moths-butterflies-and-skippers-order-lepidoptera/).

## Review notes

All seven selected sheets were visually reviewed for subject coverage, readable labels, broad anatomy, complete main silhouettes and consistency with the current structure references. PNG dimensions and byte-for-byte copies were verified. Every local document link resolves, and all eleven catalogue furnishing kinds are accounted for. Image generation can vary tiny anatomical or construction details; resolve those against the briefs and source models during 3D work. This documentation and art change needs no gameplay build or runtime test.

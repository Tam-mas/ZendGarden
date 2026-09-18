# Botanical morphology pass — 18 September 2026

The catalogue uses common names, often covering many species and cultivars. These models represent recognizable garden forms rather than claiming a precise cultivar identity. Heights remain compressed to fit the game. Placement distances are creative game rules, not horticultural planting advice. Existing catalogue IDs, gameplay layers and growth rules are retained; a hydrangea now has a woody shrub silhouette even though its existing gameplay slot remains “Flower”.

Research used botanical institutions and university extension profiles. All geometry and textures are original; reference photographs are not incorporated into the assets. `botanical_forms.py` contains the morphology; `build_botanicals.py` supplies materials, mesh primitives and deterministic export. Foliage and reproductive organs remain separate for growth and harvest.

## Key corrections and references

| Plant | Model interpretation | Reference |
| --- | --- | --- |
| Eucalyptus | Pale patchy trunk, open irregular crown, elongated hanging adult leaves; a smooth-barked gum interpretation | [RHS eucalyptus](https://www.rhs.org.uk/plants/eucalyptus/growing-guide) |
| Lavender | English lavender: compact silver-grey leafy base, long bare stalks, purple terminal whorls | [RHS lavender](https://www.rhs.org.uk/plants/lavender/growing-guide) |
| Silver birch | Pale trunk with dark marks, light crown, small foliage | [RHS birch](https://www.rhs.org.uk/plants/birch/how-to-grow-birch) |
| Willow | Long pendulous branchlets and narrow leaves | [Kew weeping willow](https://www.kew.org/plants/weeping-willow) |
| Japanese maple | Broad low crown, radiating leaf lobes, red-leaved garden form | [NC State Acer palmatum](https://plants.ces.ncsu.edu/plants/acer-palmatum/) |
| Iris | Basal sword-leaf fans; three upright standards and three falling tepals | [RHS bearded iris](https://www.rhs.org.uk/plants/9256/iris-germanica/details) |
| Foxglove | Basal rosette, tall stems and one-sided open bells | [NC State foxglove](https://plants.ces.ncsu.edu/plants/digitalis-purpurea/) |
| Hydrangea | Broad paired leaves and hemispherical clusters of four-part florets | [RHS shrubby hydrangeas](https://www.rhs.org.uk/plants/hydrangea/shrubby/growing-guide) |
| Sweet pea | Paired leaflets, tendrils, wing-and-standard flowers on climbing stems | [RHS sweet peas](https://www.rhs.org.uk/plants/lathyrus/sweet-peas) |
| Rosemary | Narrow paired leaves on woody stems, small axillary flowers | [NC State rosemary](https://plants.ces.ncsu.edu/plants/salvia-rosmarinus/) |
| Kangaroo paw | Strap foliage, elevated branching stalks, tubular flowers with split tips | [ANBG kangaroo paws](https://www.anbg.gov.au/anigozanthos/) |
| Bottlebrush | Radial red stamens forming cylindrical brushes | [ANBG Callistemon](https://www.anbg.gov.au/gnp/gnp5/cal-brac.html) |
| Banksia, Grevillea | Stout cylindrical banksia inflorescences versus curved projecting grevillea styles; distinct foliage | [ANBG Proteaceae](https://visit.anbg.gov.au/visit/garden-highlights/proteaceae-displays/), [ANBG illustrated plant families](https://visit.anbg.gov.au/static/4a717de3dcec62b894383246b00628de/anbg-document-aus_plant_families.pdf) |
| Wattle | Ferny bipinnate foliage and yellow globular heads, representing a garden wattle of that form | [ANBG native-plant horticulture](https://www.anbg.gov.au/gardens/living/horticulture/index.html) |
| Billy buttons | Basal foliage and golden spherical heads on slender stalks | [University of Sydney Craspedia](https://eflora.sydney.edu.au/browse/craspedia/) |
| Lomandra | Broad, arching strap-leaf tussock | [ANBG Lomandra](https://www.anbg.gov.au/gnp/interns-2007/lomandra-longifolia.html) |
| Lilly pilly | Paired oval foliage and pink-purple fruit | [ANBG Syzygium smithii](https://www.anbg.gov.au/stamps/stamp-syzygium-smithii-2002.html) |
| Feather grass | Fine foliage and loose airy panicles | [Cambridge Botanic Garden](https://www.botanic.cam.ac.uk/the-garden/plant-list/nassella-tenuissima/) |
| Blue fescue | Low blue-grey needle-leaf tuft | [RHS foliage descriptions](https://www.rhs.org.uk/plants/for-places/shade-planting-annuals-bulbs-perennials) |

## Additional catalogue references

The following university profiles informed leaf arrangement, habit, flower structure and fruit placement. The implementation emphasizes the listed visible traits and simplifies fine diagnostic features.

| Plant | Visible traits | NC State Extension reference |
| --- | --- | --- |
| Cosmos | Divided fine foliage, eight broad rays around a central disk | [Cosmos bipinnatus](https://plants.ces.ncsu.edu/plants/cosmos-bipinnatus/) |
| Daisy | Low rosette, white rays and yellow centre | [Leucanthemum vulgare](https://plants.ces.ncsu.edu/plants/leucanthemum-vulgare/) |
| Sunflower | Tall stout stems, broad leaves and large dark-centred heads | [Helianthus annuus](https://plants.ces.ncsu.edu/plants/helianthus-annuus/) |
| Poppy | Cupped broad petals, dark centre and dissected leaves | [Papaver rhoeas](https://plants.ces.ncsu.edu/plants/papaver-rhoeas/) |
| Clematis | Climbing stems, divided leaves and broad starry flowers | [Clematis](https://plants.ces.ncsu.edu/plants/clematis/) |
| Nasturtium | Trailing stems and round shield leaves | [Tropaeolum majus](https://plants.ces.ncsu.edu/plants/tropaeolum-majus/) |
| Creeping thyme | Low branching mat with tiny opposite leaves and flowers | [Thymus serpyllum](https://plants.ces.ncsu.edu/plants/thymus-serpyllum/) |
| Chamomile | Fine divided foliage and small white daisies | [Matricaria chamomilla](https://plants.ces.ncsu.edu/plants/matricaria-chamomilla/) |
| Sedge | Narrow arching leaves in a clump | [Carex](https://plants.ces.ncsu.edu/plants/carex/) |
| Rose | Compound leaves and layered garden-rose blooms | [Rosa](https://plants.ces.ncsu.edu/plants/rosa/) |
| Azalea | Compact leafy shrub and clustered flowers | [Rhododendron](https://plants.ces.ncsu.edu/plants/rhododendron/) |
| Camellia | Broad evergreen leaves and double flowers | [Camellia japonica](https://plants.ces.ncsu.edu/plants/camellia-japonica/) |
| Lilac | Broad paired leaves, tapering panicles of tiny florets | [Syringa vulgaris](https://plants.ces.ncsu.edu/plants/syringa-vulgaris/) |
| Boxwood | Dense rounded bush with small paired leaves | [Buxus sempervirens](https://plants.ces.ncsu.edu/plants/buxus-sempervirens/) |
| Gardenia | Broad leaves and cream double blooms | [Gardenia jasminoides](https://plants.ces.ncsu.edu/plants/gardenia-jasminoides/) |
| Blueberry | Upright shrub, small oval leaves and berry clusters | [Vaccinium corymbosum](https://plants.ces.ncsu.edu/plants/vaccinium-corymbosum/) |
| Cherry blossom | Spreading branching and small pink blossoms | [Prunus serrulata](https://plants.ces.ncsu.edu/plants/prunus-serrulata/) |
| Olive | Narrow silvery foliage and small oval fruit | [Olea europaea](https://plants.ces.ncsu.edu/plants/olea-europaea/) |
| Apple | Broad foliage and hanging rounded fruit | [Malus domestica](https://plants.ces.ncsu.edu/plants/malus-domestica/) |
| Carrot | Fine divided foliage in a basal rosette | [Daucus carota](https://plants.ces.ncsu.edu/plants/daucus-carota/) |
| Tomato | Compound foliage and hanging red fruit clusters | [Solanum lycopersicum](https://plants.ces.ncsu.edu/plants/solanum-lycopersicum/) |
| Lettuce | Overlapping cupped leaves in a low head | [Lactuca sativa](https://plants.ces.ncsu.edu/plants/lactuca-sativa/) |
| Pumpkin | Trailing stems, broad lobed leaves and ribbed fruit at soil level | [Cucurbita pepo](https://plants.ces.ncsu.edu/plants/cucurbita-pepo/) |
| Strawberry | Three leaflets, low growth and red fruit below foliage | [Fragaria × ananassa](https://plants.ces.ncsu.edu/plants/fragaria-x-ananassa/) |
| Pea | Paired leaflets, curling tendrils and hanging pods | [Garden pea](https://plants.ces.ncsu.edu/plants/lathyrus-oleraceus/) |
| Aubergine | Broad foliage and pendulous elongated purple fruit | [Solanum melongena](https://plants.ces.ncsu.edu/plants/solanum-melongena/) |
| Basil | Compact branching with paired broad leaves | [Ocimum basilicum](https://plants.ces.ncsu.edu/plants/ocimum-basilicum/) |
| Corn | Tall jointed stems, long blades, terminal tassels and husked ears | [Zea mays](https://plants.ces.ncsu.edu/plants/zea-mays/) |
| Cucumber | Trailing lobed foliage, tendrils and elongated green fruit | [Cucumis sativus](https://plants.ces.ncsu.edu/plants/cucumis-sativus/) |
| Chilli | Narrow leaves and curved tapered red fruit | [Capsicum annuum](https://plants.ces.ncsu.edu/plants/capsicum-annuum/) |
| Melon | Trailing leafy stems and rounded fruit near the ground | [Cucumis melo](https://plants.ces.ncsu.edu/plants/cucumis-melo/) |

Moss carpet, dichondra, fountain grass, peony, magnolia, lemon, waxflower, radish and beetroot also receive distinct procedural forms. Their common names are interpreted as garden types; further cultivar-level specificity would require assigning scientific names in the catalogue. Moss has small leafy shoots, dichondra kidney leaves, fountain grass fluffy terminal heads, peony divided leaves and layered flowers, magnolia large tepals, lemon elongated yellow fruit, waxflower needle foliage and small five-part flowers, radish a basal rosette, and beetroot broad leaves with red petioles.


Additional follow-up references: [RHS herbaceous peonies](https://www.rhs.org.uk/plants/peony/herbaceous), [UC Extension dichondra](https://ipm.ucanr.edu/weeds-identification-gallery/kidneyweed-dichondra/), [Ohio State fountain grass](https://plantfacts.osu.edu/tmi/Plantlist/pe_oides.html), [ANBG moss structure](https://www.anbg.gov.au/bryophyte/what-is-moss.html), [ANBG Banksia](https://www.anbg.gov.au/banksia/), [RHS magnolias](https://www.rhs.org.uk/garden-inspiration/plants-we-love/magnolias-garden), [RHS citrus](https://www.rhs.org.uk/fruit/citrus/grow-your-own), [RHS beet](https://www.rhs.org.uk/plants/98644/beta-vulgaris/details), and [RHS radishes](https://www.rhs.org.uk/vegetables/radishes/grow-your-own).

Waxflower reference: [Royal Botanic Gardens Victoria, Chamelaucium uncinatum](https://hortflora.rbg.vic.gov.au/taxon/ad9995a6-5340-11e7-b82b-005056b0018f) describes opposite, very narrow leaves; the model uses paired needle foliage and small pink flowers.

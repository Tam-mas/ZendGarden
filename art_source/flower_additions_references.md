# Flower additions: botanical reference and growth direction

Researched 8 October 2026. The 70 entries below preserve the approved order: 10 orchids, 15 wildflowers, 25 cottage-garden flowers, then 20 flowering bushes. IDs 148–217 extend the existing catalogue; the existing moth and cymbidium orchids remain separate plants.

## Scope and interpretation

Each generic proposal resolves to a species or an explicitly named cultivated form. Sources include the Royal Horticultural Society, Australian National Botanic Gardens, Kew, state botanical gardens, the Smithsonian, the Wildlife Trusts, university extension plant profiles, the American Orchid Society and species research. Most profiles include photographs or botanical illustrations. Image-search previews were also inspected for orchid structures, whole plant habit and colour patterns; reference images guide newly authored geometry and are not bundled as game textures.

These are authored representative cultivated heights in metres, including flowering stalks. They describe a useful mature garden size; climate, cultivar and pruning can change the real height. The growth days are compressed gameplay values, not real horticultural estimates. Colour is one chosen natural-looking palette per plant. Flower counts are reduced model representation counts; a botanical head may contain far more individual florets.

The `petals` field counts the principal visible segments used by the mesh, including coloured sepals, tepals or bracts where those supply the display. Notes specify exceptions, such as orchids, flannel flower bracts, Nigella sepals and Lady's mantle flowers without showy petals. It does not imply that every segment is botanically a petal. A bloom radius measures one flower except where the notes explicitly identify a composite head, plume or spray.

The wildlife field is a broad game attraction tag. It is not a claim of obligate pollination by that animal. Paphiopedilum flowers commonly use flies, Brassia can use wasps, and British bee orchids largely self-pollinate. Sterile snowball viburnum is selected for its round flower heads and has low floral food value. Correa and Eremophila have native bird tags because their nectar-bearing tubes are useful to honeyeaters. These caveats should remain visible to any future ecological gameplay author.

## Growth-stage art direction

Use the game's Seedling, Juvenile, Buds and Mature growth phases, following organ development rather than merely scaling a mature plant.

- Seedling: small real vegetative architecture. Bulbs and tubers show narrow emerging shoots or the appropriate rosette. Woody plants show short stems with few leaves. Epiphytic orchids show young divisions or vegetative growths with their characteristic roots and leaf fans; orchid seed germination requires specialised biology and is not represented literally.
- Juvenile: more leaves and branch structure, fewer adult organs, no open flowers. Keep species identity in leaf arrangement, blade shape, wood versus herbaceous stems and basal versus stem foliage. Pseudobulbs appear only in the orchid types that have them.
- Buds: flowering stalks or terminal clusters emerge with enclosed immature flowers. Match pointed orchid and lily buds, spherical composite buds, dense allium bud sheaths and pendent tubular flower buds.
- Mature: open flowers at their real positions and orientations, with some upper or terminal buds retained where racemes flower sequentially. Show structures such as orchid lips, lily stamens, allium pedicels, flower calyces and the underside of pendent bells.

The stage notes include some late-season seed heads and leaf senescence for future use; those observations do not require adding a new runtime stage. Deciduous shrubs that flower before leaf expansion, especially Forsythia and flowering quince, should retain sparse new foliage during their mature flowering model. Bud emergence is a reproductive event on a developed framework and should not erase existing wood.

## Modelling priorities

Use asymmetric orchid geometry, including three sepals, two ordinary petals and a distinct lip. Paphiopedilum needs a pouch and large dorsal sepal; Vanda needs its single upright stem and aerial roots; Brassia needs extended narrow segments. These must remain distinct from the pre-existing moth and cymbidium orchid silhouettes.

Use individual flower geometry for recognisable parts, with instanced florets for large compound heads. Differentiate a flat yarrow corymb, rounded allium umbel, spiny Echinacea cone, soft Astilbe plume and fine Ceanothus cluster. Keep stems and bloom sizes at plausible proportions to the listed height. Flowering shrubs need branching twig frameworks and individual leaf blades, not solid spherical foliage masses.

For lower-detail models, preserve the silhouette, leaf arrangement, flower orientation, colour zoning and diagnostic organs. Petal, foliage-vein and speckle textures may add detail where helpful. Generated bitmap textures should be converted to WebP before game use, keeping transparency for cutout foliage or petals. Photo references are research material; any generated texture remains an authored interpretation.

## Entries and sources

### Orchids

#### 148. Cattleya orchid

Scientific model: **Cattleya labiata**. Authored mature height: **0.50 m**. Form: `orchid_cattleya`; foliage direction: `strap`.

Clumped spindle-shaped pseudobulbs with one broad leathery leaf each. Three narrow sepals frame two broad wavy petals and a forward tubular lip with a magenta ruffled edge and yellow throat. New vegetative growth precedes the sheath, buds, then large open blooms.

Sources: [Reference 1](https://www.aos.org/explore/cattleya), [Reference 2](https://longwoodgardens.org/blog/2022-09-21/orchids-emblems-national-pride).

#### 149. Slipper orchid

Scientific model: **Paphiopedilum insigne**. Authored mature height: **0.30 m**. Form: `orchid_slipper`; foliage direction: `strap`.

Basal fans of plain green narrow leaves, with no pseudobulbs. Solitary flowers on upright stalks: tall white-edged dorsal sepal with maroon spots, two sideways petals, golden-brown inflated pouch, fused lower sepals behind it. A closed bud elongates before the pouch opens.

Sources: [Reference 1](https://www.rhs.org.uk/plants/paphiopedilum/growing-guide), [Reference 2](https://www.rhs.org.uk/plants/pdfs/agm-lists/agm-orchids.pdf), [Reference 3](https://longwoodgardens.org/blog/2022-03-16/orchids-international-floral-emblem).

#### 150. Dancing-lady orchid

Scientific model: **Oncidium sphacelatum**. Authored mature height: **1.00 m**. Form: `orchid_oncidium`; foliage direction: `strap`.

Flattened oval pseudobulbs carry long arching strap leaves. Slender branching sprays of small yellow flowers with brown markings; the broad lobed yellow lip forms a skirt below much smaller sepals and petals. New pseudobulbs and leaves form before branching flower stalks.

Sources: [Reference 1](https://plants.ces.ncsu.edu/plants/oncidium-sphacelatum/).

#### 151. Pansy orchid

Scientific model: **Miltoniopsis vexillaria**. Authored mature height: **0.45 m**. Form: `orchid_pansy`; foliage direction: `strap`.

Compact flattened pseudobulbs with pale green strap foliage. Broad, almost flat pink flowers on gently arching lateral stalks; the large rounded white-marked lip has a yellow basal patch. Keep lip distinct from the two side petals. Emerging growth, arching bud stalk, then open flower faces.

Sources: [Reference 1](https://www.aos.org/explore/miltoniopsis), [Reference 2](https://www.orchids.org/grexes/miltoniopsis-vexillaria).

#### 152. Blue Vanda orchid

Scientific model: **Vanda coerulea**. Authored mature height: **1.20 m**. Form: `orchid_vanda`; foliage direction: `strap`.

One upright monopodial stem with alternating ranks of stout strap leaves and hanging silvery aerial roots. Side racemes bear broad waxy blue flowers with darker tessellated veins; petals twist at their bases and the small lip projects below the central column. Stem and roots develop before buds.

Sources: [Reference 1](https://www.rhs.org.uk/plants/409682/vanda-coerulea/details), [Reference 2](https://www.kew.org/read-and-watch/vanda-ful-vandas).

#### 153. Zygopetalum orchid

Scientific model: **Zygopetalum maculatum**. Authored mature height: **0.60 m**. Form: `orchid_zygo`; foliage direction: `strap`.

Rounded pseudobulbs support glossy pleated lance-shaped leaves. Upright flower spikes carry green sepals and petals blotched brown, plus a broad white lip veined violet. Do not make the lip green. New growth becomes a leafy fan, then forms a spike with sequentially opening buds.

Sources: [Reference 1](https://plants.ces.ncsu.edu/plants/zygopetalum/), [Reference 2](https://www.si.edu/object/zygopetalum-maculatum%3Aofeo-sg_2013-0564B), [Reference 3](https://powo.science.kew.org/taxon/urn%3Alsid%3Aipni.org%3Anames%3A661743-1/general-information).

#### 154. Spider orchid

Scientific model: **Brassia verrucosa**. Authored mature height: **0.60 m**. Form: `orchid_spider`; foliage direction: `strap`.

Oval pseudobulbs with two arching leaves. Arching racemes carry green-yellow flowers with very long narrow sepals and petals, small dark basal marks, and a shorter broad pale spotted lip. The long segments form a spider outline, not a six-pointed symmetrical star. Buds lengthen before unfolding.

Sources: [Reference 1](https://www.aos.org/explore/brassia).

#### 155. Australian rock orchid

Scientific model: **Dendrobium speciosum**. Authored mature height: **0.75 m**. Form: `orchid_rock`; foliage direction: `strap`.

Thick ribbed canes topped by several leathery oblong leaves. Dense curved racemes carry many small cream flowers with yellowish outer parts and a small purple-spotted white lip. Mature canes persist as new shoots appear; crown flower spikes precede the dense flowering sprays.

Sources: [Reference 1](https://www.anbg.gov.au/gnp/interns-2003/thelychiton-speciosum.html).

#### 156. Bee orchid

Scientific model: **Ophrys apifera**. Authored mature height: **0.35 m**. Form: `orchid_bee`; foliage direction: `rosette`.

A terrestrial orchid with a low lance-leaf rosette and sparse upright flowering stem. Three pink sepals surround tiny green petals and a rounded velvety brown bee-like lip with yellow markings. Small basal growth precedes the bracted spike. UK populations commonly self-pollinate; the game wildlife tag is an abstraction.

Sources: [Reference 1](https://www.wildlifetrusts.org/wildlife-explorer/wildflowers/bee-orchid).

#### 157. Early purple orchid

Scientific model: **Orchis mascula**. Authored mature height: **0.40 m**. Form: `orchid_spike`; foliage direction: `rosette`.

Basal rosette of broad lance leaves with purple spots. Upright dense spike of small purple flowers with an arched hood, broad three-lobed spotted lip and rear spur. Leaves establish before the elongated spike; lower flowers open before upper buds, unlike the existing large glasshouse orchids.

Sources: [Reference 1](https://www.rhs.org.uk/plants/11905/orchis-mascula/details).

### Wildflowers

#### 158. Cornflower

Scientific model: **Centaurea cyanus**. Authored mature height: **0.75 m**. Form: `cornflower`; foliage direction: `alternate`.

Thin branching stems with narrow grey-green leaves. Flower heads have enlarged fringed blue outer florets around a compact purple-blue disc, above overlapping scaly bracts. Juvenile growth is a narrow leafy tuft; enclosed bracted heads open into fringed heads, then become straw-coloured seed heads.

Sources: [Reference 1](https://plants.ces.ncsu.edu/plants/centaurea-cyanus/).

#### 159. Corncockle

Scientific model: **Agrostemma githago**. Authored mature height: **0.90 m**. Form: `star`; foliage direction: `opposite`.

Slender hairy stems with opposite narrow leaves. Five broad pink-purple petals with fine dark lines; long pointed green sepals extend visibly between and beyond petals. A leafy seedling becomes a branched plant, pointed buds, then solitary flowers and enlarged seed capsules.

Sources: [Reference 1](https://plants.ces.ncsu.edu/plants/agrostemma-githago/).

#### 160. Red campion

Scientific model: **Silene dioica**. Authored mature height: **0.70 m**. Form: `notched`; foliage direction: `opposite`.

Hairy stems and opposite oval leaves. Pink flowers have five deeply notched petals and a prominent ribbed tubular calyx. Start with a basal leafy clump, then branching stems and enclosed calyces; mature flower faces remain distinctly split into paired petal tips.

Sources: [Reference 1](https://www.rhs.org.uk/plants/17328/silene-dioica/details).

#### 161. Ragged robin

Scientific model: **Silene flos-cuculi**. Authored mature height: **0.60 m**. Form: `ragged`; foliage direction: `opposite`.

Loose branched stems above a basal rosette with narrow upper opposite leaves. Each of five pink petals is divided into four slender ragged lobes. Preserve gaps between strips. Early rosette develops a tall stem, elongated calyx buds, then airy pink flowers; grows in damp meadow ground, not underwater.

Sources: [Reference 1](https://www.wildlifetrusts.org/wildlife-explorer/wildflowers/ragged-robin).

#### 162. Meadow cranesbill

Scientific model: **Geranium pratense**. Authored mature height: **0.75 m**. Form: `star`; foliage direction: `lobed`.

Palmately divided leaves and branched stems carry open violet-blue five-petalled flowers with fine darker veins. Young leaves unfold into the divided mound before buds rise above it; spent flowers form pointed beak-like seed structures. Rounded petal faces distinguish it from the existing daisy-type heads.

Sources: [Reference 1](https://www.wildlifetrusts.org/wildlife-explorer/wildflowers/meadow-cranes-bill).

#### 163. Field scabious

Scientific model: **Knautia arvensis**. Authored mature height: **0.80 m**. Form: `pincushion`; foliage direction: `lobed`.

Basal oblong leaves become deeply divided upper leaves on slender branching hairy stems. Lilac pincushion heads have many small florets, enlarged outer lobes and protruding stamens. A leafy rosette precedes round buds, flattened domed blooms, then rounded seed heads. Radius describes one composite head.

Sources: [Reference 1](https://collections.rhs.org.uk/view/93005/knautia-arvensis), [Reference 2](https://doi.org/10.1111/1365-2745.13938).

#### 164. Yarrow

Scientific model: **Achillea millefolium**. Authored mature height: **0.65 m**. Form: `umbel`; foliage direction: `fern`.

Finely divided feathery leaves along stems. Numerous tiny white composite heads form broad flat-topped corymbs; do not represent a whole corymb as one daisy. A low feathery tuft grows upright, produces clustered buds, then flat flower tables. Radius is the reduced model's whole corymb unit.

Sources: [Reference 1](https://plants.ces.ncsu.edu/plants/achillea-millefolium/).

#### 165. Purple coneflower

Scientific model: **Echinacea purpurea**. Authored mature height: **1.00 m**. Form: `coneflower`; foliage direction: `alternate`.

Upright coarse hairy stems, broad lance leaves, drooping pink-purple ray florets and a prominent copper-orange spiny central cone. Leaf clump develops upright stems, green conical buds, then reflexing rays around the enlarging cone. Retain dark spiny seed cones in the late phase.

Sources: [Reference 1](https://www.rhs.org.uk/plants/72079/rudbeckia-echinacea-purpurea/details), [Reference 2](https://plants.ces.ncsu.edu/plants/echinacea-purpurea/).

#### 166. Black-eyed Susan

Scientific model: **Rudbeckia hirta**. Authored mature height: **0.80 m**. Form: `coneflower`; foliage direction: `alternate`.

Hairy upright stems with simple rough lance leaves. Golden yellow rays surround a raised dark brown dome; cone is shorter and rays flatter than Echinacea. Low leaf growth precedes branched stems and green head buds, then yellow flowering heads and dark seed heads.

Sources: [Reference 1](https://plants.ces.ncsu.edu/plants/rudbeckia-hirta/).

#### 167. Blanket flower

Scientific model: **Gaillardia aristata**. Authored mature height: **0.60 m**. Form: `blanket`; foliage direction: `alternate`.

A basal leafy clump carries branched stems and red-centred daisy heads whose rays have golden tips and three-toothed ends. Raised centres are burgundy-brown. Leaves and stems develop before spherical head buds; rays unfold into a two-tone disc, followed by rounded seed heads.

Sources: [Reference 1](https://plants.ces.ncsu.edu/plants/gaillardia-aristata/).

#### 168. Flannel flower

Scientific model: **Actinotus helianthi**. Authored mature height: **0.60 m**. Form: `flannel`; foliage direction: `lobed`.

Grey-green velvety deeply lobed foliage on softly branching stems. The apparent white petals are long woolly bracts with green tips surrounding a pale yellow-green central umbel of tiny flowers. Small lobed growth precedes fuzzy buds and outward-spreading star-like bracts.

Sources: [Reference 1](https://test.anbg.gov.au/gnp/interns-2002/actinotus-helianthi.html).

#### 169. Strawflower

Scientific model: **Xerochrysum bracteatum**. Authored mature height: **0.75 m**. Form: `strawflower`; foliage direction: `alternate`.

Upright branching stems with lance leaves. Papery overlapping gold-orange bracts surround a yellow disc of true florets; inner bracts stay cupped while outer ones spread. Leafy juvenile stems produce round enclosed heads, then stiff layered blooms. Heads retain a dry papery appearance as they age.

Sources: [Reference 1](https://www.anbg.gov.au/gallery/xerochrysum-bracteatum-adam-forster.html), [Reference 2](https://australianbg.gardenexplorer.org/taxon-8075.aspx).

#### 170. Australian blue pincushion

Scientific model: **Brunonia australis**. Authored mature height: **0.30 m**. Form: `pincushion`; foliage direction: `rosette`.

Low soft obovate leaf rosette with almost leafless slender scapes. Each scape bears a rounded hemispherical blue head made of many tiny flowers with projecting pale styles. Young rosettes precede small rounded buds and lifted blue heads. Radius is a whole composite head.

Sources: [Reference 1](https://plantselector.botanicgardens.sa.gov.au/Plants/Details/37), [Reference 2](https://www.anbg.gov.au/images/photo_cd/brunoniaceae/).

#### 171. Chocolate lily

Scientific model: **Arthropodium strictum**. Authored mature height: **0.70 m**. Form: `lily_star`; foliage direction: `strap`.

Basal narrow strap leaves and an airy branched raceme. Small mauve six-tepalled flowers have central anthers with conspicuous golden hairs; the flower face spreads from a short tube. Strap shoots precede a tall branching stalk, pointed buds and scattered open flowers. Tuberous roots remain below soil.

Sources: [Reference 1](https://plantnet.rbgsyd.nsw.gov.au/cgi-bin/NSWfl.pl?lvl=sp&name=Arthropodium~strictum&page=nswfl), [Reference 2](https://spapps.environment.sa.gov.au/SeedsOfSA/speciesinformation.html?rid=475).

#### 172. Fringed lily

Scientific model: **Thysanotus tuberosus**. Authored mature height: **0.50 m**. Form: `fringed_lily`; foliage direction: `strap`.

Fine grass-like basal leaves below wiry branched stalks. Three broad purple inner tepals have finely fringed margins; three outer tepals are narrower and unfringed, with central yellow anthers. Young grass-like shoots precede pointed buds; retain the contrast between fringed and plain segments when flowers open.

Sources: [Reference 1](https://www.anbg.gov.au/apu/plants/thystube.html), [Reference 2](https://www.anbg.gov.au/stamps/stamp-thysan-tuberosus-05.html).

### Cottage flowers

#### 173. Daffodil

Scientific model: **Narcissus pseudonarcissus**. Authored mature height: **0.40 m**. Form: `daffodil`; foliage direction: `strap`.

Flat blue-green strap leaves and leafless stalks. One slightly nodding flower per stalk, with six pale-yellow tepals and a deeper yellow trumpet as long as the tepals. Bulb shoots emerge before sheathed buds; the trumpet extends and opens. Foliage persists after bloom before yellowing.

Sources: [Reference 1](https://plants.ces.ncsu.edu/plants/narcissus-pseudonarcissus/).

#### 174. Snowdrop

Scientific model: **Galanthus nivalis**. Authored mature height: **0.18 m**. Form: `snowdrop`; foliage direction: `strap`.

Two narrow blue-green leaves per bulb and a slender arching stalk carrying one pendent flower. Three long white outer tepals surround three short inner tepals with green tip marks. Pointed leaf shoots precede a hooked bud and bell; preserve the different lengths of the two tepal whorls.

Sources: [Reference 1](https://plants.ces.ncsu.edu/plants/galanthus-nivalis/).

#### 175. Crocus

Scientific model: **Crocus vernus 'Remembrance'**. Authored mature height: **0.10 m**. Form: `cup`; foliage direction: `strap`.

Very low violet goblets with six overlapping tepals, orange-yellow central stamens and narrow grass-like leaves with a white central stripe. Corm shoots rise with folded flower buds; cups open wider in sunlight and close in poor light. Short flowers stay close to the ground, not on leafy tall stems.

Sources: [Reference 1](https://www.rhs.org.uk/plants/92662/crocus-vernus-remembrance/details), [Reference 2](https://plants.ces.ncsu.edu/plants/crocus/).

#### 176. Hyacinth

Scientific model: **Hyacinthus orientalis**. Authored mature height: **0.30 m**. Form: `hyacinth`; foliage direction: `strap`.

Thick upright basal strap leaves surround a stout leafless stalk bearing a dense cylindrical raceme. Small waxy lavender flowers have tubular bases and six recurved lobes. Bulb leaves and a compact bud cluster emerge together; stalk elongates before lower bells open then upper ones.

Sources: [Reference 1](https://plants.ces.ncsu.edu/plants/hyacinthus-orientalis/).

#### 177. English bluebell

Scientific model: **Hyacinthoides non-scripta**. Authored mature height: **0.40 m**. Form: `bluebell`; foliage direction: `strap`.

Basal strap foliage and a curved scape with blue-violet pendent narrow bells concentrated on one side. Six fused tepals curl back at the tips; cream anthers. Leaf shoots precede the drooping bud stalk; bell rows open while the stalk remains curved, distinguishing native bluebells from stiff Spanish bluebells.

Sources: [Reference 1](https://www.rhs.org.uk/plants/8890/hyacinthoides-non-scripta/details), [Reference 2](https://www.kew.org/plants/bluebell).

#### 178. Giant ornamental allium

Scientific model: **Allium giganteum**. Authored mature height: **1.50 m**. Form: `globes`; foliage direction: `strap`.

Broad basal strap leaves and tall straight leafless scapes. One dense spherical umbel per scape, composed of many lilac six-tepalled star flowers on radiating pedicels. Broad leaves precede stalk elongation; papery bud sheath splits to reveal the expanding sphere. Radius describes a whole umbel.

Sources: [Reference 1](https://plants.ces.ncsu.edu/plants/allium-giganteum/).

#### 179. Lily of the valley

Scientific model: **Convallaria majalis**. Authored mature height: **0.25 m**. Form: `lily_valley`; foliage direction: `strap`.

Two broad smooth elliptical leaves clasp the base of each shoot. A separate arching raceme carries tiny round white pendent bells with six short recurved teeth on one side. Rolled leaf shoots open before green bud rows become white bells. Include broad leaves rather than the narrow straps of bluebells.

Sources: [Reference 1](https://plants.ces.ncsu.edu/plants/convallaria-majalis/).

#### 180. Ranunculus

Scientific model: **Ranunculus asiaticus (double garden form)**. Authored mature height: **0.40 m**. Form: `rosette_bloom`; foliage direction: `lobed`.

Basal divided leaves beneath slim branching flower stems. Double cultivated pink flowers have tightly layered rounded petals spiralling around the centre. Leaf rosette precedes stalks and round buds; outer petals unfold first while inner ones remain cupped. Extra petals describe the selected garden form, not the five-petalled wild species.

Sources: [Reference 1](https://plants.ces.ncsu.edu/plants/ranunculus-asiaticus/).

#### 181. Windflower

Scientific model: **Anemone coronaria**. Authored mature height: **0.35 m**. Form: `anemone`; foliage direction: `lobed`.

Deeply cut basal foliage, a small leaf whorl below each flower, and slim stalks carrying solitary red open cups. Coloured sepals surround a black centre and dark stamens. Leafy rosette develops stalks and oval buds, then broadly spread flowers; plant dies back after flowering.

Sources: [Reference 1](https://plants.ces.ncsu.edu/plants/anemone-coronaria/).

#### 182. Snapdragon

Scientific model: **Antirrhinum majus**. Authored mature height: **0.80 m**. Form: `snapdragon`; foliage direction: `opposite`.

Upright stalks with narrow leaves, opposite lower and often alternate higher. Pink flowers form a raceme, each with a closed two-lipped mouth and swollen lower palate. Seedlings form leafy stems before tight terminal buds; lower dragon-mouth flowers open first beneath the remaining top buds.

Sources: [Reference 1](https://plants.ces.ncsu.edu/plants/antirrhinum-majus/).

#### 183. Sweet William

Scientific model: **Dianthus barbatus**. Authored mature height: **0.45 m**. Form: `dianthus`; foliage direction: `opposite`.

Opposite lance leaves below dense flat terminal clusters. Each five-petalled red-pink flower has toothed petal edges and a pale contrasting eye above a narrow tubular calyx. Juvenile leafy clump becomes short upright stems; clustered buds open into a flower table. Model individual small flowers rather than one enlarged disc.

Sources: [Reference 1](https://plants.ces.ncsu.edu/plants/dianthus-barbatus/).

#### 184. Stock

Scientific model: **Matthiola incana (single-flowered form)**. Authored mature height: **0.60 m**. Form: `stock`; foliage direction: `alternate`.

Grey-green narrow hairy foliage along upright stems. Dense racemes of lavender four-petalled cross-shaped flowers, with upper buds and lower open blooms. Basal leaf growth develops a thick flowering stalk before sequential flowers; choose single stock for visible four-petal form and useful wildlife attraction.

Sources: [Reference 1](https://plants.ces.ncsu.edu/plants/matthiola-incana/).

#### 185. Love-in-a-mist

Scientific model: **Nigella damascena**. Authored mature height: **0.45 m**. Form: `nigella`; foliage direction: `fern`.

Finely thread-divided green foliage and lacy involucral bracts surrounding pale blue five-sepalled flowers. Tiny true petals sit near the centre beneath many stamens. Early feathery growth develops stems, then enclosed buds and open stars; aged flowers become inflated round capsules with conspicuous pointed styles.

Sources: [Reference 1](https://plants.ces.ncsu.edu/plants/nigella-damascena/).

#### 186. Calendula

Scientific model: **Calendula officinalis**. Authored mature height: **0.45 m**. Form: `aster`; foliage direction: `alternate`.

Branching soft stems carry oblong slightly hairy leaves. Orange composite heads have several rows of flat rays and an orange-brown disc, above green involucral bracts. Leafy juvenile growth precedes plump closed heads, then open flowers; curved hooked achenes develop in spent heads.

Sources: [Reference 1](https://plants.ces.ncsu.edu/plants/calendula-officinalis/).

#### 187. Zinnia

Scientific model: **Zinnia elegans (double garden form)**. Authored mature height: **0.75 m**. Form: `zinnia`; foliage direction: `opposite`.

Stiff branching stems with opposite broad rough sessile leaves. Pink double composite heads have stacked rows of broad blunt rays and a small yellow-orange central disc, above overlapping bracts. Leaf pairs build upward, buds swell, then layered rays open. Selected garden form adds rows beyond a single wild-type head.

Sources: [Reference 1](https://plants.ces.ncsu.edu/plants/zinnia-elegans/).

#### 188. Columbine

Scientific model: **Aquilegia vulgaris**. Authored mature height: **0.70 m**. Form: `columbine`; foliage direction: `compound`.

Compound foliage with rounded three-lobed leaflets. Nodding violet flowers have five outer sepals and five inner petals, each with a backward curled nectar spur. Rounded leaf tufts precede branched stems and hanging buds; opened bells retain the conspicuous five hooked spurs above their faces.

Sources: [Reference 1](https://plants.ces.ncsu.edu/plants/aquilegia/), [Reference 2](https://www.rhs.org.uk/plants/aquilegia).

#### 189. Bleeding heart

Scientific model: **Lamprocapnos spectabilis**. Authored mature height: **0.80 m**. Form: `heart`; foliage direction: `compound`.

Divided blue-green foliage beneath arching stems with a one-sided hanging row of pink heart-shaped flowers. Two swollen outer petals surround two protruding white inner petals. Leafy shoots precede curved flower stems and small pendent buds; hearts swell and open, then foliage yellows after the flowering period.

Sources: [Reference 1](https://plants.ces.ncsu.edu/plants/lamprocapnos-spectabilis/).

#### 190. Hellebore

Scientific model: **Helleborus orientalis**. Authored mature height: **0.45 m**. Form: `hellebore`; foliage direction: `compound`.

Leathery palmately divided serrated leaves on long stalks. Nodding dusty-pink cups have five broad sepals surrounding a ring of tubular nectaries and many cream stamens. Low leaf growth develops stout bud stems, then open cups; persistent sepals surround enlarging green follicles after true petals fade.

Sources: [Reference 1](https://plants.ces.ncsu.edu/plants/helleborus-orientalis/).

#### 191. Astilbe

Scientific model: **Astilbe chinensis**. Authored mature height: **0.75 m**. Form: `plume`; foliage direction: `compound`.

Dense mound of divided serrated foliage beneath upright tapering branched pink plumes. Each plume contains many tiny flowers, not large petals. Foliage expands before the branched bud panicles lift above it; flowers open through the plume, then turn bronze-brown. Radius describes one compound plume's base.

Sources: [Reference 1](https://www.rhs.org.uk/plants/astilbe/growing-guide).

#### 192. Penstemon

Scientific model: **Penstemon digitalis**. Authored mature height: **0.90 m**. Form: `tubular`; foliage direction: `opposite`.

Basal lance leaves and opposite upper leaves on upright stems. Loose branched panicles carry white blush-tinged tubular flowers with two upper and three lower lobes, plus a hairy sterile stamen at the throat. Basal clump precedes stems, pendant pointed buds, and open two-lipped tubes.

Sources: [Reference 1](https://plants.ces.ncsu.edu/plants/penstemon-digitalis/).

#### 193. Tall garden phlox

Scientific model: **Phlox paniculata**. Authored mature height: **1.00 m**. Form: `phlox`; foliage direction: `opposite`.

Opposite pointed leaves along stiff upright stalks. Rounded terminal panicles are built of many flat pink five-lobed flower faces, each attached to a long narrow corolla tube. Paired leafy stems develop terminal buds, then a domed floral cluster; retain visible spaces between several flowering stems.

Sources: [Reference 1](https://plants.ces.ncsu.edu/plants/phlox-paniculata/).

#### 194. Canterbury bells

Scientific model: **Campanula medium**. Authored mature height: **0.85 m**. Form: `bell`; foliage direction: `alternate`.

A basal rosette of long rough leaves develops a tall branching stalk carrying large inflated violet-blue bells. Each bell has a broad five-lobed rim and a green star-shaped calyx behind it. First leafy rosette, then leafy stalk and pointed buds, then bells along the upper stem.

Sources: [Reference 1](https://plants.ces.ncsu.edu/plants/campanula-medium/).

#### 195. Oriental lily

Scientific model: **Lilium 'Star Gazer' (Oriental hybrid)**. Authored mature height: **0.90 m**. Form: `oriental_lily`; foliage direction: `alternate`.

Strong upright stem clothed in narrow lance leaves. Large outward/upward-facing pink six-tepalled flowers have white edges, crimson speckles, curved tips and six projecting orange-brown anthers. Leafy bulb shoots elongate before large pointed buds; tepals open widely as stamens extend.

Sources: [Reference 1](https://www.rhs.org.uk/plants/articles/graham-rice/perennials-and-bulbs/get-growing-lilies), [Reference 2](https://www.rhs.org.uk/plants/pdfs/plant-register-supplements/lilies/lily-register-and-checklist.pdf).

#### 196. Sweet violet

Scientific model: **Viola odorata**. Authored mature height: **0.15 m**. Form: `violet`; foliage direction: `heart`.

Low heart-shaped leaf rosettes spread by runners. Small fragrant violet flowers rise on separate thin pedicels, with two upper petals, two lateral petals and a broader lower spurred petal. Young rounded leaves become a low mat before tiny nodding buds and asymmetric flowers appear.

Sources: [Reference 1](https://plants.ces.ncsu.edu/plants/viola-odorata/).

#### 197. Lady's mantle

Scientific model: **Alchemilla mollis**. Authored mature height: **0.45 m**. Form: `froth`; foliage direction: `lobed`.

Soft rounded leaves with shallow scalloped lobes and radiating folds hold water droplets. Airy branched sprays carry tiny lime-yellow flowers with four sepals and no showy petals. Folded leaf shoots widen into a dense mound before fine flower stalks and frothy sprays; radius is the small spray unit.

Sources: [Reference 1](https://plants.ces.ncsu.edu/plants/alchemilla-mollis/).

### Flowering bushes

#### 198. Tropical hibiscus

Scientific model: **Hibiscus rosa-sinensis**. Authored mature height: **2.00 m**. Form: `hibiscus`; foliage direction: `woody`.

Woody upright branching shrub with alternate glossy toothed leaves. Large coral five-petalled funnels have a long central staminal column tipped by five stigmas. Small woody leaf shoots branch outward before pointed buds; opening flowers preserve the projecting column. Mature blooms are borne on new growth.

Sources: [Reference 1](https://plants.ces.ncsu.edu/plants/hibiscus-rosa-sinensis/).

#### 199. Daphne

Scientific model: **Daphne odora**. Authored mature height: **1.40 m**. Form: `cluster`; foliage direction: `woody`.

Compact evergreen framework with glossy alternate leaves crowded near branch tips. Tight terminal clusters of waxy four-lobed flowers, deep pink outside and pale pink-white within, on short tubes. Young shoots acquire dense leaf tips before plump terminal bud clusters open. Preserve leaves during the flowering phase.

Sources: [Reference 1](https://plants.ces.ncsu.edu/plants/daphne-odora/).

#### 200. Japanese pieris

Scientific model: **Pieris japonica**. Authored mature height: **2.00 m**. Form: `pieris`; foliage direction: `woody`.

Dense evergreen branches with narrow glossy leaves in crowded tip clusters and bronze-red new growth. Drooping branched chains of tiny white urn-shaped flowers. Young woody shoots have reddish tips; hanging bud clusters mature before the flowers open. Keep individual urns narrow, with a constricted five-toothed mouth.

Sources: [Reference 1](https://plants.ces.ncsu.edu/plants/pieris-japonica/).

#### 201. Snowball viburnum

Scientific model: **Viburnum opulus 'Roseum'**. Authored mature height: **2.50 m**. Form: `snowball`; foliage direction: `woody`.

Broad deciduous shrub with opposite three-lobed leaves. Spherical terminal heads of sterile enlarged florets start lime-green, becoming white. Young shoots build the branch framework, then leaves unfold and rounded heads expand. This cultivar is sterile and offers little floral food; wildlife is a general gameplay attraction tag.

Sources: [Reference 1](https://plants.ces.ncsu.edu/plants/viburnum-opulus-roseum/).

#### 202. Mock orange

Scientific model: **Philadelphus coronarius**. Authored mature height: **2.40 m**. Form: `mock_orange`; foliage direction: `woody`.

Arching deciduous woody stems with opposite toothed oval leaves. Small groups of four broad white petals surround conspicuous yellow stamens. Young shoots grow into an open arching framework, then leaves and rounded buds; fragrant flowers appear in short lateral clusters rather than large hydrangea heads.

Sources: [Reference 1](https://plants.ces.ncsu.edu/plants/philadelphus-coronarius/).

#### 203. Weigela

Scientific model: **Weigela florida**. Authored mature height: **2.00 m**. Form: `trumpet`; foliage direction: `woody`.

Arching woody branches carry opposite pointed serrated leaves. Pink five-lobed trumpet flowers arise in small groups along side shoots, with paler throats. Young leafy shoots form the arching shrub; narrow tubular buds swell before mouths flare open. Maintain multiple trunk stems and outward branch tips.

Sources: [Reference 1](https://plants.ces.ncsu.edu/plants/weigela-florida/).

#### 204. Deutzia

Scientific model: **Deutzia gracilis**. Authored mature height: **1.20 m**. Form: `cluster`; foliage direction: `woody`.

Compact deciduous shrub with many slender arching stems and opposite narrow serrated leaves. White five-petalled star flowers form short upright racemes along branch tips. New shoots branch into a low mound, followed by leaf pairs and grouped buds; mature blossom shows many separate small stars.

Sources: [Reference 1](https://plants.ces.ncsu.edu/plants/deutzia-gracilis/).

#### 205. Forsythia

Scientific model: **Forsythia x intermedia**. Authored mature height: **2.20 m**. Form: `forsythia`; foliage direction: `woody`.

Long arching cane-like deciduous stems. Bright yellow flowers have four long narrow lobes around a short tube and open along bare wood before leaves. Young vegetative growth builds the framework, then flower buds expand; flowering model should have sparse small emerging opposite leaves, not a dense green canopy.

Sources: [Reference 1](https://plants.ces.ncsu.edu/plants/forsythia-x-intermedia/).

#### 206. Flowering quince

Scientific model: **Chaenomeles speciosa**. Authored mature height: **2.20 m**. Form: `quince`; foliage direction: `woody`.

Tangled thorny upright woody canes with alternate glossy toothed leaves. Coral-red five-petalled cups with many yellow stamens bloom close to older wood before most leaves emerge. Small woody shoots develop a thorned framework, swelling round buds, then blossom with sparse emerging leaves; fruits later become small green-yellow pomes.

Sources: [Reference 1](https://plants.ces.ncsu.edu/plants/chaenomeles-speciosa/).

#### 207. Spirea

Scientific model: **Spiraea x vanhouttei**. Authored mature height: **2.00 m**. Form: `spirea`; foliage direction: `woody`.

A fountain of arching deciduous branches with small alternate shallow-lobed leaves. Dense rounded corymbs of tiny white five-petalled flowers line older branches. Young shoots grow upward then bend outward; grouped buds become a cascading flower-covered outline. Radius is each compact corymb, with visible individual florets.

Sources: [Reference 1](https://plants.ces.ncsu.edu/plants/spiraea-x-vanhouttei/).

#### 208. Abelia

Scientific model: **Abelia x grandiflora**. Authored mature height: **1.60 m**. Form: `tubular`; foliage direction: `woody`.

Fine arching red-brown twigs with small opposite glossy leaves. Pale pink-white tubular flowers have five short spreading lobes and sit among persistent reddish star-shaped sepals. Leafy shoots form an open rounded shrub; slim buds open at shoot tips. Keep rusty calyces after some flowers have fallen.

Sources: [Reference 1](https://plants.ces.ncsu.edu/plants/abelia-x-grandiflora/).

#### 209. Escallonia

Scientific model: **Escallonia rubra**. Authored mature height: **2.00 m**. Form: `cluster`; foliage direction: `woody`.

Dense evergreen branching shrub with small alternate glossy serrated leaves. Deep pink flowers form short terminal clusters, each with a narrow tube and five rounded spreading lobes. Young woody shoots gain dense foliage before tight buds and flower clusters; keep the canopy structured by visible individual leaves.

Sources: [Reference 1](https://plants.ces.ncsu.edu/plants/escallonia-rubra/).

#### 210. Hebe

Scientific model: **Veronica speciosa (syn. Hebe speciosa)**. Authored mature height: **1.20 m**. Form: `hebe`; foliage direction: `woody`.

Compact evergreen shrub with broad glossy opposite leaves in crossing pairs. Short dense magenta-purple flower racemes project from upper leaf axils; tiny four-lobed flowers have long pale stamens. Paired leaf shoots form a rounded framework, then tight spikes elongate and flower. Spikes remain separate from the leaves.

Sources: [Reference 1](https://www.rhs.org.uk/plants/105261/hebe-speciosa/details).

#### 211. Ceanothus

Scientific model: **Ceanothus thyrsiflorus**. Authored mature height: **2.20 m**. Form: `ceanothus`; foliage direction: `woody`.

Evergreen woody framework with small alternate glossy oval leaves showing three basal veins. Numerous dense blue clusters consist of tiny flowers with projecting stamens. Leafy branch growth becomes a rounded shrub before fine clustered buds open into blue clouds. Radius is one compound cluster, not an individual flower.

Sources: [Reference 1](https://plants.ces.ncsu.edu/plants/ceanothus-thyrsiflorus/).

#### 212. Hardy fuchsia

Scientific model: **Fuchsia magellanica**. Authored mature height: **1.60 m**. Form: `fuchsia`; foliage direction: `woody`.

Arching slender woody branches with opposite or whorled serrated leaves. Hanging flowers have a long red tube, four reflexed red sepals, a shorter purple petal skirt and projecting stamens. Young leafy shoots arch outward; elongated pendent buds open into two contrasting tiers, followed later by small dark berries.

Sources: [Reference 1](https://plants.ces.ncsu.edu/plants/fuchsia-magellanica/).

#### 213. Mexican orange blossom

Scientific model: **Choisya ternata**. Authored mature height: **1.80 m**. Form: `choisya`; foliage direction: `woody`.

Dense evergreen shrub with opposite compound leaves, each divided into three glossy oblong leaflets. White five-petalled star flowers with yellow stamens form terminal clusters. Small trifoliate shoots develop a rounded canopy, then compact pale buds and star clusters. Keep the leaflets separate; this is not a single-leaf orange tree.

Sources: [Reference 1](https://plants.ces.ncsu.edu/plants/choisya-ternata/).

#### 214. Correa

Scientific model: **Correa reflexa**. Authored mature height: **1.20 m**. Form: `correa`; foliage direction: `woody`.

Small woody shrub with opposite oval softly hairy leaves. Pendent long tubular red flowers have contrasting green-yellow four-lobed tips and projecting stamens. Young twigs carry paired leaves before hanging bud tubes elongate and tips open. Select the common red-and-green flower form; native honeyeaters use the nectar.

Sources: [Reference 1](https://anbg.gov.au/gnp/gnp7/correa-reflexa.html).

#### 215. Pink boronia

Scientific model: **Boronia pinnata**. Authored mature height: **1.50 m**. Form: `boronia`; foliage direction: `woody`.

Slender arching shrub with opposite pinnate leaves divided into narrow leaflets. Waxy pale pink-mauve flowers have four oval petals and eight central stamens; they form open little stars rather than Correa-like tubes. Young compound-leaved shoots branch before tiny buds and numerous small flowers develop.

Sources: [Reference 1](https://www.anbg.gov.au/gnp/gnp4/boronia-pinnata.html).

#### 216. Flowering tea-tree

Scientific model: **Leptospermum scoparium**. Authored mature height: **2.00 m**. Form: `tea_tree`; foliage direction: `woody`.

Fine twiggy upright shrub with small alternate sharp-pointed leaves. Pale pink five-petalled flowers sit close along twigs, with a dark central disc and a ring of short stamens. Small leafy shoots build fine branches, then round buds and separate open flowers. Woody seed capsules can persist after bloom.

Sources: [Reference 1](https://www.anbg.gov.au/leptospermum/leptospermum-scoparium.html).

#### 217. Spotted emu bush

Scientific model: **Eremophila maculata**. Authored mature height: **1.50 m**. Form: `emu_bush`; foliage direction: `woody`.

Dense twiggy shrub with small alternate lanceolate leaves. Red-orange tubular flowers have a spotted pale interior, curved swollen tube, two upper lobes and three lower lobes; stamens project from the mouth. Young leaves and branches precede curved buds and open tubes. Dry pointed fruits follow flowers.

Sources: [Reference 1](https://anpsa.org.au/plant_profiles/eremophila-maculata/), [Reference 2](https://anbg.gov.au/photo/apii/id/a/30785).

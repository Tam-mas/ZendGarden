class_name GardenCatalogue
extends RefCounted

const CATEGORIES = ["Flowers", "Grasses", "Shrubs", "Trees", "Natives", "Produce", "Cacti & succulents"]
const COLLECTION_GROUPS = ["Orchids", "Wildflowers", "Cottage flowers", "Flowering bushes", "Grasses & groundcovers", "Trees", "Australian natives", "Fruit & vegetables", "Cacti & succulents"]
const ROWS = [
 ["Cosmos", "Flowers", "efb0ba", 1, 2, "sun", "butterflies"],
 ["Lavender", "Flowers", "a894cc", 1, 3, "sun", "bees"],
 ["Daisy", "Flowers", "fff2d1", 1, 2, "any", "butterflies"],
 ["Sunflower", "Flowers", "f2bf53", 1, 3, "sun", "birds"],
 ["Foxglove", "Flowers", "c287b9", 1, 3, "shade", "bees"],
 ["Hydrangea", "Flowers", "a4bde2", 1, 3, "shade", "butterflies"],
 ["Peony", "Flowers", "e89aaa", 1, 4, "sun", "bees"],
 ["Poppy", "Flowers", "ee8868", 1, 2, "sun", "bees"],
 ["Iris", "Flowers", "7e87bd", 1, 3, "water", "butterflies"],
 ["Sweet pea", "Flowers", "dcb1d2", 1, 3, "sun", "butterflies"],
 ["Clematis", "Flowers", "b793d3", 1, 4, "any", "bees"],
 ["Nasturtium", "Flowers", "efa355", 0, 2, "sun", "bees"],
 ["Creeping thyme", "Grasses", "c8acd1", 0, 2, "sun", "bees"],
 ["Moss carpet", "Grasses", "85a568", 0, 2, "shade", "fireflies"],
 ["Blue fescue", "Grasses", "88b9b0", 0, 2, "sun", "birds"],
 ["Feather grass", "Grasses", "d3c59b", 0, 3, "sun", "birds"],
 ["Sedge", "Grasses", "a4b978", 0, 2, "water", "frogs"],
 ["Fountain grass", "Grasses", "c9a9ad", 0, 3, "sun", "birds"],
 ["Dichondra", "Grasses", "abc9a8", 0, 2, "any", "butterflies"],
 ["Chamomile", "Grasses", "f4df9d", 0, 2, "sun", "bees"],
 ["Rose", "Shrubs", "da8f9d", 2, 4, "sun", "bees"],
 ["Azalea", "Shrubs", "dfb0d0", 2, 3, "shade", "butterflies"],
 ["Rosemary", "Shrubs", "a0aed1", 2, 3, "sun", "bees"],
 ["Camellia", "Shrubs", "f1b8bd", 2, 4, "shade", "birds"],
 ["Lilac", "Shrubs", "b4a0c8", 2, 4, "sun", "butterflies"],
 ["Boxwood", "Shrubs", "87a366", 2, 3, "any", "birds"],
 ["Gardenia", "Shrubs", "f5efd4", 2, 4, "shade", "moths"],
 ["Blueberry", "Shrubs", "8097bc", 2, 3, "any", "birds"],
 ["Cherry blossom", "Trees", "eac0cd", 3, 5, "sun", "birds"],
 ["Silver birch", "Trees", "b2c986", 3, 5, "any", "birds"],
 ["Japanese maple", "Trees", "d8a17e", 3, 5, "shade", "birds"],
 ["Olive", "Trees", "9dac85", 3, 5, "sun", "birds"],
 ["Willow", "Trees", "aac68a", 3, 5, "water", "frogs"],
 ["Magnolia", "Trees", "f2d8d7", 3, 5, "any", "birds"],
 ["Lemon", "Trees", "e1ce72", 3, 4, "sun", "bees"],
 ["Apple", "Trees", "dca394", 3, 4, "sun", "birds"],
 ["Kangaroo paw", "Natives", "dca077", 1, 3, "sun", "native birds"],
 ["Billy buttons", "Natives", "ead073", 1, 2, "sun", "native birds"],
 ["Wattle", "Natives", "e6cb72", 2, 4, "sun", "native birds"],
 ["Bottlebrush", "Natives", "d4817e", 2, 4, "sun", "native birds"],
 ["Grevillea", "Natives", "e6a28d", 2, 3, "any", "native birds"],
 ["Banksia", "Natives", "dcb977", 2, 4, "sun", "native birds"],
 ["Lilly pilly", "Natives", "d995a6", 2, 4, "any", "native birds"],
 ["Waxflower", "Natives", "ebc8d9", 1, 3, "sun", "native birds"],
 ["Lomandra", "Natives", "b6be7e", 0, 2, "any", "native birds"],
 ["Eucalyptus", "Natives", "a7c5b1", 3, 5, "sun", "native birds"],
 ["Carrot", "Produce", "e9a364", 0, 2, "sun", "bees"],
 ["Tomato", "Produce", "db8977", 1, 3, "sun", "bees"],
 ["Lettuce", "Produce", "b8cf88", 0, 2, "any", "butterflies"],
 ["Pumpkin", "Produce", "e2a664", 0, 4, "sun", "bees"],
 ["Strawberry", "Produce", "e7999c", 0, 2, "any", "bees"],
 ["Radish", "Produce", "da8a9f", 0, 2, "any", "bees"],
 ["Pea", "Produce", "b9d2a0", 1, 3, "any", "butterflies"],
 ["Aubergine", "Produce", "a18eb1", 1, 3, "sun", "bees"],
 ["Basil", "Produce", "a6c486", 0, 2, "sun", "bees"],
 ["Corn", "Produce", "e5ce82", 1, 3, "sun", "birds"],
 ["Cucumber", "Produce", "99b979", 1, 3, "sun", "bees"],
 ["Chilli", "Produce", "e39d88", 1, 3, "sun", "bees"],
 ["Beetroot", "Produce", "a17e99", 0, 2, "any", "bees"],
 ["Melon", "Produce", "d5c482", 0, 4, "sun", "bees"],
 ["Common jasmine", "Flowers", "fff7e8", 1, 3, "sun", "bees"],
 ["Pink jasmine", "Flowers", "f5e8ea", 1, 3, "sun", "bees"],
 ["Winter jasmine", "Flowers", "efd131", 1, 3, "sun", "bees"],
 ["Dahlia 'Café au Lait'", "Flowers", "eed8c0", 1, 3, "sun", "bees"],
 ["Tulip 'Queen of Night'", "Flowers", "352039", 1, 3, "sun", "bees"],
 ["Blue delphinium", "Flowers", "497bc6", 1, 3, "sun", "bees"],
 ["Purple lupin", "Flowers", "8156aa", 1, 3, "sun", "bees"],
 ["Burgundy hollyhock", "Flowers", "7d263e", 1, 3, "sun", "bees"],
 ["Slender weaver's bamboo", "Grasses", "598747", 2, 4, "sun", "birds"],
 ["Golden bamboo", "Grasses", "c4b55b", 2, 4, "sun", "birds"],
 ["Black bamboo", "Grasses", "343831", 2, 4, "sun", "birds"],
 ["Himalayan blue bamboo", "Grasses", "719b9e", 2, 4, "sun", "birds"],
 ["Red bamboo 'Jiuzhaigou'", "Grasses", "b25342", 2, 4, "sun", "birds"],
 ["Rose 'Mister Lincoln'", "Shrubs", "ab2335", 2, 4, "sun", "bees"],
 ["Rose 'Iceberg'", "Shrubs", "fff9e8", 2, 4, "sun", "bees"],
 ["Rose 'Golden Celebration'", "Shrubs", "eeb638", 2, 4, "sun", "bees"],
 ["Rose 'Just Joey'", "Shrubs", "eaa071", 2, 4, "sun", "bees"],
 ["Rose 'Scentimental'", "Shrubs", "be3047", 2, 4, "sun", "bees"],
 ["Giant redwood", "Trees", "568455", 3, 5, "sun", "birds"],
 ["Coast redwood", "Trees", "447859", 3, 5, "sun", "birds"],
 ["Giant bamboo", "Grasses", "799856", 3, 5, "sun", "birds"],
 ["Ginkgo", "Trees", "91ac51", 3, 5, "sun", "birds"],
 ["Fig", "Trees", "824868", 3, 5, "sun", "birds"],
 ["Pear", "Trees", "b6b349", 3, 5, "sun", "birds"],
 ["Peach", "Trees", "e9a15c", 3, 5, "sun", "birds"],
 ["Plum", "Trees", "654d87", 3, 5, "sun", "birds"],
 ["Apricot", "Trees", "efa44f", 3, 5, "sun", "birds"],
 ["Nectarine", "Trees", "d95838", 3, 5, "sun", "birds"],
 ["Orange", "Trees", "eb9437", 3, 5, "sun", "birds"],
 ["Mandarin", "Trees", "ee9d36", 3, 5, "sun", "birds"],
 ["Lime", "Trees", "75a743", 3, 5, "sun", "birds"],
 ["Avocado", "Trees", "415d35", 3, 5, "sun", "birds"],
 ["Snow gum", "Natives", "a1b4a1", 3, 5, "sun", "native birds"],
 ["Alpine snow gum", "Natives", "a7b8ac", 3, 5, "sun", "native birds"],
 ["Red flowering gum", "Natives", "d83a3d", 3, 5, "sun", "native birds"],
 ["Waratah", "Natives", "c43048", 2, 4, "sun", "native birds"],
 ["Gymea lily", "Natives", "b9303d", 2, 4, "sun", "native birds"],
 ["Globe artichoke", "Produce", "8a9b73", 1, 3, "sun", "bees"],
 ["Rhubarb", "Produce", "b94855", 1, 3, "sun", "bees"],
 ["Asparagus", "Produce", "74a14c", 1, 3, "sun", "bees"],
 ["Broccoli", "Produce", "508053", 1, 3, "sun", "bees"],
 ["Cauliflower", "Produce", "ece8d2", 1, 3, "sun", "bees"],
 ["Capsicum", "Produce", "cb3f31", 1, 3, "sun", "bees"],
 ["Brussels sprouts", "Produce", "7d995f", 1, 3, "sun", "bees"],
 ["Leek", "Produce", "a0b38b", 0, 3, "sun", "bees"],
 ["Hemp", "Produce", "6d9345", 1, 3, "sun", "bees"],
 ["Zebra grass", "Grasses", "8fa15a", 1, 14, "sun", "birds"],
 ["Feather reed grass", "Grasses", "b9a575", 1, 12, "any", "birds"],
 ["Blue switchgrass", "Grasses", "819baf", 1, 14, "sun", "birds"],
 ["Golden forest grass", "Grasses", "c5ba61", 0, 9, "shade", "butterflies"],
 ["Japanese blood grass", "Grasses", "b95353", 0, 10, "sun", "butterflies"],
 ["Purple moor grass", "Grasses", "aa957d", 1, 14, "any", "birds"],
 ["Tufted hair grass", "Grasses", "bfb999", 1, 11, "shade", "birds"],
 ["Quaking grass", "Grasses", "b1a17b", 0, 9, "sun", "birds"],
 ["Autumn moor grass", "Grasses", "b3b968", 0, 9, "any", "birds"],
 ["Pink muhly grass", "Grasses", "c792ab", 1, 12, "sun", "butterflies"],
 ["Golden barrel cactus", "Cacti & succulents", "c9b66e", 1, 18, "sun", "bees"],
 ["Bunny ears cactus", "Cacti & succulents", "a0b56a", 1, 14, "sun", "bees"],
 ["Prickly pear", "Cacti & succulents", "79966b", 2, 18, "sun", "bees"],
 ["Mexican fencepost cactus", "Cacti & succulents", "6d936b", 2, 22, "sun", "moths"],
 ["Old man cactus", "Cacti & succulents", "d8d8cd", 1, 20, "sun", "moths"],
 ["Ladyfinger cactus", "Cacti & succulents", "b5a06c", 0, 12, "sun", "bees"],
 ["Star cactus", "Cacti & succulents", "97a58a", 0, 16, "sun", "bees"],
 ["Holiday cactus", "Cacti & succulents", "d46e86", 1, 12, "shade", "butterflies"],
 ["Mexican snowball", "Cacti & succulents", "a7beb8", 0, 10, "sun", "bees"],
 ["Lipstick echeveria", "Cacti & succulents", "a19f6a", 0, 10, "sun", "bees"],
 ["Hens and chicks", "Cacti & succulents", "8e9f73", 0, 9, "sun", "bees"],
 ["Aloe vera", "Cacti & succulents", "80a18b", 1, 14, "sun", "birds"],
 ["Century plant", "Cacti & succulents", "92aaa7", 2, 22, "sun", "moths"],
 ["Zebra haworthia", "Cacti & succulents", "a2b298", 0, 10, "shade", "bees"],
 ["Window haworthia", "Cacti & succulents", "a3c3a8", 0, 10, "shade", "bees"],
 ["Jade plant", "Cacti & succulents", "669669", 2, 18, "any", "bees"],
 ["Gollum jade", "Cacti & succulents", "799558", 1, 16, "any", "bees"],
 ["Black rose aeonium", "Cacti & succulents", "53333e", 1, 16, "sun", "bees"],
 ["Jelly bean sedum", "Cacti & succulents", "a38362", 0, 9, "sun", "bees"],
 ["Living stones", "Cacti & succulents", "aa806b", 0, 16, "sun", "bees"],
 ["Dwarf mondo grass", "Grasses", "426844", 0, 7, "shade", "birds"],
 ["Black mondo grass", "Grasses", "403c48", 0, 7, "shade", "birds"],
 ["Velvet zoysia", "Grasses", "81a658", 0, 7, "sun", "birds"],
 ["Buffalo grass", "Grasses", "97ac7a", 0, 7, "sun", "birds"],
 ["Creeping bentgrass", "Grasses", "72a35d", 0, 7, "any", "birds"],
 ["Creeping red fescue", "Grasses", "749269", 0, 7, "any", "birds"],
 ["Sheep's fescue", "Grasses", "889978", 0, 7, "sun", "birds"],
 ["Bearskin fescue", "Grasses", "76a149", 0, 7, "sun", "birds"],
 ["Blue moor grass", "Grasses", "82aaa4", 0, 7, "any", "birds"],
 ["Evergold sedge", "Grasses", "d5cd8b", 0, 7, "shade", "birds"],
 ["Snowline sedge", "Grasses", "cad7bd", 0, 7, "shade", "birds"],
 ["Dwarf golden sweet flag", "Grasses", "c2bb65", 0, 7, "water", "birds"],
 ["Cattleya orchid", "Flowers", "c477ca", 1, 14, "any", "bees"],
 ["Slipper orchid", "Flowers", "c5a452", 1, 14, "shade", "bees"],
 ["Dancing-lady orchid", "Flowers", "edc632", 1, 14, "any", "bees"],
 ["Pansy orchid", "Flowers", "dd90b8", 1, 14, "shade", "bees"],
 ["Blue Vanda orchid", "Flowers", "839acf", 1, 14, "any", "bees"],
 ["Zygopetalum orchid", "Flowers", "a99b53", 1, 14, "any", "bees"],
 ["Spider orchid", "Flowers", "bec37e", 1, 14, "any", "bees"],
 ["Australian rock orchid", "Flowers", "f3e5b0", 1, 14, "any", "bees"],
 ["Bee orchid", "Flowers", "ca8cbb", 1, 14, "sun", "bees"],
 ["Early purple orchid", "Flowers", "a448b5", 1, 14, "any", "bees"],
 ["Cornflower", "Flowers", "416cbd", 1, 8, "sun", "butterflies"],
 ["Corncockle", "Flowers", "c65ba4", 1, 8, "sun", "butterflies"],
 ["Red campion", "Flowers", "d34b85", 1, 9, "any", "bees"],
 ["Ragged robin", "Flowers", "d981ac", 1, 9, "sun", "butterflies"],
 ["Meadow cranesbill", "Flowers", "7d81ca", 1, 11, "sun", "bees"],
 ["Field scabious", "Flowers", "b095cb", 1, 10, "sun", "butterflies"],
 ["Yarrow", "Flowers", "f0e9d3", 1, 10, "sun", "butterflies"],
 ["Purple coneflower", "Flowers", "c87aaa", 1, 12, "sun", "butterflies"],
 ["Black-eyed Susan", "Flowers", "ebba32", 1, 9, "sun", "butterflies"],
 ["Blanket flower", "Flowers", "c7543b", 1, 9, "sun", "butterflies"],
 ["Flannel flower", "Flowers", "eeeadd", 1, 11, "sun", "bees"],
 ["Strawflower", "Flowers", "dfa047", 1, 8, "sun", "butterflies"],
 ["Australian blue pincushion", "Flowers", "798bc8", 1, 9, "sun", "butterflies"],
 ["Chocolate lily", "Flowers", "a882bb", 1, 10, "any", "bees"],
 ["Fringed lily", "Flowers", "b574bc", 1, 10, "sun", "bees"],
 ["Daffodil", "Flowers", "ead04d", 1, 7, "any", "bees"],
 ["Snowdrop", "Flowers", "f4f2e8", 1, 6, "shade", "bees"],
 ["Crocus", "Flowers", "9274bd", 1, 6, "sun", "bees"],
 ["Hyacinth", "Flowers", "a989cb", 1, 7, "any", "bees"],
 ["English bluebell", "Flowers", "6a72b7", 1, 8, "shade", "bees"],
 ["Giant ornamental allium", "Flowers", "a577c3", 1, 11, "sun", "bees"],
 ["Lily of the valley", "Flowers", "f0eee5", 1, 8, "shade", "bees"],
 ["Ranunculus", "Flowers", "e8a5a8", 1, 9, "sun", "bees"],
 ["Windflower", "Flowers", "c05671", 1, 8, "sun", "bees"],
 ["Snapdragon", "Flowers", "d76a90", 1, 9, "sun", "bees"],
 ["Sweet William", "Flowers", "bc4e73", 1, 9, "sun", "butterflies"],
 ["Stock", "Flowers", "c098c5", 1, 9, "sun", "bees"],
 ["Love-in-a-mist", "Flowers", "92b0d0", 1, 8, "sun", "bees"],
 ["Calendula", "Flowers", "de9134", 1, 7, "sun", "bees"],
 ["Zinnia", "Flowers", "dc6687", 1, 8, "sun", "butterflies"],
 ["Columbine", "Flowers", "8b75b1", 1, 11, "any", "bees"],
 ["Bleeding heart", "Flowers", "d581a4", 1, 11, "shade", "butterflies"],
 ["Hellebore", "Flowers", "ae829a", 1, 12, "shade", "bees"],
 ["Astilbe", "Flowers", "c990b5", 1, 11, "shade", "bees"],
 ["Penstemon", "Flowers", "eee1e2", 1, 11, "sun", "bees"],
 ["Tall garden phlox", "Flowers", "c485b3", 1, 12, "sun", "butterflies"],
 ["Canterbury bells", "Flowers", "9786c1", 1, 10, "any", "bees"],
 ["Oriental lily", "Flowers", "d58ca3", 1, 11, "sun", "butterflies"],
 ["Sweet violet", "Flowers", "9472b6", 1, 8, "shade", "bees"],
 ["Lady's mantle", "Flowers", "c4c768", 1, 10, "any", "bees"],
 ["Tropical hibiscus", "Shrubs", "dd735f", 2, 18, "sun", "butterflies"],
 ["Daphne", "Shrubs", "d7a9b9", 2, 18, "any", "butterflies"],
 ["Japanese pieris", "Shrubs", "eee8dc", 2, 20, "shade", "bees"],
 ["Snowball viburnum", "Shrubs", "eee9d7", 2, 20, "any", "bees"],
 ["Mock orange", "Shrubs", "f2ead6", 2, 20, "sun", "bees"],
 ["Weigela", "Shrubs", "d17f9b", 2, 18, "sun", "bees"],
 ["Deutzia", "Shrubs", "f1ecdf", 2, 16, "any", "bees"],
 ["Forsythia", "Shrubs", "e8c34b", 2, 18, "sun", "bees"],
 ["Flowering quince", "Shrubs", "cb6b6b", 2, 20, "sun", "bees"],
 ["Spirea", "Shrubs", "eee9df", 2, 18, "sun", "bees"],
 ["Abelia", "Shrubs", "dfb6bd", 2, 17, "sun", "butterflies"],
 ["Escallonia", "Shrubs", "c76a8e", 2, 18, "sun", "bees"],
 ["Hebe", "Shrubs", "b178ab", 2, 16, "sun", "butterflies"],
 ["Ceanothus", "Shrubs", "688abf", 2, 19, "sun", "bees"],
 ["Hardy fuchsia", "Shrubs", "c96d95", 2, 17, "any", "bees"],
 ["Mexican orange blossom", "Shrubs", "f0ead9", 2, 18, "any", "bees"],
 ["Correa", "Natives", "be7b70", 2, 16, "any", "native birds"],
 ["Pink boronia", "Natives", "d594b8", 2, 17, "any", "bees"],
 ["Flowering tea-tree", "Natives", "e0afb8", 2, 18, "sun", "bees"],
 ["Spotted emu bush", "Natives", "bd715d", 2, 17, "sun", "native birds"]
]

# Ideal watered growing days, not calendar deadlines. Twelve days form a season.
const GROWTH_DAYS=[4,7,3,6,8,10,12,4,7,5,10,4,5,6,5,8,6,9,5,4,14,12,10,16,15,10,14,12,24,20,24,28,18,26,20,22,8,5,18,16,12,20,16,9,7,28,5,9,3,12,6,2,5,10,3,9,7,10,5,12,10,10,10,12,7,10,10,12,18,18,20,20,18,14,14,16,14,14,36,32,28,28,24,24,22,24,22,22,24,22,22,28,28,26,28,18,20,14,12,14,9,10,10,12,8,12,14,12,14,9,10,14,11,9,9,12,18,14,18,22,20,12,16,12,10,10,9,14,22,10,10,18,16,16,9,16,7,7,7,7,7,7,7,7,7,7,7,7,14,14,14,14,14,14,14,14,14,14,8,8,9,9,11,10,10,12,9,9,11,8,9,10,10,7,6,6,7,8,11,8,9,8,9,9,9,8,7,8,11,11,12,11,11,12,10,11,8,10,18,18,20,20,20,18,16,18,20,18,17,18,16,19,17,18,16,17,18,17]
const SEASONAL={0:["Spring","Summer"],3:["Summer"],4:["Spring","Summer"],6:["Spring"],7:["Spring","Summer"],8:["Spring"],9:["Spring"],11:["Spring","Summer"],21:["Spring"],23:["Autumn","Winter","Spring"],24:["Spring","Summer"],28:["Spring","Summer"],30:["Spring","Summer","Autumn"],33:["Spring","Summer"],35:["Spring","Summer","Autumn"],38:["Winter","Spring"],47:["Summer"],48:["Spring","Autumn","Winter"],49:["Summer","Autumn"],50:["Spring","Summer"],52:["Spring","Autumn"],53:["Summer"],54:["Spring","Summer"],55:["Summer"],56:["Summer"],57:["Summer"],58:["Spring","Autumn"],59:["Summer"],60:["Spring", "Summer"],61:["Spring"],62:["Winter", "Spring"],63:["Summer", "Autumn"],64:["Spring"],65:["Spring", "Summer"],66:["Spring", "Summer"],67:["Summer"],73:["Spring", "Summer", "Autumn"],74:["Spring", "Summer", "Autumn"],75:["Spring", "Summer", "Autumn"],76:["Spring", "Summer", "Autumn"],77:["Spring", "Summer", "Autumn"],82:["Summer", "Autumn"],83:["Summer", "Autumn"],84:["Summer"],85:["Summer"],86:["Summer"],87:["Summer"],94:["Summer"],95:["Spring"],96:["Spring", "Summer"],97:["Spring", "Summer"],98:["Spring", "Summer"],99:["Spring"],100:["Spring", "Autumn", "Winter"],101:["Spring", "Autumn", "Winter"],102:["Summer"],103:["Autumn", "Winter"],104:["Spring", "Autumn", "Winter"],105:["Spring", "Summer"],106:["Spring","Summer","Autumn"],107:["Spring","Summer","Autumn"],108:["Spring","Summer","Autumn"],110:["Spring","Summer","Autumn"],111:["Spring","Summer","Autumn"],113:["Spring","Summer","Autumn"],115:["Spring","Summer","Autumn"],116:["Spring","Summer","Autumn"],117:["Spring","Summer","Autumn"],118:["Spring","Summer","Autumn"],119:["Spring","Summer","Autumn"],120:["Spring","Summer","Autumn"],121:["Spring","Summer","Autumn"],122:["Spring","Summer","Autumn"],124:["Spring","Summer","Autumn"],125:["Spring","Summer","Autumn"],127:["Spring","Summer","Autumn"],128:["Spring","Summer","Autumn"],129:["Spring","Summer","Autumn"],130:["Spring","Summer","Autumn"],131:["Spring","Summer","Autumn"],132:["Spring","Summer","Autumn"],134:["Spring","Summer","Autumn"],135:["Spring","Summer","Autumn"],123:["Autumn","Winter","Spring"],133:["Autumn","Winter","Spring"]}
const BOTANICAL_NAMES={106: "Miscanthus sinensis 'Zebrinus'", 107: "Calamagrostis × acutiflora 'Karl Foerster'", 108: "Panicum virgatum 'Heavy Metal'", 109: "Hakonechloa macra 'Aureola'", 110: "Imperata cylindrica 'Red Baron'", 111: "Molinia caerulea subsp. arundinacea 'Transparent'", 112: "Deschampsia cespitosa", 113: "Briza media", 114: "Sesleria autumnalis", 115: "Muhlenbergia capillaris", 116: "Echinocactus grusonii", 117: "Opuntia microdasys", 118: "Opuntia ficus-indica", 119: "Pachycereus marginatus", 120: "Cephalocereus senilis", 121: "Mammillaria elongata", 122: "Astrophytum asterias", 123: "Schlumbergera truncata", 124: "Echeveria elegans", 125: "Echeveria agavoides 'Lipstick'", 126: "Sempervivum tectorum", 127: "Aloe vera", 128: "Agave americana", 129: "Haworthiopsis attenuata", 130: "Haworthia cooperi", 131: "Crassula ovata", 132: "Crassula ovata 'Gollum'", 133: "Aeonium 'Zwartkop'", 134: "Sedum × rubrotinctum", 135: "Lithops aucampiae", 136: "Ophiopogon japonicus 'Nana'", 137: "Ophiopogon planiscapus 'Nigrescens'", 138: "Zoysia tenuifolia", 139: "Bouteloua dactyloides", 140: "Agrostis stolonifera", 141: "Festuca rubra", 142: "Festuca ovina", 143: "Festuca gautieri", 144: "Sesleria caerulea", 145: "Carex oshimensis 'Evergold'", 146: "Carex conica 'Snowline'", 147: "Acorus gramineus 'Minimus Aureus'"}

const FLOWER_METADATA={
 "148": {
  "botanical_name": "Cattleya labiata",
  "collection_group": "Orchids",
  "attached_bloom": true
 },
 "149": {
  "botanical_name": "Paphiopedilum insigne",
  "collection_group": "Orchids",
  "attached_bloom": true
 },
 "150": {
  "botanical_name": "Oncidium sphacelatum",
  "collection_group": "Orchids",
  "attached_bloom": true
 },
 "151": {
  "botanical_name": "Miltoniopsis vexillaria",
  "collection_group": "Orchids",
  "attached_bloom": true
 },
 "152": {
  "botanical_name": "Vanda coerulea",
  "collection_group": "Orchids",
  "attached_bloom": true
 },
 "153": {
  "botanical_name": "Zygopetalum maculatum",
  "collection_group": "Orchids",
  "attached_bloom": true
 },
 "154": {
  "botanical_name": "Brassia verrucosa",
  "collection_group": "Orchids",
  "attached_bloom": true
 },
 "155": {
  "botanical_name": "Dendrobium speciosum",
  "collection_group": "Orchids",
  "attached_bloom": true
 },
 "156": {
  "botanical_name": "Ophrys apifera",
  "collection_group": "Orchids",
  "attached_bloom": true
 },
 "157": {
  "botanical_name": "Orchis mascula",
  "collection_group": "Orchids",
  "attached_bloom": true
 },
 "158": {
  "botanical_name": "Centaurea cyanus",
  "collection_group": "Wildflowers",
  "attached_bloom": true
 },
 "159": {
  "botanical_name": "Agrostemma githago",
  "collection_group": "Wildflowers",
  "attached_bloom": true
 },
 "160": {
  "botanical_name": "Silene dioica",
  "collection_group": "Wildflowers",
  "attached_bloom": true
 },
 "161": {
  "botanical_name": "Silene flos-cuculi",
  "collection_group": "Wildflowers",
  "attached_bloom": true
 },
 "162": {
  "botanical_name": "Geranium pratense",
  "collection_group": "Wildflowers",
  "attached_bloom": true
 },
 "163": {
  "botanical_name": "Knautia arvensis",
  "collection_group": "Wildflowers",
  "attached_bloom": true
 },
 "164": {
  "botanical_name": "Achillea millefolium",
  "collection_group": "Wildflowers",
  "attached_bloom": true
 },
 "165": {
  "botanical_name": "Echinacea purpurea",
  "collection_group": "Wildflowers",
  "attached_bloom": true
 },
 "166": {
  "botanical_name": "Rudbeckia hirta",
  "collection_group": "Wildflowers",
  "attached_bloom": true
 },
 "167": {
  "botanical_name": "Gaillardia aristata",
  "collection_group": "Wildflowers",
  "attached_bloom": true
 },
 "168": {
  "botanical_name": "Actinotus helianthi",
  "collection_group": "Wildflowers",
  "attached_bloom": true
 },
 "169": {
  "botanical_name": "Xerochrysum bracteatum",
  "collection_group": "Wildflowers",
  "attached_bloom": true
 },
 "170": {
  "botanical_name": "Brunonia australis",
  "collection_group": "Wildflowers",
  "attached_bloom": true
 },
 "171": {
  "botanical_name": "Arthropodium strictum",
  "collection_group": "Wildflowers",
  "attached_bloom": true
 },
 "172": {
  "botanical_name": "Thysanotus tuberosus",
  "collection_group": "Wildflowers",
  "attached_bloom": true
 },
 "173": {
  "botanical_name": "Narcissus pseudonarcissus",
  "collection_group": "Cottage flowers",
  "attached_bloom": true
 },
 "174": {
  "botanical_name": "Galanthus nivalis",
  "collection_group": "Cottage flowers",
  "attached_bloom": true
 },
 "175": {
  "botanical_name": "Crocus vernus 'Remembrance'",
  "collection_group": "Cottage flowers",
  "attached_bloom": true
 },
 "176": {
  "botanical_name": "Hyacinthus orientalis",
  "collection_group": "Cottage flowers",
  "attached_bloom": true
 },
 "177": {
  "botanical_name": "Hyacinthoides non-scripta",
  "collection_group": "Cottage flowers",
  "attached_bloom": true
 },
 "178": {
  "botanical_name": "Allium giganteum",
  "collection_group": "Cottage flowers",
  "attached_bloom": true
 },
 "179": {
  "botanical_name": "Convallaria majalis",
  "collection_group": "Cottage flowers",
  "attached_bloom": true
 },
 "180": {
  "botanical_name": "Ranunculus asiaticus (double garden form)",
  "collection_group": "Cottage flowers",
  "attached_bloom": true
 },
 "181": {
  "botanical_name": "Anemone coronaria",
  "collection_group": "Cottage flowers",
  "attached_bloom": true
 },
 "182": {
  "botanical_name": "Antirrhinum majus",
  "collection_group": "Cottage flowers",
  "attached_bloom": true
 },
 "183": {
  "botanical_name": "Dianthus barbatus",
  "collection_group": "Cottage flowers",
  "attached_bloom": true
 },
 "184": {
  "botanical_name": "Matthiola incana (single-flowered form)",
  "collection_group": "Cottage flowers",
  "attached_bloom": true
 },
 "185": {
  "botanical_name": "Nigella damascena",
  "collection_group": "Cottage flowers",
  "attached_bloom": true
 },
 "186": {
  "botanical_name": "Calendula officinalis",
  "collection_group": "Cottage flowers",
  "attached_bloom": true
 },
 "187": {
  "botanical_name": "Zinnia elegans (double garden form)",
  "collection_group": "Cottage flowers",
  "attached_bloom": true
 },
 "188": {
  "botanical_name": "Aquilegia vulgaris",
  "collection_group": "Cottage flowers",
  "attached_bloom": true
 },
 "189": {
  "botanical_name": "Lamprocapnos spectabilis",
  "collection_group": "Cottage flowers",
  "attached_bloom": true
 },
 "190": {
  "botanical_name": "Helleborus orientalis",
  "collection_group": "Cottage flowers",
  "attached_bloom": true
 },
 "191": {
  "botanical_name": "Astilbe chinensis",
  "collection_group": "Cottage flowers",
  "attached_bloom": true
 },
 "192": {
  "botanical_name": "Penstemon digitalis",
  "collection_group": "Cottage flowers",
  "attached_bloom": true
 },
 "193": {
  "botanical_name": "Phlox paniculata",
  "collection_group": "Cottage flowers",
  "attached_bloom": true
 },
 "194": {
  "botanical_name": "Campanula medium",
  "collection_group": "Cottage flowers",
  "attached_bloom": true
 },
 "195": {
  "botanical_name": "Lilium 'Star Gazer' (Oriental hybrid)",
  "collection_group": "Cottage flowers",
  "attached_bloom": true
 },
 "196": {
  "botanical_name": "Viola odorata",
  "collection_group": "Cottage flowers",
  "attached_bloom": true
 },
 "197": {
  "botanical_name": "Alchemilla mollis",
  "collection_group": "Cottage flowers",
  "attached_bloom": true
 },
 "198": {
  "botanical_name": "Hibiscus rosa-sinensis",
  "collection_group": "Flowering bushes",
  "attached_bloom": true
 },
 "199": {
  "botanical_name": "Daphne odora",
  "collection_group": "Flowering bushes",
  "attached_bloom": true
 },
 "200": {
  "botanical_name": "Pieris japonica",
  "collection_group": "Flowering bushes",
  "attached_bloom": true
 },
 "201": {
  "botanical_name": "Viburnum opulus 'Roseum'",
  "collection_group": "Flowering bushes",
  "attached_bloom": true
 },
 "202": {
  "botanical_name": "Philadelphus coronarius",
  "collection_group": "Flowering bushes",
  "attached_bloom": true
 },
 "203": {
  "botanical_name": "Weigela florida",
  "collection_group": "Flowering bushes",
  "attached_bloom": true
 },
 "204": {
  "botanical_name": "Deutzia gracilis",
  "collection_group": "Flowering bushes",
  "attached_bloom": true
 },
 "205": {
  "botanical_name": "Forsythia x intermedia",
  "collection_group": "Flowering bushes",
  "attached_bloom": true
 },
 "206": {
  "botanical_name": "Chaenomeles speciosa",
  "collection_group": "Flowering bushes",
  "attached_bloom": true
 },
 "207": {
  "botanical_name": "Spiraea x vanhouttei",
  "collection_group": "Flowering bushes",
  "attached_bloom": true
 },
 "208": {
  "botanical_name": "Abelia x grandiflora",
  "collection_group": "Flowering bushes",
  "attached_bloom": true
 },
 "209": {
  "botanical_name": "Escallonia rubra",
  "collection_group": "Flowering bushes",
  "attached_bloom": true
 },
 "210": {
  "botanical_name": "Veronica speciosa (syn. Hebe speciosa)",
  "collection_group": "Flowering bushes",
  "attached_bloom": true
 },
 "211": {
  "botanical_name": "Ceanothus thyrsiflorus",
  "collection_group": "Flowering bushes",
  "attached_bloom": true
 },
 "212": {
  "botanical_name": "Fuchsia magellanica",
  "collection_group": "Flowering bushes",
  "attached_bloom": true
 },
 "213": {
  "botanical_name": "Choisya ternata",
  "collection_group": "Flowering bushes",
  "attached_bloom": true
 },
 "214": {
  "botanical_name": "Correa reflexa",
  "collection_group": "Flowering bushes",
  "attached_bloom": true
 },
 "215": {
  "botanical_name": "Boronia pinnata",
  "collection_group": "Flowering bushes",
  "attached_bloom": true
 },
 "216": {
  "botanical_name": "Leptospermum scoparium",
  "collection_group": "Flowering bushes",
  "attached_bloom": true
 },
 "217": {
  "botanical_name": "Eremophila maculata",
  "collection_group": "Flowering bushes",
  "attached_bloom": true
 }
}

static func saved_age(id: int, age: float, version: int) -> float:
 return age/float(ROWS[id][4])*GROWTH_DAYS[id] if version==1 else age

static func growing_seasons(id: int) -> String:
 return ", ".join(SEASONAL[id]) if SEASONAL.has(id) else "All seasons"

static func plants() -> Array:
 var result: Array = []
 for i in range(ROWS.size()):
  var r = ROWS[i]
  result.append({"id": i, "name": r[0], "category": r[1], "color": Color(r[2]), "layer": r[3], "days": GROWTH_DAYS[i], "seasons": SEASONAL.get(i,[]), "condition": r[5], "animal": r[6], "capacity": [1, 2, 4, 7][r[3]], "price": 8 + r[3] * 12 + (i % 4) * 3, "value": 7 + r[3] * 5, "climber": r[0] in ["Sweet pea", "Clematis", "Pea", "Cucumber", "Common jasmine", "Pink jasmine"]})
  result.back()["botanical_name"]=BOTANICAL_NAMES.get(i,"")
  result.back()["height"]=GardenPlantProfiles.HEIGHTS[i]
  result.back()["collection_group"]={"Flowers":"Cottage flowers","Shrubs":"Flowering bushes","Grasses":"Grasses & groundcovers","Trees":"Trees","Natives":"Australian natives","Produce":"Fruit & vegetables","Cacti & succulents":"Cacti & succulents"}.get(r[1],"Cottage flowers")
  if i in [0,2,7]:result.back()["collection_group"]="Wildflowers"
  if FLOWER_METADATA.has(str(i)):
   for key in FLOWER_METADATA[str(i)]:result.back()[key]=FLOWER_METADATA[str(i)][key]
 return result

static func furnishings() -> Array:
 return [
  {"name":"Terracotta pot", "price":25, "kind":"pot", "hint":"One planting pocket for a compact flower, herb or succulent. E to manage."},
  {"name":"Garden bench", "price":45, "kind":"bench", "hint":"A quiet spot to watch the garden."},
  {"name":"Stone lantern", "price":55, "kind":"lantern", "hint":"A soft light after dusk."},
  {"name":"Climbing arbor", "price":65, "kind":"arbor", "hint":"Nearby climbing plants trail across its frame."},
  {"name":"Timber pergola", "price":100, "kind":"pergola", "hint":"A canopy for nearby climbing plants."},
  {"name":"Glass greenhouse", "price":120, "kind":"greenhouse", "hint":"Protects plants within 4 metres in any conditions."},
  {"name":"Lily pond", "price":75, "kind":"pond", "hint":"Attracts frogs and dragonflies. Stock fish in the shop."},
  {"name":"Bird bath", "price":40, "kind":"bath", "hint":"Draws visiting birds."},
  {"name":"Beehive", "price":65, "kind":"hive", "hint":"Daytime bees and +5% growth for produce within four metres."},
  {"name":"Path stone", "price":3, "kind":"stone", "hint":"One decorative limestone stone for a path or border."},
  {"name":"Custom garden sign", "price":15, "kind":"sign", "hint":"Your words and colours. Q/E to rotate; edit in the garden shed."},
  {"name":"Potting bench", "price":75, "kind":"potting_bench", "hint":"Prepare starter mix so new plants begin with 8% growth and full water."},
  {"name":"Compost bays", "price":55, "kind":"compost_bays", "hint":"Turn eight spare harvest items into four growth-boosting compost portions."},
  {"name":"Rain barrel", "price":60, "kind":"rain_barrel", "hint":"Stores rain for automatic morning watering of containers within four metres."},
  {"name":"Raised garden bed", "price":35, "kind":"raised_bed", "hint":"Six real planting pockets for flowers, herbs and vegetables."},
  {"name":"Trellis screen", "price":45, "kind":"trellis_screen", "hint":"Three lattice panels for nearby climbing plants."},
  {"name":"Hexagonal gazebo", "price":180, "kind":"gazebo", "hint":"A shingled shelter with built-in seats. Rest underneath."},
  {"name":"Arched garden bridge", "price":95, "kind":"arched_bridge", "hint":"A decorative low arch with shaped timber rails."},
  {"name":"Tiered fountain", "price":120, "kind":"fountain", "hint":"Two carved limestone bowls with slender water streams."},
  {"name":"Garden swing", "price":110, "kind":"garden_swing", "hint":"A suspended oak seat with a gentle sway."},
  {"name":"Insect hotel", "price":45, "kind":"insect_hotel", "hint":"Draws small visitors and slows care stress in flowers and produce within three metres."},
  {"name":"Worm farm", "price":70, "kind":"worm_farm", "hint":"Six spare produce items become castings that ease plant stress."},
  {"name":"Leaf mulch bin", "price":50, "kind":"mulch_bin", "hint":"Six spare harvest items become mulch that makes water last twice as long."},
  {"name":"Shade cloth canopy", "price":85, "kind":"shade_canopy", "hint":"Foldable shade creates a comfortable corner for shade-loving plants."},
  {"name":"Glass cold frame", "price":80, "kind":"cold_frame", "hint":"Shelters small plants so they grow gently outside their season."},
  {"name":"Bird feeding table", "price":55, "kind":"bird_feeder", "hint":"Three spare harvest items welcome two extra songbirds for three days."},
  {"name":"Wide succulent bowl", "price":30, "kind":"wide_bowl", "hint":"Two planting pockets for low foliage and little succulents."},
  {"name":"Large timber planter", "price":50, "kind":"large_planter", "hint":"A deeper pocket for a shrub or larger flower."},
  {"name":"Herb trough", "price":45, "kind":"herb_trough", "hint":"Three raised pockets for compact herbs and flowers."},
  {"name":"Hanging basket stand", "price":55, "kind":"hanging_basket", "hint":"An elevated basket for low flowers, strawberries and trailing foliage."},
  {"name":"Vertical pocket planter", "price":95, "kind":"vertical_planter", "hint":"Six elevated pockets form a living display on a freestanding timber wall."},
  {"name":"Orchard harvest table", "price":65, "kind":"harvest_table", "hint":"A slatted table with fruit crates. Move, rotate or pack it away."},
  {"name":"Glasshouse nursery shelf", "price":60, "kind":"nursery_shelf", "hint":"A level timber display bench with slender steel legs."},
  {"name":"Alpine wind chime", "price":45, "kind":"wind_chime", "hint":"A timber stand with gently swaying metal chimes."},
  {"name":"Tiered planting steps", "price":85, "kind":"tiered_planter", "hint":"Six planting pockets on three levels for a layered garden display."}
 ]

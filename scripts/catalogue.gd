class_name GardenCatalogue
extends RefCounted

const CATEGORIES = ["Flowers", "Grasses", "Shrubs", "Trees", "Natives", "Produce"]
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
 ["Slender weaver's bamboo", "Shrubs", "598747", 2, 4, "sun", "birds"],
 ["Golden bamboo", "Shrubs", "c4b55b", 2, 4, "sun", "birds"],
 ["Black bamboo", "Shrubs", "343831", 2, 4, "sun", "birds"],
 ["Himalayan blue bamboo", "Shrubs", "719b9e", 2, 4, "sun", "birds"],
 ["Red bamboo 'Jiuzhaigou'", "Shrubs", "b25342", 2, 4, "sun", "birds"],
 ["Rose 'Mister Lincoln'", "Shrubs", "ab2335", 2, 4, "sun", "bees"],
 ["Rose 'Iceberg'", "Shrubs", "fff9e8", 2, 4, "sun", "bees"],
 ["Rose 'Golden Celebration'", "Shrubs", "eeb638", 2, 4, "sun", "bees"],
 ["Rose 'Just Joey'", "Shrubs", "eaa071", 2, 4, "sun", "bees"],
 ["Rose 'Scentimental'", "Shrubs", "be3047", 2, 4, "sun", "bees"],
 ["Giant redwood", "Trees", "568455", 3, 5, "sun", "birds"],
 ["Coast redwood", "Trees", "447859", 3, 5, "sun", "birds"],
 ["Giant bamboo", "Trees", "799856", 3, 5, "sun", "birds"],
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
 ["Hemp", "Produce", "6d9345", 1, 3, "sun", "bees"]
]

# Ideal watered growing days, not calendar deadlines. Twelve days form a season.
const GROWTH_DAYS=[4,7,3,6,8,10,12,4,7,5,10,4,5,6,5,8,6,9,5,4,14,12,10,16,15,10,14,12,24,20,24,28,18,26,20,22,8,5,18,16,12,20,16,9,7,28,5,9,3,12,6,2,5,10,3,9,7,10,5,12,10,10,10,12,7,10,10,12,18,18,20,20,18,14,14,16,14,14,36,32,28,28,24,24,22,24,22,22,24,22,22,28,28,26,28,18,20,14,12,14,9,10,10,12,8,12]
const SEASONAL={0:["Spring","Summer"],3:["Summer"],4:["Spring","Summer"],6:["Spring"],7:["Spring","Summer"],8:["Spring"],9:["Spring"],11:["Spring","Summer"],21:["Spring"],23:["Autumn","Winter","Spring"],24:["Spring","Summer"],28:["Spring","Summer"],30:["Spring","Summer","Autumn"],33:["Spring","Summer"],35:["Spring","Summer","Autumn"],38:["Winter","Spring"],47:["Summer"],48:["Spring","Autumn","Winter"],49:["Summer","Autumn"],50:["Spring","Summer"],52:["Spring","Autumn"],53:["Summer"],54:["Spring","Summer"],55:["Summer"],56:["Summer"],57:["Summer"],58:["Spring","Autumn"],59:["Summer"],60:["Spring", "Summer"],61:["Spring"],62:["Winter", "Spring"],63:["Summer", "Autumn"],64:["Spring"],65:["Spring", "Summer"],66:["Spring", "Summer"],67:["Summer"],73:["Spring", "Summer", "Autumn"],74:["Spring", "Summer", "Autumn"],75:["Spring", "Summer", "Autumn"],76:["Spring", "Summer", "Autumn"],77:["Spring", "Summer", "Autumn"],82:["Summer", "Autumn"],83:["Summer", "Autumn"],84:["Summer"],85:["Summer"],86:["Summer"],87:["Summer"],94:["Summer"],95:["Spring"],96:["Spring", "Summer"],97:["Spring", "Summer"],98:["Spring", "Summer"],99:["Spring"],100:["Spring", "Autumn", "Winter"],101:["Spring", "Autumn", "Winter"],102:["Summer"],103:["Autumn", "Winter"],104:["Spring", "Autumn", "Winter"],105:["Spring", "Summer"]}

static func saved_age(id: int, age: float, version: int) -> float:
 return age/float(ROWS[id][4])*GROWTH_DAYS[id] if version==1 else age

static func growing_seasons(id: int) -> String:
 return ", ".join(SEASONAL[id]) if SEASONAL.has(id) else "All seasons"

static func plants() -> Array:
 var result: Array = []
 for i in range(ROWS.size()):
  var r = ROWS[i]
  result.append({"id": i, "name": r[0], "category": r[1], "color": Color(r[2]), "layer": r[3], "days": GROWTH_DAYS[i], "seasons": SEASONAL.get(i,[]), "condition": r[5], "animal": r[6], "capacity": [1, 2, 4, 7][r[3]], "price": 8 + r[3] * 12 + (i % 4) * 3, "value": 7 + r[3] * 5, "climber": r[0] in ["Sweet pea", "Clematis", "Pea", "Cucumber", "Common jasmine", "Pink jasmine"]})
 return result

static func furnishings() -> Array:
 return [
  {"name":"Terracotta pot", "price":25, "kind":"pot", "hint":"A little warmth for a path edge."},
  {"name":"Garden bench", "price":45, "kind":"bench", "hint":"A quiet spot to watch the garden."},
  {"name":"Stone lantern", "price":55, "kind":"lantern", "hint":"A soft light after dusk."},
  {"name":"Climbing arbor", "price":65, "kind":"arbor", "hint":"Nearby climbing plants trail across its frame."},
  {"name":"Timber pergola", "price":100, "kind":"pergola", "hint":"A canopy for nearby climbing plants."},
  {"name":"Glass greenhouse", "price":120, "kind":"greenhouse", "hint":"Protects plants within 4 metres in any conditions."},
  {"name":"Lily pond", "price":75, "kind":"pond", "hint":"Attracts frogs and dragonflies. Stock fish in the shop."},
  {"name":"Bird bath", "price":40, "kind":"bath", "hint":"Draws visiting birds."},
  {"name":"Beehive", "price":65, "kind":"hive", "hint":"A timber hive with its own bees visiting during daylight."},
  {"name":"Path stone", "price":3, "kind":"stone", "hint":"One decorative limestone stone for a path or border."},
  {"name":"Custom garden sign", "price":15, "kind":"sign", "hint":"Your words and colours. Q/E to rotate; edit in the garden shed."}
 ]

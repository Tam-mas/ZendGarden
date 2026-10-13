"""Append-only catalogue IDs and modelling briefs for the 2026 orchard/forest set.

Heights are authored garden-scale metres, not maximum wild heights. Pawpaw uses
the Australian name for papaya. Banana is a giant herb and dragonfruit a climbing
cactus; both are browsable with the fruit collection without pretending to have
woody trunks. Existing Peach (84) remains available alongside these 20 additions.
"""

# name, botanical name, architecture, height, leaf colour, harvest/flower colour
FRUIT = [
 ('Mango','Mangifera indica','mango',6.0,'476c38','dca149'),
 ('Banana','Musa acuminata','banana',4.2,'629449','d6bd58'),
 ('Pawpaw','Carica papaya','papaya',4.0,'5a873e','d9ac4a'),
 ('Dragonfruit','Selenicereus undatus','dragonfruit',2.4,'5f8754','c9497e'),
 ('Guava','Psidium guajava','guava',3.8,'68934d','bdc965'),
 ('Lychee','Litchi chinensis','lychee',5.2,'456e3a','bd5e57'),
 ('Longan','Dimocarpus longan','longan',5.5,'4e763d','b29762'),
 ('Jackfruit','Artocarpus heterophyllus','jackfruit',6.2,'3f6f40','92a250'),
 ('Starfruit','Averrhoa carambola','starfruit',4.0,'648b42','d5bf4e'),
 ('Pomegranate','Punica granatum','pomegranate',3.0,'688c45','ba594c'),
 ('Persimmon','Diospyros kaki','persimmon',4.2,'5c7e43','d98738'),
 ('Loquat','Eriobotrya japonica','loquat',4.4,'426c42','dca34d'),
 ('Mulberry','Morus nigra','mulberry',4.6,'698c47','623748'),
 ('Tamarillo','Solanum betaceum','tamarillo',2.8,'689449','b64c39'),
 ('Breadfruit','Artocarpus altilis','breadfruit',6.5,'497940','8fa858'),
 ('Grapefruit','Citrus × paradisi','grapefruit',4.5,'4d743a','dabb55'),
 ('Pomelo','Citrus maxima','pomelo',4.8,'567b3e','b8ba5c'),
 ('Kumquat','Citrus japonica','kumquat',2.5,'4e7840','de9438'),
 ('Yuzu','Citrus junos','yuzu',3.2,'557b44','d5bc4b'),
 ('Custard apple','Annona reticulata','custard',4.2,'6d914d','9ba26a'),
]
DRY = [
 ('Saguaro','Carnegiea gigantea','saguaro',5.0,'658a64','eee5c9'),
 ('Organ pipe cactus','Stenocereus thurberi','organpipe',2.8,'688860','e4d8c6'),
 ('Blue torch cactus','Pilosocereus pachycladus','bluetorch',2.2,'80a9a2','e8dcca'),
 ('Totem pole cactus','Lophocereus schottii var. monstrosus','totem',1.7,'819d7e','d9c5b0'),
 ("Bishop's cap",'Astrophytum myriostigma','bishop',.45,'9ba68d','e4c45f'),
 ('Fishhook barrel cactus','Ferocactus wislizeni','barrel',.8,'778b58','d59646'),
 ('Pincushion cactus','Mammillaria spinosissima','pincushion',.38,'839568','cb5f8d'),
 ('Rainbow hedgehog cactus','Echinocereus rigidissimus','rainbow',.35,'939a73','d274a2'),
 ('Fishbone cactus','Disocactus anguliger','fishbone',.65,'5f8c58','e8e1cd'),
 ("Rat's tail cactus",'Disocactus flagelliformis','rattail',.7,'6b895c','c56c8f'),
 ('Queen of the night','Epiphyllum oxypetalum','epiphyllum',1.25,'56834e','eee8d3'),
 ('Spiral aloe','Aloe polyphylla','spiral',.48,'8ea59a','d9825b'),
 ('Foxtail agave','Agave attenuata','foxtail',1.25,'97ad96','c6bd72'),
 ('Panda plant','Kalanchoe tomentosa','panda',.55,'aeb6a0','c8ae78'),
 ("Bear's paw",'Cotyledon tomentosa','bearpaw',.45,'a9b58a','cf9260'),
 ('String of pearls','Curio rowleyanus','pearls',.22,'83a978','ded9c1'),
 ("Burro's tail",'Sedum morganianum','burro',.35,'9bb8ab','c78088'),
 ('Paddle plant','Kalanchoe luciae','paddle',.6,'a9ae83','caba73'),
 ('Split rock','Pleiospilos nelii','splitrock',.13,'989d87','df9d54'),
 ('Tiger jaws','Faucaria tigrina','tiger',.16,'7a9779','dfbf48'),
]
FOREST = [
 ('Soft tree fern','Dicksonia antarctica','softfern',4.0,'527b42','91a968'),
 ('Lacy tree fern','Sphaeropteris cooperi','lacyfern',5.2,'66904d','9cb675'),
 ('Rough tree fern','Alsophila australis','roughfern',4.8,'557f49','91a966'),
 ('Silver tree fern','Alsophila dealbata','silverfern',4.5,'6b946a','b7c7a7'),
 ('Black tree fern','Sphaeropteris medullaris','blackfern',6.0,'4e7b3e','8aa266'),
 ('Golden chicken fern','Cibotium barometz','goldenfern',2.5,'708e47','bba367'),
 ('Alexandra palm','Archontophoenix alexandrae','kingpalm',9.0,'557b43','ad664f'),
 ('Bangalow palm','Archontophoenix cunninghamiana','bangalow',7.5,'547e46','a96451'),
 ('Ruffled fan palm','Licuala grandis','fanpalm',3.2,'6c8c43','b76542'),
 ('Fishtail palm','Caryota mitis','fishtail',5.5,'648443','9f674e'),
 ('Walking palm','Socratea exorrhiza','walkingpalm',8.0,'577c3e','bba169'),
 ('Moreton Bay fig','Ficus macrophylla','banyan',12.0,'507747','a28461'),
 ('Kapok tree','Ceiba pentandra','kapok',16.0,'6f934d','a89a71'),
 ('Queensland kauri','Agathis robusta','kauri',14.0,'50774a','9a936b'),
 ('Hoop pine','Araucaria cunninghamii','hooppine',13.0,'4a7551','9e906b'),
 ('Queensland maple','Flindersia brayleyana','qmaple',10.0,'577f46','b29968'),
 ('Black bean tree','Castanospermum australe','blackbean',8.0,'426f40','c69245'),
 ('Blue quandong','Elaeocarpus grandis','quandong',11.0,'63864c','779cac'),
 ('Candlenut','Aleurites moluccanus','candlenut',9.0,'8a9d71','b7a26a'),
 ('Red lauan','Shorea leprosula','lauan',18.0,'66884c','bc976b'),
]

PLANTS=[]
for group, rows in [('Fruit trees',FRUIT),('Cacti & succulents',DRY),('Rainforest & tree ferns',FOREST)]:
 for row in rows:
  name,botanical,form,height,leaf,color=row
  idx=218+len(PLANTS)
  dry=group=='Cacti & succulents'
  shade=group=='Rainforest & tree ferns' and ('fern' in form or 'palm' in form or form in ['fishtail','bangalow']) or form in ['fishbone','rattail','epiphyllum']
  PLANTS.append(dict(id=idx,name=name,botanical_name=botanical,form=form,height=height,leaf=leaf,color=color,
   group=group,category='Cacti & succulents' if dry else 'Trees',layer=(0 if height<.4 else 1 if height<1.3 else 2) if dry or form=='dragonfruit' else 3,
   days=12+round(height*3) if dry else 18+round(height*1.2),condition='shade' if shade else 'sun',
   animal='bees' if dry or group=='Fruit trees' else 'birds'))
BY_ID={p['id']:p for p in PLANTS}
IDS=tuple(BY_ID)

extends RefCounted

static func run(g, failures: Array) -> void:
 for old in g.planted:
  old.node.queue_free()
  old.marker.queue_free()
 g.planted.clear()
 g.selected_layer=0
 g.inventory={}
 g.orders=[{"person":"Test neighbour","plant":0,"count":2,"reward":24}]
 g.fulfilled=0
 g.upgrades.shears=0
 var plant=g.add_plant(0,Vector3(1.2,0,1.2),0,float(g.catalogue[0].days))
 g.mode="prune"
 g.hover_valid=true
 g.hover_cell=plant.pos
 g.action_cooldown=0
 g.perform_action()
 if int(g.inventory.get("0",0))!=1: failures.append("Pruning did not collect mature plant")
 var coins=g.coins
 g.fulfill_order(0)
 if g.coins!=coins or int(g.inventory.get("0",0))!=1: failures.append("Incomplete order consumed items or paid reward")
 g.action_cooldown=0
 g.perform_action()
 if int(g.inventory.get("0",0))!=1: failures.append("Pruning duplicated immature yield")
 plant.age=float(g.catalogue[0].days)
 g.mode="harvest"
 g.action_cooldown=0
 g.perform_action()
 if int(g.inventory.get("0",0))!=2: failures.append("Gathering did not share pruning inventory")
 g.fulfill_order(0)
 if g.coins!=coins+24 or int(g.inventory.get("0",0))!=0 or g.fulfilled!=1: failures.append("Order item consumption or reward incorrect")
 g.fulfill_order(0)
 if g.coins!=coins+24 or g.fulfilled!=1: failures.append("Order paid twice")
 var due=g.day+2
 g.replenish_orders()
 if not g.orders[0].get("pending",false): failures.append("Order replenished early")
 g.day=due
 g.replenish_orders()
 if g.orders[0].get("pending",false) or g.orders[0].plant not in g.unlocked_plants: failures.append("Order did not replenish with available seeds")
 g.orders=[{"person":"Test neighbour","plant":0,"count":2,"reward":24}]
 g.inventory={"0":3,"1":1}
 g.sell_harvest()
 if int(g.inventory["0"])!=2 or int(g.inventory["1"])!=0: failures.append("Selling did not reserve order items")
 var wild=g.wild_plants[1]
 g.wild_pruning.erase(wild.key)
 g.wild_collection.erase(wild.key)
 GardenCare.restore_wild(g)
 if not GardenCare.collect_wild(g,wild) or GardenCare.collect_wild(g,wild): failures.append("Border daily collection limit failed")
 g.save_game()
 var saved=JSON.parse_string(FileAccess.get_file_as_string(g.SAVE_PATH))
 for key in g.inventory:
  if int(saved.inventory.get(key,-1))!=int(g.inventory[key]): failures.append("Basket save count incorrect")
 if int(saved.orders[0].plant)!=0 or int(saved.orders[0].count)!=2 or int(saved.orders[0].reward)!=24 or int(saved.wild_collection.get(wild.key,-1))!=g.day: failures.append("Order/border save data incorrect")
 # Use JSON-parsed orders, whose numeric IDs are floats, just like a real reload.
 g.orders=saved.orders
 g.inventory=saved.inventory
 var before_delivery=g.coins
 g.fulfill_order(0)
 if g.coins!=before_delivery+24 or int(g.inventory.get("0",-1))!=0: failures.append("Reloaded Cosmos order could not use basket items")
 g.wild_collection=saved.wild_collection
 if GardenCare.collect_wild(g,wild): failures.append("Reload allowed repeated border collection")
 g.day+=1
 if not GardenCare.collect_wild(g,wild): failures.append("Border did not replenish next morning")
 if g.TRANSITION_SECONDS!=12.0: failures.append("Next morning transition is not half speed")
 var code=OS.get_environment("ZEND_TEST_CODE")
 if not code.is_empty():
  var before_code=g.coins
  if g.redeem_test_code("invalid") or not g.redeem_test_code(code) or g.coins!=before_code+1000: failures.append("Testing credit incorrect")
 g.add_object("stone",Vector3(-7,0,8),3)
 var stone=g.objects.back()
 if stone.node.get_child_count()==0: failures.append("Stone model missing")
 g.mode="remove"
 g.hover_cell=stone.pos
 g.hover_valid=true
 g.action_cooldown=0
 g.perform_action()
 if stone in g.objects: failures.append("Remove did not remove a shop stone")
 g.open_sidebar("Orders")
 await g.get_tree().process_frame
 await RenderingServer.frame_post_draw
 g.get_viewport().get_texture().get_image().save_png("/tmp/orders-review.png")
 print("ORDERS_RESULT: ",failures)

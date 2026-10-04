extends SceneTree
## Share byte-identical imported textures. Editable GLBs/images are never changed.
## Run after --editor --import and before export; .godot and shared_textures are
## disposable outputs. The next source import can safely rebuild any model.
const SHARED="res://assets/shared_textures/"
var seen_resources={}
var texture_cache={}
var shared_by_path={}
var used_files={}
var model_count=0
var texture_count=0
var source_bytes=0
var unique_bytes=0
var failed=false

func _initialize() -> void:
 PortableCompressedTexture2D.set_keep_all_compressed_buffers(true)
 DirAccess.make_dir_recursive_absolute(SHARED)
 var models=[]
 find_models("res://assets",models)
 models.sort()
 for source in models:
  var config=ConfigFile.new()
  if config.load(source+".import")!=OK:
   fail("Missing import metadata: "+source)
   break
  var path=str(config.get_value("remap","path",""))
  var scene=ResourceLoader.load(path,"PackedScene",ResourceLoader.CACHE_MODE_IGNORE)
  if not scene:
   fail("Cannot load imported scene: "+source)
   break
  seen_resources={}
  share_resource(scene)
  if failed:break
  # Keep native scene compression. Repacking nodes would risk owners and rigs;
  # only texture references inside the original SceneState are edited here.
  if ResourceSaver.save(scene,path,ResourceSaver.FLAG_COMPRESS)!=OK:
   fail("Cannot save imported scene: "+source)
   break
  model_count+=1
 if not failed:
  # Remove only this tool's obsolete hash-named outputs, never source artwork.
  for name in DirAccess.get_files_at(SHARED):
   if name.get_basename().length()==64 and name.get_extension() in ["res","ctex"] and not used_files.has(SHARED+name):
    DirAccess.remove_absolute(SHARED+name)
  var report={"models":model_count,"model_paths":models,"texture_references":texture_count,"shared_textures":shared_by_path.size(),"generated_files":used_files.size(),"texture_bytes_loaded":source_bytes,"unique_texture_bytes":unique_bytes}
  DirAccess.make_dir_recursive_absolute("res://build")
  var output=FileAccess.open("res://build/texture-sharing.json",FileAccess.WRITE)
  output.store_string(JSON.stringify(report," "))
  print("TEXTURE_SHARING_RESULT: ",JSON.stringify(report))
 quit(1 if failed else 0)

func find_models(path: String, output: Array) -> void:
 for name in DirAccess.get_files_at(path):
  if name.ends_with(".glb"):output.append(path+"/"+name)
 for name in DirAccess.get_directories_at(path):
  if name!="shared_textures":find_models(path+"/"+name,output)

func fail(message: String) -> void:
 failed=true
 push_error(message)

func digest(bytes: PackedByteArray, metadata: String="") -> String:
 var hash=HashingContext.new()
 hash.start(HashingContext.HASH_SHA256)
 hash.update(bytes)
 if not metadata.is_empty():hash.update(metadata.to_utf8_buffer())
 return hash.finish().hex_encode()

func shared_texture(texture: Texture2D) -> Texture2D:
 var id=texture.get_instance_id()
 if texture_cache.has(id):return texture_cache[id].shared
 var bytes: PackedByteArray
 var path: String
 var data_path=""
 if texture is PortableCompressedTexture2D:
  bytes=texture.get("_data")
  if bytes.is_empty():
   fail("Compressed texture buffer is unavailable")
   return texture
  # The override is separate from the encoded image header. Different sampling
  # sizes must remain separate even when their pixel buffers are identical.
  path=SHARED+digest(bytes,str(texture.size_override))+".res"
  if not used_files.has(path):
   if ResourceSaver.save(texture,path)!=OK:
    fail("Cannot save shared texture: "+path)
    return texture
 elif texture is CompressedTexture2D:
  bytes=FileAccess.get_file_as_bytes(texture.get_load_path())
  if bytes.is_empty():
   fail("Missing native texture data: "+texture.get_load_path())
   return texture
  data_path=SHARED+digest(bytes)+".ctex"
  path=SHARED+digest(bytes)+".res"
  if not used_files.has(path):
   var output=FileAccess.open(data_path,FileAccess.WRITE)
   if not output:
    fail("Cannot write shared texture: "+path)
    return texture
   output.store_buffer(bytes)
   output.close()
   var wrapper=CompressedTexture2D.new()
   if wrapper.load(data_path)!=OK or ResourceSaver.save(wrapper,path)!=OK:
    fail("Cannot wrap shared native texture: "+path)
    return texture
 else:return texture
 var shared=shared_by_path.get(path)
 if not shared:
  shared=ResourceLoader.load(path,"Texture2D",ResourceLoader.CACHE_MODE_REPLACE)
  shared_by_path[path]=shared
 if not shared or shared.get_size()!=texture.get_size():
  fail("Shared texture dimensions changed: "+path)
  return texture
 if shared is PortableCompressedTexture2D and shared.get("_data")!=bytes:
  fail("Shared texture encoding changed: "+path)
  return texture
 texture_count+=1
 source_bytes+=bytes.size()
 if not used_files.has(path):unique_bytes+=bytes.size()
 used_files[path]=true
 if not data_path.is_empty():used_files[data_path]=true
 # Retain references for the lifetime of this pass: object IDs can be reused
 # after a model is released, and must not refer to a different old texture.
 texture_cache[id]={"original":texture,"shared":shared}
 return shared

func share_resource(resource: Resource) -> void:
 if seen_resources.has(resource.get_instance_id()):return
 seen_resources[resource.get_instance_id()]=true
 for property in resource.get_property_list():
  if not property.usage & PROPERTY_USAGE_STORAGE:continue
  var value=resource.get(property.name)
  if value is Texture2D:
   resource.set(property.name,shared_texture(value))
  else:descend(value)

func descend(value: Variant) -> void:
 if value is Resource:share_resource(value)
 elif value is Array:
  for item in value:descend(item)
 elif value is Dictionary:
  for item in value.values():descend(item)

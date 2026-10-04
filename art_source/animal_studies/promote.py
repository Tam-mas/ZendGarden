"""Promote approved sculpts without rebuilding their geometry or coat.

Run sequentially in an isolated Blender process. The studies remain untouched;
game sources add grounded pet/settle/stretch actions and cat WebP maps.
"""
import bpy, json, math, subprocess, sys, hashlib, shutil
from pathlib import Path
from mathutils import Matrix, Vector, Quaternion

ROOT = Path(__file__).resolve().parents[2]
STUDIES = ROOT / 'art_source/animal_studies'
KIND = sys.argv[sys.argv.index('--') + 1]
CAT = KIND == 'cat'
FOLDER = ROOT / 'art_source/cat_study' if CAT else STUDIES / KIND
SOURCE = FOLDER / ('cat_study.blend' if CAT else KIND + '_review.blend')
PYTHON = '/Users/tam/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/bin/python3'
bpy.ops.wm.open_mainfile(filepath=str(SOURCE), load_ui=False, use_scripts=False)
scene = next(s for s in bpy.data.scenes if s.name.startswith('Zend'))
bpy.context.window.scene = scene
rig = next(o for o in scene.objects if o.type == 'ARMATURE')
rig.animation_data.action = None
rig.animation_data.use_nla = False
for track in rig.animation_data.nla_tracks:
    track.mute = True

conversions = []
if CAT:
    destination = FOLDER / 'textures/game'
    destination.mkdir(exist_ok=True)
    for image in list(bpy.data.images):
        if image.source != 'FILE' or not image.filepath:
            continue
        source = Path(bpy.path.abspath(image.filepath))
        if source.suffix.lower() != '.png':
            continue
        target = destination / (source.stem + '.webp')
        lossless = 'normal' in source.stem.lower() or image.channels == 4
        conversion = subprocess.check_output([PYTHON, str(STUDIES/'convert_map.py'), str(source), str(target), 'lossless' if lossless else 'lossy'], text=True)
        conversions.append(dict(file=target.name, **json.loads(conversion)))
        replacement = bpy.data.images.load(str(target), check_existing=True)
        replacement.colorspace_settings.name = image.colorspace_settings.name
        replacement.pack()
        image.user_remap(replacement)
    # Retract the entire open lid, rather than leaving a flattened visible flap.
    for track in rig.animation_data.nla_tracks:
        curves = track.strips[0].action.layers[0].strips[0].channelbags[0].fcurves
        for name in ['LidL', 'LidR']:
            path = 'pose.bones["'+name+'"].scale'
            y = next(c for c in curves if c.data_path == path and c.array_index == 1)
            values = [.005+.995*max(0,min(1,(float(k.co.y)-.025)/.975)) for k in y.keyframe_points]
            for curve in [c for c in curves if c.data_path == path]:
                for key, value in zip(curve.keyframe_points, values):
                    key.co.y = value
                    key.interpolation = 'LINEAR'
                curve.update()

def reset():
    for pb in rig.pose.bones:
        pb.matrix_basis = Matrix.Identity(4)
        pb.rotation_mode = 'QUATERNION'
    for name in ['LidL', 'LidR']:
        rig.pose.bones[name].scale = Vector((.005,)*3)

def rotate(name, axis, angle):
    bone = rig.data.bones[name]
    rig.pose.bones[name].rotation_quaternion = Quaternion(bone.matrix_local.to_3x3().inverted() @ Vector(axis), angle)

if KIND in ['cat', 'dog']:
    # Recreate temporary ground-contact IK; bake evaluated transforms to FK.
    targets, constraints = {}, []
    for name in ['FrontL','FrontR','BackL','BackR']:
        paw = rig.data.bones[name+'_Paw']
        target = bpy.data.objects.new(name+' interaction contact', None)
        scene.collection.objects.link(target)
        target.location = paw.head_local
        target.rotation_mode = 'QUATERNION'
        target.rotation_quaternion = paw.matrix_local.to_quaternion()
        targets[name] = target
        lower = rig.pose.bones[name+'_Lower']
        ik = lower.constraints.new('IK')
        ik.target = target
        ik.chain_count = 2
        ik.use_stretch = False
        constraints.append((lower, ik))
        foot = rig.pose.bones[name+'_Paw']
        flat = foot.constraints.new('COPY_ROTATION')
        flat.target = target
        flat.owner_space = 'WORLD'
        flat.target_space = 'WORLD'
        constraints.append((foot, flat))
        for suffix in ['_Upper','_Lower']:
            rig.pose.bones[name+suffix].ik_stretch = 0
    order = sorted(rig.data.bones, key=lambda b:len(b.parent_recursive))
    samples = {}
    durations = {'pet':3.5, 'settle':8.0}
    if CAT: durations['stretch'] = 6.0
    for clip, duration in durations.items():
        stored = []
        for frame in range(round(duration*30)+1):
            reset()
            p = frame/(duration*30)
            wave = math.sin(p*math.tau)
            envelope = math.sin(math.pi*p)**2
            for name, target in targets.items():
                target.location = rig.data.bones[name+'_Paw'].head_local
            rig.pose.bones['Spine'].scale.x = 1+.006*math.sin(p*math.tau*2)
            if clip == 'settle':
                # A relaxed low stance, keeping all four paws on the ground.
                rig.pose.bones['Root'].location.y = -.025 if CAT else -.045
                rotate('Head', (1,0,0), .035+.025*wave)
                rotate('EarL', (0,1,0), -.035)
                rotate('EarR', (0,1,0), .035)
            elif clip == 'pet':
                rotate('Head', (0,0,1), (.11 if CAT else .09)*wave*envelope)
                rotate('Chest', (0,1,0), .025*wave*envelope)
                rotate('EarL', (1,0,0), -.08*envelope)
                rotate('EarR', (1,0,0), -.06*envelope)
            else:
                rig.pose.bones['Root'].location.y = -.025*envelope
                rotate('Spine', (1,0,0), -.045*envelope)
                rotate('Chest', (1,0,0), -.06*envelope)
                rotate('Head', (1,0,0), .10*envelope)
                for name, target in targets.items():
                    if name.startswith('Front'): target.location.y -= .028*envelope
            for index in range(1,4):
                rotate('Tail'+str(index), (0,0,1), (.10 if CAT else .24)*math.sin(p*math.tau*(1 if CAT else 3)+index*.4))
            blink = max(math.exp(-((p-at)/.016)**4) for at in [.34,.77])
            for name in ['LidL','LidR']:
                rig.pose.bones[name].scale = Vector((.005+.995*blink,)*3)
            bpy.context.view_layer.update()
            evaluated = rig.evaluated_get(bpy.context.evaluated_depsgraph_get())
            matrices = {b.name:evaluated.pose.bones[b.name].matrix.copy() for b in order}
            basis = {}
            for bone in order:
                relative = matrices[bone.parent.name].inverted()@matrices[bone.name] if bone.parent else matrices[bone.name]
                rest = bone.parent.matrix_local.inverted()@bone.matrix_local if bone.parent else bone.matrix_local
                basis[bone.name] = (rest.inverted()@relative).decompose()
            stored.append(basis)
        samples[clip] = stored
    for pb, constraint in constraints: pb.constraints.remove(constraint)
    for target in targets.values(): bpy.data.objects.remove(target, do_unlink=True)
    for clip, stored in samples.items():
        rig.animation_data.action = None
        for frame, basis in enumerate(stored, 1):
            for name, (location, rotation, scale) in basis.items():
                pb = rig.pose.bones[name]
                pb.location, pb.rotation_quaternion, pb.scale = location, rotation, scale
                for prop in ['location','rotation_quaternion','scale']: pb.keyframe_insert(prop, frame=frame)
        action = rig.animation_data.action
        action.name = KIND+'_game_'+clip
        track = rig.animation_data.nla_tracks.new()
        track.name = clip
        strip = track.strips.new(clip, 1, action)
        strip.extrapolation = 'NOTHING'
        track.mute = True
        rig.animation_data.action = None

reset()
scene.frame_set(0)
rig['stl_animal'] = KIND
bpy.ops.object.select_all(action='DESELECT')
rig.select_set(True)
bpy.context.view_layer.objects.active = rig
for ob in rig.children_recursive: ob.select_set(True)
rig.animation_data.use_nla = True
for track in rig.animation_data.nla_tracks:
    track.mute = False
    track.strips[0].influence = 1
rig.rotation_euler.z = math.pi
folder = 'companions' if KIND in ['cat','dog'] else 'wildlife'
destination = ROOT/'assets'/folder/(KIND+'.glb')
canonical = FOLDER/'export'/(KIND+'_game.glb')
bpy.ops.export_scene.gltf(filepath=str(destination), export_format='GLB', use_selection=True, use_active_scene=True,
    export_yup=True, export_apply=False, export_animations=True, export_extras=True,
    export_animation_mode='NLA_TRACKS', export_merge_animation='NLA_TRACK', export_nla_strips=True,
    export_image_format='WEBP', export_image_webp_fallback=False, export_image_quality=95)
shutil.copyfile(destination,canonical)
rig.rotation_euler.z = 0
rig.animation_data.use_nla = False
for track in rig.animation_data.nla_tracks: track.mute = True
reset()
scene.frame_set(0)
# A compact production source; untouched studies retain the original dense STL.
for ob in list(scene.objects):
    if ob.name.startswith('SOURCE —'): bpy.data.objects.remove(ob, do_unlink=True)
bpy.ops.wm.save_as_mainfile(filepath=str(FOLDER/(KIND+'_game.blend')), compress=True)
report = {'animal':KIND, 'source':str(SOURCE.relative_to(ROOT)), 'production_asset':str(destination.relative_to(ROOT)),
    'canonical_export':str(canonical.relative_to(ROOT)),
    'game_source':str((FOLDER/(KIND+'_game.blend')).relative_to(ROOT)), 'sha256':hashlib.sha256(destination.read_bytes()).hexdigest(),
    'bytes':destination.stat().st_size, 'clips':[t.name for t in rig.animation_data.nla_tracks], 'texture_conversions':conversions}
(FOLDER/'promotion.json').write_text(json.dumps(report,indent=2)+'\n')
print('ANIMAL_PROMOTED: '+json.dumps(report), flush=True)

"""Run with Blender MCP (exec this file) or blender --background --python this file.
Original toy-box street-life kit; dimensions below use Godot's Y-up, -Z-forward.
Writes one vertex-colored mesh/material per GLB and a reviewable source .blend.
"""
import bpy
import math
import json
from pathlib import Path
from mathutils import Matrix

ROOT = Path(__file__).resolve().parents[1] if '__file__' in globals() else Path('/home/egron/source/bikegame')
OUT = ROOT / 'game/assets/models/street_life'
OUT.mkdir(parents=True, exist_ok=True)
# A separate scene preserves any open user scene.
scene = bpy.data.scenes.new('Street Life Kit')
bpy.context.window.scene = scene
mat = bpy.data.materials.new('StreetLife_SatinVertexColor')
mat.use_nodes = True
bsdf = mat.node_tree.nodes.get('Principled BSDF')
bsdf.inputs['Roughness'].default_value = .72
color_node = mat.node_tree.nodes.new('ShaderNodeVertexColor')
color_node.layer_name = 'Color'
mat.node_tree.links.new(color_node.outputs['Color'], bsdf.inputs['Base Color'])
parts = []
assets = []
stats = {}
DARK = '293c48'
CREAM = 'fff0d1'
GLASS = '365c70'

def rgba(h):
    rgb = [int(h[i:i+2],16)/255 for i in (0,2,4)]
    return tuple(v/12.92 if v < .04045 else ((v+.055)/1.055)**2.4 for v in rgb)+(1,)

def finish_part(o, name, at, size, color, rotation=0):
    o.name = name
    o.location = at
    o.scale = size
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    if rotation:
        o.rotation_euler.z = math.radians(rotation)
    col = o.data.color_attributes.new(name='Color', type='FLOAT_COLOR', domain='CORNER')
    for c in col.data:
        c.color = rgba(color)
    o.data.materials.clear()
    o.data.materials.append(mat)
    parts.append(o)
    return o

def box(name, at, size, color, rotation=0, bevel=.10):
    bpy.ops.mesh.primitive_cube_add(size=1)
    o = bpy.context.object
    o.scale = size
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    mod = o.modifiers.new('Molded edge', 'BEVEL')
    mod.width = min(min(size)*.22, bevel)
    mod.segments = 2
    bpy.ops.object.modifier_apply(modifier=mod.name)
    # Flat main faces and softly shaded bevels.
    for p in o.data.polygons:
        p.use_smooth = p.area < max(size)*min(size)*.15
    return finish_part(o,name,at,(1,1,1),color,rotation)

def oval(name, at, size, color, rotation=0):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=12, ring_count=8, radius=1)
    o = bpy.context.object
    for p in o.data.polygons:
        p.use_smooth = True
    return finish_part(o,name,at,tuple(v*.5 for v in size),color,rotation)

def wheel(at, radius=.34):
    for depth,r,c in [(.24,radius,DARK),(.255,radius*.55,CREAM),(.27,radius*.22,'71969e')]:
        bpy.ops.mesh.primitive_cylinder_add(vertices=12, radius=r, depth=depth)
        o=bpy.context.object
        o.rotation_euler.y=math.pi/2
        bpy.ops.object.transform_apply(location=False,rotation=True,scale=False)
        finish_part(o,'Wheel',at,(1,1,1),c)

def eyes(y,z,x=.13, scale=1):
    for side in [-1,1]:
        oval('Eye white',(side*x,y,z),(.13*scale,.17*scale,.065*scale),CREAM)
        oval('Pupil',(side*x,y,z-.032*scale),(.064*scale,.10*scale,.038*scale),DARK)

def export(name):
    bpy.ops.object.select_all(action='DESELECT')
    for o in parts: o.select_set(True)
    bpy.context.view_layer.objects.active=parts[0]
    bpy.ops.object.join()
    obj=bpy.context.object
    # Bake origin at the agent's ground plane, then convert to Blender Z-up.
    bpy.context.scene.cursor.location=(0,0,0)
    bpy.ops.object.origin_set(type='ORIGIN_CURSOR')
    bpy.ops.object.transform_apply(location=True,rotation=True,scale=True)
    obj.data.transform(Matrix(((1,0,0,0),(0,0,-1,0),(0,1,0,0),(0,0,0,1))))
    obj.name=name
    # Joining identical material slots can otherwise create multiple draw surfaces.
    obj.data.materials.clear()
    obj.data.materials.append(mat)
    for p in obj.data.polygons: p.material_index=0
    obj.data.calc_loop_triangles()
    stats[name]={'triangles':len(obj.data.loop_triangles),'materials':1}
    bpy.ops.export_scene.gltf(filepath=str(OUT/(name+'.glb')),export_format='GLB',use_selection=True,use_active_scene=True,export_cameras=False,export_lights=False)
    assets.append(obj)
    parts.clear()

def vehicle(kind, paint):
    length = {'bus':4.35,'truck':3.75,'pickup':3.6}.get(kind,3.2)
    half=length/2
    box('Chassis',(0,.51,0),(1.68,.46,length),paint)
    if kind=='bus':
        box('Bus cabin',(0,1.25,0),(1.62,1.20,length-.12),paint)
        box('Ivory roof',(0,1.89,0),(1.65,.17,length-.1),CREAM)
        box('Windshield',(0,1.43,-half+.045),(1.34,.63,.055),GLASS)
        box('Destination panel',(0,1.80,-half+.02),(.83,.17,.06),DARK)
        box('Route stripe',(0,1.80,-half-.018),(.48,.06,.015),CREAM)
        for s in [-1,1]:
            box('Cream belt',(s*.844,.85,0),(.025,.16,length-.3),CREAM)
            for z in [-1.25,-.4,.45,1.3]:
                box('Bus window',(s*.817,1.44,z),(.05,.60,.67),GLASS)
            box('Door seam',(s*.852,.79,-1.28),(.025,.72,.035),DARK)
    else:
        cab_z=-.48 if kind in ['pickup','truck'] else .12
        box('Cabin',(0,1.05,cab_z),(1.38,.85,1.36),paint)
        box('Cream roof',(0,1.49,cab_z+.06),(1.4,.13,1.15),CREAM if kind!='taxi' else paint)
        box('Windshield',(0,1.16,cab_z-.689),(1.15,.44,.045),GLASS)
        box('Rear window',(0,1.16,cab_z+.689),(1.12,.40,.045),GLASS)
        box('Bonnet',(0,.81,-half+.4),(1.59,.21,.72),paint)
        for s in [-1,1]:
            box('Side window',(s*.70,1.16,cab_z),(.04,.44,1.03),GLASS)
            box('Window pillar',(s*.73,1.16,cab_z+.12),(.045,.47,.065),paint)
            box('Handle',(s*.735,.86,cab_z+.32),(.055,.045,.19),CREAM)
            box('Mirror',(s*.84,1.01,cab_z-.50),(.18,.15,.20),paint)
        if kind=='pickup':
            box('Bed inset',(0,.77,1.04),(1.32,.08,1.18),DARK)
            for s in [-1,1]: box('Bed rail',(s*.74,.93,1.03),(.18,.38,1.39),paint)
            box('Tailgate',(0,.91,half-.10),(1.56,.36,.17),paint)
        if kind=='truck':
            box('Delivery box',(0,1.24,.93),(1.72,1.37,1.72),CREAM)
            for s in [-1,1]:
                box('Parcel badge',(s*.87,1.31,.84),(.035,.51,.62),paint)
                box('Badge ribbon',(s*.893,1.31,.84),(.025,.51,.09),CREAM)
            box('Rear door',(0,1.25,half+.004),(1.45,1.12,.03),'cad4cb')
            box('Door divide',(0,1.25,half+.025),(.035,1.06,.02),DARK)
        if kind=='taxi':
            box('Taxi sign',(0,1.65,.14),(.64,.23,.31),CREAM)
            for x in [-.19,0,.19]: box('Sign marks',(x,1.65,-.025),(.075,.12,.02),DARK)
            for s in [-1,1]:
                for i in range(7):
                    box('Checker',(s*.85,.68,-.68+i*.21),(.018,.12,.13),DARK if i%2==0 else CREAM,bevel=.005)
    for z in [-half-.025,half+.025]:
        box('Bumper',(0,.47,z),(1.47,.17,.11),CREAM)
        box('Plate',(0,.57,z*1.012),(.36,.13,.04),DARK)
    for x in [-.55,.55]:
        oval('Headlight',(x,.77,-half-.015),(.36,.27,.085),CREAM)
        box('Tail light',(x,.75,half+.025),(.24,.20,.06),'db655c')
    for x in [-.84,.84]:
        for z in [-half+.62,half-.62]: wheel((x,.34,z))
    export(kind)

for kind,paint in [('car','dc7062'),('taxi','f0bf51'),('bus','63a9a1'),('pickup','6e9ab9'),('truck','9a81b7')]:
    vehicle(kind,paint)

for index in range(4):
    skin=['dca477','915f45','efc39c','bd805c'][index]
    coat=['628cae','d97865','73a589','b585b4'][index]
    hair=['513b31','302d32','815334','60443a'][index]
    oval('Jacket',(0,.97,0),(.57,.70,.40),coat)
    box('Hem',(0,.69,0),(.47,.14,.34),coat)
    box('Zip',(0,.98,-.202),(.026,.39,.022),CREAM)
    oval('Head',(0,1.57,-.015),(.58,.62,.53),skin)
    oval('Hair cap',(0,1.79,.035),(.59,.26,.51),hair)
    oval('Fringe',(-.14,1.72,-.19),(.27,.17,.17),hair,-20)
    oval('Nose',(0,1.55,-.28),(.14,.14,.12),skin)
    eyes(1.63,-.26,.125,.72)
    box('Smile',(0,1.43,-.262),(.11,.024,.025),'9a554a')
    for s in [-1,1]:
        oval('Ear',(s*.286,1.58,0),(.12,.18,.13),skin)
        box('Trouser',(s*.145,.42,0),(.22,.59,.25),DARK)
        box('Sneaker',(s*.145,.13,-.07),(.25,.20,.40),CREAM)
        box('Sole',(s*.145,.048,-.075),(.26,.065,.41),coat)
        oval('Sleeve',(s*.35,1.0,0),(.23,.52,.27),coat,s*12)
        oval('Hand',(s*.40,.72,-.015),(.18,.22,.19),skin)
    if index==0:
        box('Cap brim',(0,1.82,-.23),(.63,.07,.38),coat)
        oval('Cap',(0,1.87,.01),(.61,.22,.54),coat)
    elif index==1:
        oval('Hair bun',(0,1.88,.14),(.34,.32,.32),hair)
        box('Scarf',(0,1.30,-.03),(.44,.13,.39),'eabd59')
        box('Scarf end',(.13,1.17,-.23),(.15,.28,.07),'eabd59',-12)
    elif index==2:
        box('Backpack',(0,1.0,.25),(.44,.49,.23),'deaf64')
        for s in [-1,1]: box('Strap',(s*.19,1.03,-.18),(.07,.46,.065),'deaf64')
    else:
        for s in [-1,1]: box('Glasses',(s*.13,1.63,-.296),(.21,.17,.04),DARK)
        box('Glasses bridge',(0,1.64,-.31),(.10,.03,.025),DARK)
    export('person_'+str(index))

for kind in ['dog','fox','horse','cow','pig','goose']:
    if kind=='goose':
        oval('Body',(0,.46,.07),(.48,.49,.76),CREAM)
        oval('Neck',(0,.83,-.20),(.19,.78,.22),CREAM)
        oval('Head',(0,1.18,-.27),(.31,.31,.35),CREAM)
        box('Bill',(0,1.13,-.48),(.20,.11,.28),'e9a14b')
        for s in [-1,1]:
            oval('Wing',(s*.23,.50,.13),(.09,.31,.49),'d8dccc')
            box('Webbed foot',(s*.12,.06,-.04),(.16,.10,.29),'e9a14b')
        eyes(1.22,-.409,.09,.42)
    else:
        big=kind in ['horse','cow']
        pig=kind=='pig'
        y=1.12 if big else .48
        width=1.0 if big else .55
        length=1.95 if big else (1.12 if pig else .92)
        coat={'dog':'b88758','fox':'d9814c','horse':'a26c4b','cow':'f0e6ce','pig':'e5a0a1'}[kind]
        oval('Body',(0,y,0),(width,.91 if big else .53,length),coat)
        hy=1.96 if kind=='horse' else (1.47 if big else .72)
        hz=-1.04 if big else -.53
        if kind=='horse': oval('Neck',(0,1.58,-.72),(.51,1.17,.57),coat,-8)
        oval('Head',(0,hy,hz),(.65 if big else .48,.70 if big else .49,.67 if big else .48),coat)
        muzzle='cb9790' if kind in ['cow','pig'] else CREAM
        oval('Muzzle',(0,hy-.12,hz-.31),(.56 if big else .36,.31 if big else .25,.42 if big else .30),muzzle)
        eyes(hy+.055,hz-.30,.19 if big else .13,1 if big else .67)
        for s in [-1,1]:
            if pig or kind=='cow':
                oval('Nostril',(s*(.13 if big else .08),hy-.13,hz-.51 if big else hz-.45),(.075,.05,.027),DARK)
            for z in [-length*.32,length*.32]:
                box('Leg',(s*width*.32,(y-.2)*.5,z),(.21 if big else .15,y-.2,.22 if big else .16),coat)
                box('Hoof' if big or pig else 'Paw',(s*width*.32,.09,z-.025),(.24 if big else .18,.17,.28 if big else .22),DARK if big or pig else CREAM)
            ear_size=(.23,.38,.17) if kind in ['fox','horse'] else (.30,.18,.21)
            if kind=='dog': ear_size=(.18,.46,.24)
            ey=hy+.30 if kind!='dog' else hy+.03
            oval('Ear',(s*(.29 if big else .23),ey,hz+.035),ear_size,coat if kind!='dog' else '79513e',s*-22)
            if kind in ['fox','pig']:
                oval('Inner ear',(s*.23,ey+.02,hz-.04),(.105,.18,.065),'efbbab',s*-22)
        if kind in ['dog','fox']:
            oval('Nose',(0,hy-.07,hz-.46),(.14,.11,.10),DARK)
            oval('Chest',(0,.56,-.32),(.38,.42,.27),CREAM)
            oval('Tail',(0,.63,.63),(.24,.27,.66),coat)
            oval('Tail tip',(0,.69,.91),(.20,.22,.29),CREAM if kind=='fox' else '79513e')
            if kind=='dog': box('Collar',(0,.71,-.36),(.46,.09,.36),'63a9a1')
        elif kind=='horse':
            for i in range(4): oval('Mane',(0,1.38+i*.19,-.51-i*.08),(.17,.30,.34),DARK)
            oval('Tail',(0,.95,1.05),(.23,.86,.27),DARK,-10)
            box('Blaze',(0,2.01,-1.372),(.12,.30,.035),CREAM)
        elif kind=='cow':
            for s in [-1,1]:
                oval('Patch',(s*.467,1.19,.25*s),(.10,.53,.67),DARK,s*16)
                oval('Horn',(s*.24,1.91,hz+.03),(.13,.36,.14),'dfbc7c',s*-20)
            oval('Tail',(0,.86,1.05),(.10,.68,.13),coat)
            oval('Tail tuft',(0,.56,1.08),(.17,.23,.17),DARK)
        else:
            # A chunky curled tail remains legible without a thin curve mesh.
            for i in range(6):
                a=i*math.pi/4
                oval('Tail curl',(.09*math.sin(a),.62+.09*math.cos(a),.62),(.08,.08,.09),'c97f86')
    export(kind)

# Arrange the source scene as an asset shelf, after exporting local transforms.
for i,obj in enumerate(assets): obj.location=((i%5)*4.5,(i//5)*4.8,0)
(OUT/'mesh_budget.json').write_text(json.dumps(stats,indent=2)+'\n')
source_dir = ROOT / 'art/street_life'
source_dir.mkdir(parents=True, exist_ok=True)
bpy.data.libraries.write(str(source_dir/'street_life.blend'), {scene}, fake_user=True, compress=True)
result={'output':str(OUT),'assets':stats}

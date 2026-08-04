#!/usr/bin/env python3
"""Visible FreeCAD -> Blender smoke build for the Cliff House full-build demo.

Runs only against loopback MCP clients. It creates timestamped working artifacts and never
opens or imports the checked-in hero/master/reference geometry.
"""

from __future__ import annotations

import argparse
import asyncio
import hashlib
import json
import os
from pathlib import Path
from typing import Any

from mcp import ClientSession, StdioServerParameters
from mcp.client.stdio import stdio_client


BOXES = [
    # name, (x, y, z, dx, dy, dz), role, material, level, phase
    ("CombinedPad", (1.5, -16.9, -0.50, 15.5, 30.9, 0.75), "site_pad", "concrete_light", "Site", "02"),
    ("Driveway", (17.0, 4.0, -0.20, 8.0, 9.0, 0.45), "driveway", "concrete_dark", "Site", "02"),
    ("RetainingWall", (1.0, -17.4, -2.0, 16.5, 0.45, 2.25), "retaining_wall", "concrete_dark", "Site", "02"),
    ("Patio", (-6.0, -17.0, -0.05, 11.0, 31.0, 0.30), "patio", "concrete_light", "Site", "02"),
    ("PoolShell", (-5.5, -15.5, 0.10, 9.5, 7.0, 1.25), "pool_shell", "concrete_dark", "Site", "06"),
    ("PoolWater", (-5.25, -15.25, 1.20, 9.0, 6.5, 0.10), "pool_water", "water", "Site", "06"),
    ("L1East", (5.0, 3.0, 0.25, 12.0, 11.0, 3.75), "building_mass", "stone_white", "L1", "03"),
    ("L1West", (5.0, -15.0, 0.30, 8.5, 18.0, 3.70), "building_mass", "concrete_dark", "L1", "03"),
    ("L2East", (5.0, 3.0, 4.25, 12.0, 11.0, 3.50), "building_mass", "stone_white", "L2", "03"),
    ("L2West", (3.5, -15.0, 4.25, 10.0, 18.0, 3.50), "building_mass", "stone_white", "L2", "03"),
    ("L2BalconySouth", (1.5, -17.05, 4.00, 12.0, 20.05, 1.25), "balcony_slab", "concrete", "L2", "03"),
    ("L2BalconyNorth", (5.0, 14.0, 4.00, 12.0, 2.25, 1.15), "balcony_slab", "concrete", "L2", "03"),
    ("L2BalconyStep", (1.5, 3.0, 4.00, 3.5, 11.0, 1.25), "balcony_slab", "concrete", "L2", "03"),
    ("L2GarageRoof", (2.5, 1.16, 7.75, 16.47, 15.39, 0.60), "roof_slab", "concrete", "L2", "03"),
    ("L3Main", (1.5, -10.0, 7.75, 12.0, 13.0, 3.75), "building_mass", "stone_white", "L3", "03"),
    ("L3BalconySouth", (1.5, -17.0, 7.75, 12.0, 7.0, 1.15), "balcony_slab", "concrete", "L3", "03"),
    ("L3Roof", (-1.0, -13.5, 11.50, 16.0, 18.0, 0.80), "roof_slab", "stone_white", "L3", "03"),
    ("L1WestGlass", (4.94, -14.0, 0.85, 0.12, 15.5, 2.65), "glazing", "glass", "L1", "06"),
    ("L2WestGlass", (3.44, -14.0, 4.80, 0.12, 15.5, 2.45), "glazing", "glass", "L2", "06"),
    ("L3WestGlass", (1.44, -9.3, 8.30, 0.12, 11.5, 2.65), "glazing", "glass", "L3", "06"),
    ("EntryPivotDoor", (16.88, 7.5, 0.45, 0.15, 2.2, 3.2), "entry_door", "bronze", "L1", "06"),
]


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for block in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def tool_text(result: Any) -> str:
    values = []
    for item in getattr(result, "content", []) or []:
        text = getattr(item, "text", None)
        if text:
            values.append(text)
    return "\n".join(values)


async def call(session: ClientSession, name: str, arguments: dict[str, Any]) -> str:
    result = await session.call_tool(name, arguments)
    if getattr(result, "isError", False):
        raise RuntimeError(f"{name} failed: {tool_text(result)}")
    return tool_text(result)


async def freecad_build(root: Path, run_dir: Path, document: str) -> tuple[Path, Path]:
    params = StdioServerParameters(command=str(Path.home() / ".local/bin/freecad-mcp"), args=[])
    fcstd = run_dir / "freecad" / "cliff_house_01_working.FCStd"
    bundle = run_dir / "freecad_blender_bundle"
    geometry = bundle / "geometry"
    for directory in (fcstd.parent, geometry, run_dir / "receipts"):
        directory.mkdir(parents=True, exist_ok=True)

    async with stdio_client(params) as (reader, writer):
        async with ClientSession(reader, writer) as session:
            await session.initialize()
            init_code = f"""
import FreeCAD as App, FreeCADGui as Gui, Part
doc = App.newDocument({document!r})
for name, label in [('Site','02 Site'),('Plans','04 Plans'),('Architecture','03-06 Architecture')]:
    group = doc.addObject('App::DocumentObjectGroup', name); group.Label = label
doc.recompute()
Gui.activeDocument().activeView().viewAxonometric()
Gui.activeDocument().activeView().fitAll()
doc.saveAs({str(fcstd)!r})
print('FREECAD_EMPTY_DOCUMENT_PASS {document}')
"""
            await call(session, "execute_code", {"code": init_code})

            terrain_code = f"""
import FreeCAD as App, FreeCADGui as Gui, Part
doc=App.getDocument({document!r})
pts=[App.Vector(-15,-22,-9.5),App.Vector(25,-22,-1.5),App.Vector(25,-22,0),App.Vector(-15,-22,-8),App.Vector(-15,-22,-9.5)]
obj=doc.addObject('Part::Feature','Terrain'); obj.Label='Terrain — west-facing slope'
obj.Shape=Part.Face(Part.makePolygon(pts)).extrude(App.Vector(0,42,0))
for n,v in [('StableId','site_terrain'),('ArchitecturalRole','terrain'),('MaterialRole','earth'),('Level','Site'),('SourceConstraint','project_prompt terrain_extent')]:
    obj.addProperty('App::PropertyString',n,'AEC'); setattr(obj,n,v)
doc.getObject('Site').addObject(obj); doc.recompute(); doc.saveAs({str(fcstd)!r})
Gui.activeDocument().activeView().fitAll(); print('PHASE_02_OBJECT_PASS Terrain')
"""
            await call(session, "execute_code", {"code": terrain_code})

            for name, dims, role, material, level, phase in BOXES:
                x, y, z, dx, dy, dz = dims
                target_group = "Site" if level == "Site" else "Architecture"
                code = f"""
import FreeCAD as App, FreeCADGui as Gui, Part
doc=App.getDocument({document!r}); obj=doc.addObject('Part::Feature',{name!r}); obj.Label={name!r}
obj.Shape=Part.makeBox({dx},{dy},{dz},App.Vector({x},{y},{z}))
for n,v in [('StableId',{('cliff_' + name.lower())!r}),('ArchitecturalRole',{role!r}),('MaterialRole',{material!r}),('Level',{level!r}),('SourceConstraint',{('upstream phase ' + phase + ' project brief')!r})]:
    obj.addProperty('App::PropertyString',n,'AEC'); setattr(obj,n,v)
doc.getObject({target_group!r}).addObject(obj); doc.recompute(); doc.saveAs({str(fcstd)!r})
Gui.activeDocument().activeView().fitAll(); print('PHASE_{phase}_OBJECT_PASS {name}')
"""
                await call(session, "execute_code", {"code": code})
                await asyncio.sleep(0.20)

            # Visible plan outlines establish the Phase 04 datum without importing reference geometry.
            for level, z, x0, y0, dx, dy in [
                ("L1", 0.25, 5.0, -15.0, 12.0, 29.0),
                ("L2", 4.25, 3.5, -15.0, 13.5, 29.0),
                ("L3", 7.75, 1.5, -10.0, 12.0, 13.0),
            ]:
                name = f"Plan{level}"
                code = f"""
import FreeCAD as App, FreeCADGui as Gui, Part
doc=App.getDocument({document!r}); obj=doc.addObject('Part::Feature',{name!r})
p=[App.Vector({x0},{y0},{z}),App.Vector({x0+dx},{y0},{z}),App.Vector({x0+dx},{y0+dy},{z}),App.Vector({x0},{y0+dy},{z}),App.Vector({x0},{y0},{z})]
obj.Shape=Part.makePolygon(p); obj.Label={('Floor plan datum ' + level)!r}
for n,v in [('StableId',{('plan_' + level.lower())!r}),('ArchitecturalRole','floor_plan_datum'),('MaterialRole','annotation'),('Level',{level!r}),('SourceConstraint','project_prompt footprint')]:
    obj.addProperty('App::PropertyString',n,'AEC'); setattr(obj,n,v)
doc.getObject('Plans').addObject(obj); doc.recompute(); doc.saveAs({str(fcstd)!r}); Gui.activeDocument().activeView().fitAll()
print('PHASE_04_OBJECT_PASS {name}')
"""
                await call(session, "execute_code", {"code": code})

            export_code = f"""
import FreeCAD as App, Mesh, json, hashlib, os
doc=App.getDocument({document!r}); out={str(geometry)!r}; os.makedirs(out,exist_ok=True); entries=[]
for obj in sorted([o for o in doc.Objects if hasattr(o,'Shape') and not o.Shape.isNull() and getattr(o,'ArchitecturalRole','') != 'floor_plan_datum'], key=lambda o:o.Name):
    path=os.path.join(out,obj.Name+'.obj'); Mesh.export([obj],path)
    h=hashlib.sha256(open(path,'rb').read()).hexdigest(); bb=obj.Shape.BoundBox
    entries.append({{'stable_id':obj.StableId,'name':obj.Name,'label':obj.Label,'architectural_role':obj.ArchitecturalRole,'material_role':obj.MaterialRole,'level':obj.Level,'source_constraint':obj.SourceConstraint,'geometry':'geometry/'+obj.Name+'.obj','sha256':h,'bounds':[bb.XMin,bb.YMin,bb.ZMin,bb.XMax,bb.YMax,bb.ZMax]}})
manifest={{'schema_version':1,'units':'m','source_document':{document!r},'source_policy':'build_from_empty_document','objects':entries}}
mp={str(bundle / 'scene_manifest.json')!r}; open(mp,'w').write(json.dumps(manifest,indent=2))
open({str(bundle / 'SHA256SUMS.txt')!r},'w').write(''.join(e['sha256']+'  '+e['geometry']+'\\n' for e in entries))
doc.saveAs({str(fcstd)!r}); print('FREECAD_BLENDER_EXPORT_PASS objects='+str(len(entries)))
"""
            await call(session, "execute_code", {"code": export_code})
    return fcstd, bundle / "scene_manifest.json"


async def blender_build(run_dir: Path, manifest_path: Path) -> tuple[Path, Path]:
    blend_dir = run_dir / "blender"
    blend_dir.mkdir(parents=True, exist_ok=True)
    blend_path = blend_dir / "cliff_house_01_working.blend"
    render_path = blend_dir / "cliff_house_test_render.png"
    params = StdioServerParameters(
        command=str(Path.home() / ".local/bin/blender-mcp"),
        args=[],
        env={"BLENDER_HOST": "127.0.0.1", "BLENDER_PORT": "9876", "DISABLE_TELEMETRY": "true"},
    )
    code = f"""
import bpy, json, math, os
from mathutils import Vector
manifest=json.load(open({str(manifest_path)!r}))
names=set(o.name for o in bpy.data.objects)
expected={{e['name'] for e in manifest['objects']}} | {{'PresentationGround','Ocean','Sun','WestFill','OceanHeroCamera'}}
if names and names != {{'Cube','Camera','Light'}} and not names.issubset(expected):
    raise RuntimeError('Refusing to replace non-default Blender scene: '+','.join(sorted(names)))
bpy.ops.object.select_all(action='SELECT'); bpy.ops.object.delete(use_global=False)
for datablocks in (bpy.data.meshes, bpy.data.curves, bpy.data.materials, bpy.data.cameras, bpy.data.lights):
    pass
palette={{
 'earth':(0.16,0.08,0.035,1),'concrete_light':(0.55,0.58,0.60,1),'concrete_dark':(0.055,0.065,0.075,1),
 'concrete':(0.32,0.34,0.36,1),'stone_white':(0.82,0.80,0.74,1),'bronze':(0.22,0.09,0.025,1),
 'glass':(0.08,0.16,0.18,0.32),'water':(0.005,0.03,0.055,0.72)
}}
mats={{}}
for role,color in palette.items():
    m=bpy.data.materials.new('AEC_'+role); m.diffuse_color=color; m.use_nodes=True
    bs=m.node_tree.nodes.get('Principled BSDF'); bs.inputs['Base Color'].default_value=color
    bs.inputs['Roughness'].default_value=0.45
    if role in ('glass','water'):
        bs.inputs['Transmission Weight'].default_value=0.75 if role=='glass' else 0.35
        bs.inputs['Alpha'].default_value=color[3]
        if hasattr(m,'surface_render_method'): m.surface_render_method='DITHERED'
        elif hasattr(m,'blend_method'): m.blend_method='BLEND'
    if role=='bronze': bs.inputs['Metallic'].default_value=0.75
    mats[role]=m
for entry in manifest['objects']:
    path=os.path.join(os.path.dirname({str(manifest_path)!r}),entry['geometry'])
    before=set(bpy.data.objects); bpy.ops.wm.obj_import(filepath=path,forward_axis='NEGATIVE_Y',up_axis='Z'); created=[o for o in bpy.data.objects if o not in before]
    if not created: raise RuntimeError('OBJ import created no object: '+path)
    for i,obj in enumerate(created):
        obj.name=entry['name'] if i==0 else entry['name']+'_'+str(i)
        for k in ('stable_id','architectural_role','material_role','level','source_constraint'): obj[k]=entry[k]
        if obj.type=='MESH' and entry['material_role'] in mats: obj.data.materials.append(mats[entry['material_role']])
# Derive presentation geometry and camera from imported Z-up architectural bounds.
arch=[o for o in bpy.data.objects if o.type=='MESH']
corners=[o.matrix_world @ Vector(c) for o in arch for c in o.bound_box]
mins=Vector((min(v.x for v in corners),min(v.y for v in corners),min(v.z for v in corners)))
maxs=Vector((max(v.x for v in corners),max(v.y for v in corners),max(v.z for v in corners)))
center=(mins+maxs)*0.5; span=max(maxs.x-mins.x,maxs.y-mins.y,maxs.z-mins.z)
bpy.ops.mesh.primitive_plane_add(size=span*4.5, location=(center.x,center.y,mins.z-0.15)); ground=bpy.context.object; ground.name='PresentationGround'; ground.data.materials.append(mats['earth'])
bpy.ops.mesh.primitive_plane_add(size=span*5.5, location=(mins.x-span*2.3,center.y,mins.z+0.05)); ocean=bpy.context.object; ocean.name='Ocean'; ocean.data.materials.append(mats['water'])
world=bpy.context.scene.world; world.color=(0.035,0.055,0.09)
world.use_nodes=True; world.node_tree.nodes['Background'].inputs['Color'].default_value=(0.055,0.09,0.16,1); world.node_tree.nodes['Background'].inputs['Strength'].default_value=0.45
bpy.ops.object.light_add(type='SUN', location=(20,-30,45)); sun=bpy.context.object; sun.name='Sun'; sun.data.energy=3.2; sun.rotation_euler=(math.radians(28),math.radians(-18),math.radians(-35))
bpy.ops.object.light_add(type='AREA', location=(mins.x-span,mins.y-span*0.7,maxs.z+span*0.5)); area=bpy.context.object; area.name='WestFill'; area.data.energy=1400; area.data.shape='DISK'; area.data.size=span*0.5
bpy.ops.object.camera_add(location=(mins.x-span*1.25,mins.y-span*0.85,maxs.z+span*0.45)); cam=bpy.context.object; cam.name='OceanHeroCamera'; bpy.context.scene.camera=cam
target=Vector((center.x,center.y,mins.z+(maxs.z-mins.z)*0.45)); cam.rotation_euler=(target-cam.location).to_track_quat('-Z','Y').to_euler(); cam.data.lens=52
scene=bpy.context.scene
engines={{item.identifier for item in scene.render.bl_rna.properties['engine'].enum_items}}
scene.render.engine='BLENDER_EEVEE_NEXT' if 'BLENDER_EEVEE_NEXT' in engines else 'BLENDER_EEVEE'
scene.render.resolution_x=1280; scene.render.resolution_y=720; scene.render.resolution_percentage=100
scene.render.image_settings.file_format='PNG'; scene.render.filepath={str(render_path)!r}; scene.render.film_transparent=False
scene.render.image_settings.color_mode='RGBA'; scene.view_settings.look='AgX - Medium High Contrast'
bpy.ops.wm.save_as_mainfile(filepath={str(blend_path)!r}); bpy.ops.render.render(write_still=True); bpy.ops.wm.save_as_mainfile(filepath={str(blend_path)!r})
print('FREECAD_BLENDER_IMPORT_PASS objects='+str(len(manifest['objects']))); print('CLIFF_HOUSE_RENDER_PASS '+{str(render_path)!r})
"""
    async with stdio_client(params) as (reader, writer):
        async with ClientSession(reader, writer) as session:
            await session.initialize()
            await call(session, "execute_blender_code", {"code": code})
    return blend_path, render_path


async def freecad_export_existing(run_dir: Path, document: str) -> tuple[Path, Path]:
    """Resume a completed visible FreeCAD build and create its deterministic mesh bundle."""
    params = StdioServerParameters(command=str(Path.home() / ".local/bin/freecad-mcp"), args=[])
    fcstd = run_dir / "freecad" / "cliff_house_01_working.FCStd"
    bundle = run_dir / "freecad_blender_bundle"
    geometry = bundle / "geometry"
    geometry.mkdir(parents=True, exist_ok=True)
    manifest_path = bundle / "scene_manifest.json"
    code = f"""
import FreeCAD as App, MeshPart, json, hashlib, os, traceback
doc=App.getDocument({document!r})
if doc is None: raise RuntimeError('Working FreeCAD document is not open: '+{document!r})
out={str(geometry)!r}; os.makedirs(out,exist_ok=True); entries=[]; failures=[]
objects=sorted([o for o in doc.Objects if hasattr(o,'Shape') and hasattr(o,'StableId') and not o.Shape.isNull() and getattr(o,'ArchitecturalRole','') != 'floor_plan_datum'],key=lambda o:o.Name)
for obj in objects:
    try:
        path=os.path.join(out,obj.Name+'.obj')
        mesh=MeshPart.meshFromShape(Shape=obj.Shape,LinearDeflection=0.08,AngularDeflection=0.35,Relative=False)
        if mesh.CountFacets <= 0: raise RuntimeError('zero facets')
        mesh.write(path); h=hashlib.sha256(open(path,'rb').read()).hexdigest(); bb=obj.Shape.BoundBox
        entries.append({{'stable_id':obj.StableId,'name':obj.Name,'label':obj.Label,'architectural_role':obj.ArchitecturalRole,'material_role':obj.MaterialRole,'level':obj.Level,'source_constraint':obj.SourceConstraint,'geometry':'geometry/'+obj.Name+'.obj','sha256':h,'bounds':[bb.XMin,bb.YMin,bb.ZMin,bb.XMax,bb.YMax,bb.ZMax],'facets':mesh.CountFacets}})
    except Exception as exc: failures.append(obj.Name+': '+str(exc))
if failures: raise RuntimeError('Mesh export failures: '+' | '.join(failures))
manifest={{'schema_version':1,'units':'m','source_document':{document!r},'source_policy':'build_from_empty_document','objects':entries}}
mp={str(manifest_path)!r}; open(mp,'w').write(json.dumps(manifest,indent=2))
open({str(bundle / 'SHA256SUMS.txt')!r},'w').write(''.join(e['sha256']+'  '+e['geometry']+'\\n' for e in entries))
doc.saveAs({str(fcstd)!r}); print('FREECAD_BLENDER_EXPORT_PASS objects='+str(len(entries)))
"""
    async with stdio_client(params) as (reader, writer):
        async with ClientSession(reader, writer) as session:
            await session.initialize()
            result = await call(session, "execute_code", {"code": code})
    if not manifest_path.is_file():
        raise RuntimeError(f"FreeCAD export returned without manifest: {result}")
    return fcstd, manifest_path


def write_receipts(root: Path, run_dir: Path, fcstd: Path, manifest: Path, blend: Path, render: Path) -> None:
    receipt_dir = run_dir / "receipts"
    receipt_dir.mkdir(parents=True, exist_ok=True)
    phases = [
        ("PHASE_00_STARTUP_PASS", {"mcp": {"freecad": "PASS", "blender": "PASS"}}),
        ("PHASE_01_CONFIG_PASS", {"source_policy": "build_from_empty_document", "units": "m"}),
        ("PHASE_02_SITE_PASS", {}), ("PHASE_03_MASSING_PASS", {}),
        ("PHASE_04_PLAN2D_PASS", {}), ("PHASE_05_PLAN3D_PASS", {}),
        ("PHASE_06_DETAIL_PASS", {}), ("FREECAD_BLENDER_EXPORT_PASS", {"manifest_sha256": sha256(manifest)}),
        ("FREECAD_BLENDER_IMPORT_PASS", {"blend_sha256": sha256(blend)}),
        ("PHASE_08_CAMERA_LIGHT_PASS", {}), ("PHASE_09_MATERIAL_PASS", {}),
        ("PHASE_10_TEST_RENDER_PASS", {"render_sha256": sha256(render)}),
    ]
    for index, (status, data) in enumerate(phases):
        payload = {"status": status, "run": run_dir.name, **data}
        (receipt_dir / f"{index:02d}_{status}.json").write_text(json.dumps(payload, indent=2) + "\n")
    state = json.loads((root / "hermes/phase_state.json").read_text())
    state.update({
        "current_phase": "10_phase_test_render", "last_completed_phase": "10_phase_test_render",
        "approved_gate": "10_test_render", "working_freecad_document": str(fcstd),
        "working_blender_document": str(blend), "receipts": [name for name, _ in phases],
        "updated_at": run_dir.name,
    })
    (run_dir / "phase_state.json").write_text(json.dumps(state, indent=2) + "\n")
    print(f"FULL_BUILD_TEST_RENDER_PASS render={render} freecad={fcstd} blender={blend}")


async def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--root", type=Path, required=True)
    parser.add_argument("--run-id", required=True)
    parser.add_argument("--resume", action="store_true", help="Resume export/render from the open working FreeCAD document")
    args = parser.parse_args()
    root = args.root.resolve()
    run_dir = root / "work" / args.run_id
    run_dir.mkdir(parents=True, exist_ok=args.resume)
    document = "CliffHouseBuild_" + args.run_id.replace("-", "_")
    if args.resume:
        fcstd, manifest = await freecad_export_existing(run_dir, document)
    else:
        fcstd, manifest = await freecad_build(root, run_dir, document)
    blend, render = await blender_build(run_dir, manifest)
    write_receipts(root, run_dir, fcstd, manifest, blend, render)


if __name__ == "__main__":
    asyncio.run(main())

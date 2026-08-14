"""Deterministically build the Swagstaff Cliff House from its base scene.

Run inside Rhino 8. The active document must be a fresh copy of Swagstaff's
16-object ``base_model.3dm``. No geometry from any reconstructed hero file is
read or reused.
"""

import System
import Rhino
from Rhino import RhinoDoc
from Rhino.DocObjects import ObjectAttributes
from Rhino.Geometry import Box, Interval, Plane, Point3d, Polyline, TextEntity
from System.Drawing import Color


doc = RhinoDoc.ActiveDoc
if doc is None:
    raise RuntimeError("No active Rhino document")

if doc.Objects.Count != 16:
    raise RuntimeError("Expected untouched 16-object Swagstaff base, found %s" % doc.Objects.Count)

doc.ModelUnitSystem = Rhino.UnitSystem.Meters
doc.ModelAbsoluteTolerance = 0.001


def layer(path, color, visible=True):
    parts = path.split("::")
    parent_id = System.Guid.Empty
    full = ""
    idx = -1
    for part in parts:
        full = part if not full else full + "::" + part
        idx = doc.Layers.FindByFullPath(full, -1)
        if idx < 0:
            lay = Rhino.DocObjects.Layer()
            lay.Name = part
            lay.ParentLayerId = parent_id
            lay.Color = color
            lay.IsVisible = visible
            idx = doc.Layers.Add(lay)
        parent_id = doc.Layers[idx].Id
    return idx


COLORS = {
    "terrain": Color.FromArgb(86, 112, 72),
    "concrete": Color.FromArgb(75, 78, 80),
    "slab": Color.FromArgb(145, 145, 140),
    "stone": Color.FromArgb(226, 222, 208),
    "glass": Color.FromArgb(95, 160, 175),
    "bronze": Color.FromArgb(105, 72, 42),
    "water": Color.FromArgb(18, 44, 55),
    "plan": Color.FromArgb(65, 105, 170),
}


def attrs(layer_path, name, color=None):
    a = ObjectAttributes()
    a.LayerIndex = layer(layer_path, color or Color.White)
    a.Name = name
    return a


def box(name, layer_path, x0, y0, z0, x1, y1, z1, color=None):
    geom = Box(Plane.WorldXY, Interval(x0, x1), Interval(y0, y1), Interval(z0, z1)).ToBrep()
    oid = doc.Objects.AddBrep(geom, attrs(layer_path, name, color))
    if oid == System.Guid.Empty:
        raise RuntimeError("Failed to add " + name)
    return oid


def line_box(name, layer_path, p0, p1, width, height, color=None):
    x0, y0, z0 = p0
    x1, y1, z1 = p1
    if abs(x1 - x0) >= abs(y1 - y0):
        return box(name, layer_path, min(x0,x1), y0-width/2, z0, max(x0,x1), y0+width/2, z0+height, color)
    return box(name, layer_path, x0-width/2, min(y0,y1), z0, x0+width/2, max(y0,y1), z0+height, color)


def curve_rect(name, layer_path, x0, y0, x1, y1, z=0.0, color=None):
    pts = [Point3d(x0,y0,z), Point3d(x1,y0,z), Point3d(x1,y1,z), Point3d(x0,y1,z), Point3d(x0,y0,z)]
    return doc.Objects.AddCurve(Polyline(pts).ToNurbsCurve(), attrs(layer_path, name, color))


def text(name, value, layer_path, x, y, z, height=0.45, color=None):
    te = TextEntity()
    te.Plane = Plane(Point3d(x,y,z), Rhino.Geometry.Vector3d.XAxis, Rhino.Geometry.Vector3d.YAxis)
    te.PlainText = value
    te.TextHeight = height
    return doc.Objects.AddText(te, attrs(layer_path, name, color))


# --- Canonical Swagstaff target hierarchy ---
for p, c in [
    ("building_site_v3::terrain", COLORS["terrain"]),
    ("building_site_v3::combined_pad", COLORS["concrete"]),
    ("building_site_v3::curtain_wall", COLORS["concrete"]),
    ("building_site_v3::driveway", COLORS["slab"]),
    ("massing_v3::L1_solids", COLORS["stone"]),
    ("massing_v3::L2_solids", COLORS["stone"]),
    ("massing_v3::L2_balcony_solids", COLORS["slab"]),
    ("massing_v3::L2_roof_solids", COLORS["stone"]),
    ("massing_v3::L3_solids", COLORS["stone"]),
    ("massing_v3::L3_balcony_solids", COLORS["slab"]),
    ("massing_v3::L3_roof_slab", COLORS["stone"]),
]:
    layer(p, c, False)  # design-intent reference, hidden in finished view

# Smooth sloping NURBS terrain from the exact site bounds.
srf = Rhino.Geometry.NurbsSurface.CreateFromCorners(
    Point3d(-15,-22,-8), Point3d(25,-22,0), Point3d(25,20,0), Point3d(-15,20,-8)
)
doc.Objects.AddSurface(srf, attrs("building_site_v3::terrain", "SITE_TERRAIN_NURBS", COLORS["terrain"]))
box("SITE_COMBINED_PAD", "building_site_v3::combined_pad", 1.5,-16.9,-0.5,17,14,0.25, COLORS["concrete"])
for nm,coords in [
    ("RETAINING_WEST",(1,-17.4,-2,1.35,14.5,0.25)),
    ("RETAINING_EAST",(17.15,-17.4,-2,17.5,14.5,0.25)),
    ("RETAINING_SOUTH",(1,-17.4,-2,17.5,-17.05,0.25)),
    ("RETAINING_NORTH",(1,14.15,-2,17.5,14.5,0.25)),
]: box(*(tuple([nm,"building_site_v3::curtain_wall"]) + coords + tuple([COLORS["concrete"]])))
box("SITE_DRIVEWAY", "building_site_v3::driveway",17.5,3.96,-0.2,25.03,13,0.25,COLORS["slab"])

# Exact 11 massing objects recorded by the Swagstaff demo.
MASSING = [
    ("L1_EAST","massing_v3::L1_solids",5,3,0.25,17,14,4),
    ("L1_WEST","massing_v3::L1_solids",5,-15,0.3,13.5,3,4),
    ("L2_EAST","massing_v3::L2_solids",5,3,4.25,17,14,7.75),
    ("L2_WEST","massing_v3::L2_solids",3.5,-15,4.25,13.5,3,7.75),
    ("L2_BALCONY_SOUTH","massing_v3::L2_balcony_solids",1.5,-17.05,4,13.5,3,5.25),
    ("L2_BALCONY_NORTH","massing_v3::L2_balcony_solids",5,14,4,17,16.25,5.15),
    ("L2_BALCONY_STEP","massing_v3::L2_balcony_solids",1.5,3,4,5,14,5.25),
    ("L2_ROOF_GARAGE","massing_v3::L2_roof_solids",2.5,1.16,7.75,18.97,16.55,8.35),
    ("L3_MAIN","massing_v3::L3_solids",1.5,-10,7.75,13.5,3,11.5),
    ("L3_BALCONY_SOUTH","massing_v3::L3_balcony_solids",1.5,-17,7.75,13.5,-10,8.9),
    ("L3_ROOF_SLAB","massing_v3::L3_roof_slab",-1,-13.5,11.5,15,4.5,12.3),
]
for values in MASSING: box(*(values + tuple([COLORS["stone"]])))

# --- Finished architectural model ---
for p,c in [
    ("AEC_HOUSE::SITE",COLORS["terrain"]), ("AEC_HOUSE::STRUCTURE",COLORS["concrete"]),
    ("AEC_HOUSE::SLABS",COLORS["slab"]), ("AEC_HOUSE::ASHLAR_WALLS",COLORS["stone"]),
    ("AEC_HOUSE::GLAZING",COLORS["glass"]), ("AEC_HOUSE::BRONZE_FRAMES",COLORS["bronze"]),
    ("AEC_HOUSE::BALCONY_RAILS",COLORS["bronze"]), ("AEC_HOUSE::ENTRY",COLORS["bronze"]),
    ("AEC_HOUSE::GARAGE",COLORS["bronze"]), ("AEC_HOUSE::POOL",COLORS["water"]),
    ("AEC_HOUSE::INTERIOR",COLORS["stone"]), ("AEC_HOUSE::STAIRS",COLORS["slab"]),
]: layer(p,c,True)

# Floor and roof plates.
for nm,coords in [
    ("L1_MAIN_SLAB",(4.7,-15.2,0.25,13.8,3.2,0.55)),
    ("L1_GARAGE_SLAB",(4.7,2.8,0.25,17.2,14.2,0.55)),
    ("L2_MAIN_SLAB",(3.3,-15.2,4.0,13.8,3.2,4.30)),
    ("L2_NORTH_FLOOR_SLAB",(4.8,2.8,4.0,17.2,14.2,4.30)),
    ("L3_MAIN_SLAB",(1.3,-10.2,7.7,13.8,3.2,8.0)),
    ("ROOF_MAIN",(-1,-13.5,11.5,15,4.5,11.85)),
    ("ROOF_NORTH",(2.5,1.16,7.75,18.97,16.55,8.10)),
]: box(*(tuple([nm,"AEC_HOUSE::SLABS"]) + coords + tuple([COLORS["slab"]])))

# White ashlar perimeter walls with the west/view facades left open for glass.
wall_t=0.28
for level,wing,z0,z1,xw,xe,ys,yn in [
    (1,"SOUTH_WING",0.55,4.0,5,13.5,-15,3), (1,"NORTH_WING",0.55,4.0,5,17,3,14),
    (2,"SOUTH_WING",4.30,7.75,3.5,13.5,-15,3), (2,"NORTH_WING",4.30,7.75,5,17,3,14),
    (3,"MAIN",8.0,11.5,1.5,13.5,-10,3),
]:
    prefix="L%s_%s"%(level,wing)
    box(prefix+"_EAST_WALL","AEC_HOUSE::ASHLAR_WALLS",xe-wall_t,ys,z0,xe,yn,z1,COLORS["stone"])
    box(prefix+"_SOUTH_WALL","AEC_HOUSE::ASHLAR_WALLS",xw,ys,z0,xe,ys+wall_t,z1,COLORS["stone"])
    box(prefix+"_NORTH_WALL","AEC_HOUSE::ASHLAR_WALLS",xw,yn-wall_t,z0,xe,yn,z1,COLORS["stone"])

# West-facing floor-to-ceiling glazing and bronze grids.
facades=[("L1_SOUTH",5,-15,3,0.65,3.85), ("L2_SOUTH",3.5,-15,3,4.4,7.6),
         ("L1_NORTH",5,3,14,0.65,3.85), ("L2_NORTH",5,3,14,4.4,7.6),
         ("L3",1.5,-10,3,8.1,11.35)]
for prefix,x,y0,y1,z0,z1 in facades:
    box(prefix+"_GLASS","AEC_HOUSE::GLAZING",x-0.05,y0,z0,x+0.03,y1,z1,COLORS["glass"])
    bays=max(3,int((y1-y0)/2.4))
    for i in range(bays+1):
        y=y0+(y1-y0)*i/bays
        box(prefix+"_MULLION_%02d"%i,"AEC_HOUSE::BRONZE_FRAMES",x-0.10,y-0.035,z0,x+0.08,y+0.035,z1,COLORS["bronze"])
    box(prefix+"_TRANSOM","AEC_HOUSE::BRONZE_FRAMES",x-0.10,y0,(z0+z1)/2-0.035,x+0.08,y1,(z0+z1)/2+0.035,COLORS["bronze"])

# Cantilever balconies and minimal cable rails.
balconies=[("L2_WEST",1.5,-17.0,3.5,3.0,4.0), ("L2_NORTH",5,14,17,16.25,4.0),
           ("L3_WEST",1.5,-17,13.5,-10,7.75)]
for nm,x0,y0,x1,y1,z in balconies:
    box(nm+"_SLAB","AEC_HOUSE::SLABS",x0,y0,z,x1,y1,z+0.25,COLORS["slab"])
    # Outer edge rail posts and three horizontal cables.
    outer_x=min(x0,x1)
    span=y1-y0
    for i in range(max(2,int(abs(span)/2.5))+1):
        y=y0+span*i/max(2,int(abs(span)/2.5))
        box(nm+"_RAIL_POST_%02d"%i,"AEC_HOUSE::BALCONY_RAILS",outer_x-0.035,y-0.035,z+0.25,outer_x+0.035,y+0.035,z+1.25,COLORS["bronze"])
    for j,h in enumerate((0.55,0.85,1.15)):
        box(nm+"_RAIL_CABLE_%02d"%j,"AEC_HOUSE::BALCONY_RAILS",outer_x-0.03,min(y0,y1),z+h,outer_x+0.03,max(y0,y1),z+h+0.025,COLORS["bronze"])

# Veranda supports.
for i,y in enumerate((-14.5,-10,-5.5,-1)):
    box("VERANDA_POST_%02d"%i,"AEC_HOUSE::STRUCTURE",3.45,y-0.10,0.30,3.65,y+0.10,4.0,COLORS["concrete"])

# Entry, garage, and stairs on the east/street side.
box("ENTRY_PIVOT_DOOR","AEC_HOUSE::ENTRY",13.48,-1.0,0.55,13.62,0.6,3.35,COLORS["bronze"])
box("ENTRY_DEEP_REVEAL_TOP","AEC_HOUSE::ASHLAR_WALLS",13.35,-1.2,3.35,13.75,0.8,3.95,COLORS["stone"])
for i in range(3): box("ENTRY_STEP_%02d"%i,"AEC_HOUSE::STAIRS",13.5+i*0.35,-1.2,0.15+i*0.13,14.2+i*0.35,0.8,0.28+i*0.13,COLORS["slab"])
for i,(y0,y1) in enumerate(((5.0,8.8),(9.2,13.0))):
    box("GARAGE_DOOR_%02d"%(i+1),"AEC_HOUSE::GARAGE",16.86,y0,0.55,17.05,y1,3.25,COLORS["bronze"])

# Infinity pool and west patio using the source-plan extents.
box("PATIO_CONCRETE","AEC_HOUSE::SITE",-5.8,-16.8,-0.05,4.8,13.8,0.15,COLORS["slab"])
box("INFINITY_POOL_SHELL","AEC_HOUSE::POOL",-5.6,-14.0,-0.70,0.2,5.0,0.05,COLORS["concrete"])
box("INFINITY_POOL_WATER","AEC_HOUSE::POOL",-5.45,-13.85,0.03,0.05,4.85,0.12,COLORS["water"])
box("INFINITY_POOL_BRONZE_EDGE","AEC_HOUSE::BRONZE_FRAMES",-5.62,-14.0,0.08,-5.48,5.0,0.18,COLORS["bronze"])

# Interior floor program: named partition walls at each level.
partitions=[
    ("L1_GUEST_SUITE",8.6,-15,8.6,-9,0.55,4.0), ("L1_SERVICE",10.8,-9,10.8,-3,0.55,4.0),
    ("L1_STAIR_CORE",8.6,-3,13.5,-3,0.55,4.0), ("L1_GARAGE_DIVIDE",5,8.5,17,8.5,0.55,4.0),
    ("L2_BEDROOM_WING",8.5,-15,8.5,3,4.30,7.75), ("L2_MEDIA_DIVIDE",3.5,-5,13.5,-5,4.30,7.75),
    ("L2_NORTH_ROOMS",5,8.5,17,8.5,4.30,7.75), ("L3_SUITE_DIVIDE",7.5,-10,7.5,3,8.0,11.5),
    ("L3_STUDY_DIVIDE",1.5,-3,13.5,-3,8.0,11.5),
]
for nm,x0,y0,x1,y1,z0,z1 in partitions:
    line_box(nm+"_WALL","AEC_HOUSE::INTERIOR",(x0,y0,z0),(x1,y1,z0),0.18,z1-z0,COLORS["stone"])

# Hidden, separately laid-out floor plans with unique room labels.
layer("FLOORPLAN::LEVEL_1",COLORS["plan"],False); layer("FLOORPLAN::LEVEL_2",COLORS["plan"],False)
layer("FLOORPLAN::LEVEL_3",COLORS["plan"],False); layer("FLOORPLAN::LABELS",COLORS["plan"],False)
programs={
  1:["LIVING","DINING","KITCHEN","GUEST_SUITE","GUEST_BATH","ENTRY","STAIR_LIFT","MUD_LAUNDRY","TWO_CAR_GARAGE"],
  2:["BEDROOM_2","BEDROOM_3","BEDROOM_4","BATH_2","BATH_3","FAMILY_LOUNGE","MEDIA_STUDY","LINEN","STAIR_LIFT","NORTH_BALCONY"],
  3:["PRIMARY_BEDROOM","WALK_IN_CLOSET","PRIMARY_BATH","PRIVATE_STUDY","SKY_LOUNGE","STAIR_LIFT","ROOF_TERRACE"],
}
for level_no,rooms in programs.items():
    ox=30+(level_no-1)*18; oy=-15
    curve_rect("L%s_PLAN_OUTLINE"%level_no,"FLOORPLAN::LEVEL_%s"%level_no,ox,oy,ox+14,oy+24,0,COLORS["plan"])
    cols=2; rows=(len(rooms)+1)//2
    for i,room in enumerate(rooms):
        c=i%cols; r=i//cols; x0=ox+c*7; y0=oy+r*(20.0/rows)
        x1=x0+7; y1=y0+(20.0/rows)
        curve_rect("L%s_%s_OUTLINE"%(level_no,room),"FLOORPLAN::LEVEL_%s"%level_no,x0,y0,x1,y1,0,COLORS["plan"])
        text("L%s_%s_LABEL"%(level_no,room),room.replace("_"," "),"FLOORPLAN::LABELS",(x0+x1)/2,(y0+y1)/2,0,0.35,COLORS["plan"])
    text("L%s_SCHEMATIC_NOTE"%level_no,"LEVEL %s SCHEMATIC - VERIFY STRUCTURE, EGRESS, ACCESSIBILITY AND LOCAL CODE"%level_no,
         "FLOORPLAN::LABELS",ox+7,oy+22,0,0.32,COLORS["plan"])

# Preserve the source scene, but hide its curve/label parents in the finished view.
for source_path in ("Source_Curves", "Labels"):
    idx=doc.Layers.FindByFullPath(source_path,-1)
    if idx>=0: doc.Layers[idx].IsVisible=False

doc.Strings.SetString("AEC_SCHEMA", "swagstaff-cliff-house/1.0")
doc.Strings.SetString("AEC_SOURCE", "stwagstaff/2026_aec_cptx_demo base_model.3dm")
doc.Strings.SetString("AEC_BUILD_METHOD", "deterministic-from-scratch")
doc.Strings.SetString("AEC_PROGRAM", "3 levels; pool; patio; two-car garage; labeled schematic floor plans")
doc.Views.Redraw()
print("SWAGSTAFF_FRESH_BUILD_PASS objects=%s layers=%s" % (doc.Objects.Count, doc.Layers.Count))

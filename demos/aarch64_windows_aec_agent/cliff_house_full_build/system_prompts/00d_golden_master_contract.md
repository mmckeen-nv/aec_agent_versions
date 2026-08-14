# Golden Master Build Contract — Cliff House 02

This contract defines the required Rhino result for the full-build demo. Read it after
`00b_rhino_scene_protocol.md` and before every Rhino construction phase. It is normative when a
generic upstream phase prompt offers an example or adjustable default.

The full build must begin with
`projects/cliff_house_02/rhino_assets/base_model.3dm` (SHA-256
`DDACAC2BA0CEA8DF75A1B02B9214C64BBCBF4B5D214E60C67DAC94A32E7272D0`). That source contains 16
objects and reports metres. Never load, import, reference, or copy geometry from the modification
demo's golden master. The golden master is an acceptance target, not an input.

## Document contract

- Units: metres; absolute tolerance: `0.001`.
- Preserve all 16 source objects and hide the `Source_Curves` and `Labels` parents in the finished
  architectural view.
- Every new object must have a unique stable name and a semantic nested layer.
- Document metadata:
  - `AEC_SCHEMA=swagstaff-cliff-house/1.0`
  - `AEC_SOURCE=stwagstaff/2026_aec_cptx_demo base_model.3dm`
  - `AEC_BUILD_METHOD=deterministic-from-scratch`

## Phase 01 — site

- `SITE_TERRAIN_NURBS`: bounds `(-15,-22,-8)` to `(25,20,0)`, rising west-to-east.
- `SITE_COMBINED_PAD`: `(1.5,-16.9,-0.5)` to `(17,14,0.25)`.
- Four individually named retaining walls around `(1,-17.4,-2)` to `(17.5,14.5,0.25)`.
- `SITE_DRIVEWAY`: `(17.5,3.96,-0.2)` to `(25.03,13,0.25)`.
- Target root: `building_site_v3`; expected authored site objects: 7.

## Phase 02 — canonical massing

Build exactly these 11 named volumes on the stated `massing_v3` sublayers:

| Name | Bounds `(x0,y0,z0) → (x1,y1,z1)` |
|---|---|
| `L1_EAST` | `(5,3,0.25) → (17,14,4)` |
| `L1_WEST` | `(5,-15,0.3) → (13.5,3,4)` |
| `L2_EAST` | `(5,3,4.25) → (17,14,7.75)` |
| `L2_WEST` | `(3.5,-15,4.25) → (13.5,3,7.75)` |
| `L2_BALCONY_SOUTH` | `(1.5,-17.05,4) → (13.5,3,5.25)` |
| `L2_BALCONY_NORTH` | `(5,14,4) → (17,16.25,5.15)` |
| `L2_BALCONY_STEP` | `(1.5,3,4) → (5,14,5.25)` |
| `L2_ROOF_GARAGE` | `(2.5,1.16,7.75) → (18.97,16.55,8.35)` |
| `L3_MAIN` | `(1.5,-10,7.75) → (13.5,3,11.5)` |
| `L3_BALCONY_SOUTH` | `(1.5,-17,7.75) → (13.5,-10,8.9)` |
| `L3_ROOF_SLAB` | `(-1,-13.5,11.5) → (15,4.5,12.3)` |

Keep the canonical massing hierarchy as hidden design intent in the finished view. Detailed
architecture belongs under `AEC_HOUSE`.

## Phases 03–06 — finished architecture

Create these visible semantic layers:

- `AEC_HOUSE::SITE`, `STRUCTURE`, `SLABS`, `ASHLAR_WALLS`, `GLAZING`,
  `BRONZE_FRAMES`, `BALCONY_RAILS`, `ENTRY`, `GARAGE`, `POOL`, `INTERIOR`, `STAIRS`.
- Floor plates: two Level 1 wings, two Level 2 wings, Level 3 main plate, main roof, north roof.
- White ashlar perimeter walls; leave the west/view facades open for glazing.
- Five named full-height west glazing runs: Level 1 south/north, Level 2 south/north, Level 3.
  Use regularly spaced bronze mullions and a mid-height transom on each run.
- Cantilever balconies: Level 2 west, Level 2 north, Level 3 west. Add individually named posts and
  three horizontal cable rails to each outer edge.
- Four veranda posts along the west edge.
- Oversized bronze pivot entry door in a deep ashlar reveal; three entry steps.
- Two individually named east-facing garage doors.
- Patio: `(-5.8,-16.8,-0.05) → (4.8,13.8,0.15)`.
- Infinity pool shell: `(-5.6,-14,-0.7) → (0.2,5,0.05)`; named water surface and bronze west
  overflow edge are mandatory.
- Named partitions must express guest/service/stair/garage on Level 1, bedrooms/media/north rooms
  on Level 2, and primary suite/study on Level 3.

## Floor-plan program

Create hidden, separately laid-out `FLOORPLAN::LEVEL_1`, `LEVEL_2`, `LEVEL_3`, and `LABELS`
geometry. Every room outline and label must be unique and level-prefixed.

- Level 1: living, dining, kitchen, guest suite, guest bath, entry, stair/lift, mud/laundry,
  two-car garage.
- Level 2: bedrooms 2–4, baths 2–3, family lounge, media/study, linen, stair/lift, north balcony.
- Level 3: primary bedroom, walk-in closet, primary bath, private study, sky lounge, stair/lift,
  roof terrace.
- Each plan must state: `SCHEMATIC - VERIFY STRUCTURE, EGRESS, ACCESSIBILITY AND LOCAL CODE`.

## Acceptance gate

Before Rhino handoff, prove all of the following from the active working document:

- 16 preserved source objects plus exactly 191 authored objects (207 total).
- Exactly 7 authored `building_site_v3`, 11 `massing_v3`, 115 `AEC_HOUSE`, and 58 `FLOORPLAN`
  objects.
- All 191 authored objects are named and all 191 names are unique.
- 42 total layers, metre units, and required metadata values.
- Required names include `SITE_TERRAIN_NURBS`, `L1_EAST`, `L2_WEST`, `L3_MAIN`,
  `L3_ROOF_SLAB`, `INFINITY_POOL_WATER`, `ENTRY_PIVOT_DOOR`, `GARAGE_DOOR_01`,
  `L1_LIVING_LABEL`, `L2_BEDROOM_2_LABEL`, and `L3_PRIMARY_BEDROOM_LABEL`.

Do not proceed to Blender if any invariant fails. Repair the active phase, re-query, and issue a
new verified receipt.

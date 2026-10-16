-- ======================================================================
--  Villas_Row.ms   (3ds Max 2024 - Physical Materials - real meters)
--
--  Row of 5 modern townhouse villas from the street render:
--   - 2 floors + roof stair box, taupe cladding, cantilevered first floor
--   - recessed glass bay + glass balcony, vertical wood louvers
--   - tall side fin wall, stone boundary wall with "Villa 0X" sign,
--     wood pedestrian door + wood car gate, white canopy slab,
--     planter + flower bed, wall light
--   - street: asphalt road with lane marks, curb/sidewalk, palm trees
--
--  Run:  Scripting > Run Script...   (or open it and press Ctrl+E)
--  Units: works with any System Unit - every size below is in meters.
--  X = along the street, -Y = towards the street, Z = up.
-- ======================================================================
(
	local nVillas = 5
	local plotW   = 10.5   -- plot frontage
	local plotD   = 16.0   -- plot depth
	local gf      = 3.60   -- ground floor height
	local ff      = 3.40   -- first floor height
	local roofZ   = gf + ff -- 7.00 top of first floor slab

	local U1m = units.decodeValue "1m"
	local curLayer = undefined
	local curNodes = #()

	fn mU v = v * U1m
	fn p3 x y z = [mU x, mU y, mU z]

	fn reg o mat nm = (
		if mat != undefined do o.material = mat
		o.name = uniqueName nm
		curLayer.addNode o
		append curNodes o
		o
	)
	fn mkMat nm col rough metal = (
		local mt = PhysicalMaterial name:nm
		mt.base_color = col
		mt.roughness = rough
		mt.metalness = metal
		mt
	)
	fn mkEmit nm col lum = (
		local mt = mkMat nm col 0.5 0.0
		try (mt.emission = 1.0; mt.emit_color = col; mt.emit_luminance = lum) catch ()
		mt
	)
	fn mkGlass nm = (
		local mt = mkMat nm (color 150 170 180) 0.02 0.0
		try (mt.transparency = 0.85; mt.trans_color = (color 225 238 245); mt.trans_ior = 1.52) catch ()
		mt
	)

	-- materials
	local mStone   = mkMat "Villa_Stone_Beige"    (color 226 218 205) 0.80 0.0
	local mTaupe   = mkMat "Villa_Cladding_Taupe" (color 178 158 145) 0.65 0.0
	local mTaupeDk = mkMat "Villa_Cladding_Dark"  (color 128 110 100) 0.65 0.0
	local mPlaster = mkMat "Villa_Plaster_Light"  (color 214 204 192) 0.85 0.0
	local mWhite   = mkMat "Villa_White"          (color 238 236 230) 0.70 0.0
	local mWood    = mkMat "Villa_Wood_Teak"      (color 140 92 55)   0.55 0.0
	local mAlu     = mkMat "Villa_Alu_DarkGrey"   (color 48 48 50)    0.35 0.85
	local mGlass   = mkGlass "Villa_Glass"
	local mGroove  = mkMat "Villa_Groove"         (color 150 142 132) 0.80 0.0
	local mSign    = mkMat "Villa_Sign_Text"      (color 45 45 45)    0.40 0.30
	local mLamp    = mkEmit "Villa_WallLight"     (color 255 200 140) 1500.0
	local mPlant   = mkMat "Plant_Green"          (color 58 96 42)    0.75 0.0
	local mFlowerP = mkMat "Flower_Purple"        (color 120 70 170)  0.60 0.0
	local mFlowerY = mkMat "Flower_Yellow"        (color 235 200 60)  0.60 0.0
	local mFlowerR = mkMat "Flower_Pink"          (color 220 90 130)  0.60 0.0
	local mSoil    = mkMat "Soil"                 (color 70 52 38)    0.95 0.0
	local mAsphalt = mkMat "Road_Asphalt"         (color 58 60 64)    0.90 0.0
	local mMark    = mkMat "Road_Marking_White"   (color 235 235 235) 0.60 0.0
	local mWalk    = mkMat "Sidewalk_Paver"       (color 172 170 164) 0.85 0.0
	local mCurb    = mkMat "Curb_Concrete"        (color 200 198 192) 0.80 0.0
	local mTrunk   = mkMat "Palm_Trunk"           (color 120 96 70)   0.90 0.0
	local mFrond   = mkMat "Palm_Frond"           (color 70 105 60)   0.75 0.0

	-- ---------------- primitives ----------------
	fn bx x0 y0 z0 x1 y1 z1 mat nm:"Part" = (
		local o = Box length:(mU (abs (y1-y0))) width:(mU (abs (x1-x0))) height:(mU (abs (z1-z0)))
		o.pos = p3 ((x0+x1)/2.0) ((y0+y1)/2.0) (amin z0 z1)
		reg o mat nm
	)
	fn cyl x y z r h mat dir:[0,0,1] nm:"Cyl" sides:16 = (
		local o = Cylinder radius:(mU r) height:(mU h) sides:sides heightsegs:1
		o.dir = dir
		o.pos = p3 x y z
		reg o mat nm
	)
	fn ball x y z r mat nm:"Leaf" = (
		local o = Sphere radius:(mU r) segs:8
		o.pos = p3 x y z
		reg o mat nm
	)
	fn signText str x z yFront sz thick mat nm = (
		local t = text text:str size:(mU sz) font:"Century Gothic"
		addModifier t (Extrude amount:(mU thick) capStart:true capEnd:true)
		t.transform = matrix3 [1,0,0] [0,0,1] [0,-1,0] [0,0,0]
		CenterPivot t
		t.pos = p3 x (yFront - thick/2.0) z
		reg t mat nm
	)
	-- vertical slats between x0..x1 (gates / louvers)
	fn slats x0 x1 y0 y1 z0 z1 w gap mat nm = (
		local x = x0
		while x + w <= x1 + 0.001 do (
			bx x y0 z0 (x+w) y1 z1 mat nm:nm
			x += w + gap
		)
	)
	fn shrub x y z r mat = (
		ball x y (z + r*0.8) r mat nm:"Shrub"
		ball (x + r*0.5) (y + r*0.2) (z + r*0.6) (r*0.75) mat nm:"Shrub"
		ball (x - r*0.5) (y - r*0.1) (z + r*0.6) (r*0.7) mat nm:"Shrub"
	)
	fn palm x y h = (
		local o = Cone radius1:(mU 0.28) radius2:(mU 0.18) height:(mU h) sides:12
		o.pos = p3 x y 0
		reg o mTrunk "Palm_Trunk"
		for i = 1 to 14 do (
			local yaw = i * (360.0/14) + (random (-8) 8)
			local tilt = if (mod i 2) == 0 then (random 10 25) else (random 30 50)
			local d = [(cos yaw)*(cos tilt), (sin yaw)*(cos tilt), -(sin tilt)]
			local f = Cylinder radius:(mU 0.35) height:(mU (random 2.4 3.2)) sides:8 heightsegs:1
			f.dir = d
			f.scale = [1, 0.12, 1]
			f.pos = p3 x y h
			reg f mFrond "Palm_Frond"
		)
		ball x y (h + 0.1) 0.35 mTrunk nm:"Palm_Head"
	)

	-- ==================================================================
	--  ONE VILLA  (local plot x 0..plotW, boundary wall at y = 0)
	-- ==================================================================
	fn buildVilla idx = (
		-- ---------- boundary wall / gates ----------
		bx 0.00 0.00 0 0.50 0.30 3.00 mStone nm:"Pillar"
		bx 0.50 0.05 0 1.90 0.20 0.05 mAlu nm:"Door_Sill"
		slats 0.52 1.88 0.08 0.16 0.05 2.40 0.09 0.025 mWood "Ped_Door_Slat"
		bx 0.50 0.04 2.40 1.90 0.20 2.50 mAlu nm:"Door_Head"
		bx 1.70 0.02 1.00 1.73 0.08 1.80 mAlu nm:"Door_Handle"
		-- name wall with grooves + sign
		bx 1.90 0.00 0 5.40 0.30 2.50 mStone nm:"Name_Wall"
		for gx in #(2.60, 3.30, 4.00, 4.70) do bx gx (-0.004) 0.05 (gx+0.015) 0.0 2.45 mGroove nm:"Wall_Groove"
		signText ("Villa 0" + (idx as string)) 4.40 2.05 0.0 0.30 0.012 mSign "Villa_Sign"
		-- wall light on the pillar
		bx 0.15 (-0.08) 2.35 0.35 0.0 2.65 mAlu nm:"WallLight_Body"
		bx 0.18 (-0.085) 2.40 0.32 (-0.08) 2.60 mLamp nm:"WallLight_Glow"
		-- car gate
		slats 5.42 9.88 0.08 0.16 0.05 2.40 0.10 0.025 mWood "Car_Gate_Slat"
		bx 5.40 0.04 2.40 9.90 0.20 2.50 mAlu nm:"Gate_Head"
		bx 9.90 0.00 0 10.40 0.30 2.60 mStone nm:"Pillar_Shared"
		-- white canopy slab over the entrance
		bx (-0.30) (-0.60) 2.95 5.60 1.20 3.20 mWhite nm:"Entrance_Canopy"
		bx 5.30 0.00 0 5.60 0.30 2.95 mWhite nm:"Canopy_Post"
		-- side boundary walls
		bx 9.95 0.30 0 10.35 plotD 2.40 mPlaster nm:"Side_Wall"
		-- planter + shrub at the pillar, flower bed in front of the name wall
		bx (-0.10) (-1.00) 0 1.20 (-0.15) 0.55 mStone nm:"Planter"
		bx (-0.05) (-0.95) 0.55 1.15 (-0.20) 0.57 mSoil nm:"Planter_Soil"
		shrub 0.55 (-0.58) 0.57 0.42 mPlant
		ball 0.30 (-0.40) 1.55 0.30 mPlant nm:"Shrub"
		bx 2.00 (-0.45) 0 5.30 (-0.02) 0.12 mStone nm:"Flower_Bed"
		for i = 1 to 26 do (
			local m = case ((mod i 3) as integer) of (0: mFlowerP; 1: mFlowerY; default: mFlowerR)
			ball (random 2.10 5.20) (random (-0.40) (-0.08)) (random 0.15 0.24) (random 0.06 0.10) m nm:"Flower"
		)
		for i = 1 to 8 do ball (random 2.10 5.20) (random (-0.40) (-0.08)) 0.12 (random 0.08 0.12) mPlant nm:"Bed_Leaf"

		-- ---------- house ----------
		-- ground floor (set back behind the wall)
		bx 0.80 4.00 0 9.60 (plotD-1.0) gf mPlaster nm:"GF_Body"
		bx 1.40 3.98 0.10 4.20 4.00 2.90 mGlass nm:"GF_Glass"
		bx 5.00 3.98 0.00 6.40 4.00 2.60 mWood nm:"GF_Entry_Door"
		-- first floor slab edge / cantilever
		bx 0.50 3.10 gf 9.60 (plotD-1.0) (gf+0.25) mWhite nm:"FF_Slab"
		-- tall side fin wall (rises above the roof)
		bx 0.50 3.00 0 1.30 (plotD-1.0) (roofZ+1.20) mTaupeDk nm:"Side_Fin"
		-- recessed glass bay with balcony
		bx 1.30 4.00 (gf+0.25) 4.20 4.10 (roofZ-0.15) mGlass nm:"FF_Glass"
		for mx in #(1.30, 2.25, 3.20, 4.12) do bx mx 3.96 (gf+0.25) (mx+0.08) 4.04 (roofZ-0.15) mAlu nm:"Mullion"
		bx 1.30 3.96 (gf+2.20) 4.20 4.04 (gf+2.28) mAlu nm:"Transom"
		bx 1.30 3.10 (gf+0.25) 4.20 3.14 (gf+1.25) mGlass nm:"Balcony_Glass"
		bx 1.30 3.08 (gf+1.25) 4.20 3.16 (gf+1.29) mAlu nm:"Balcony_Rail"
		bx 1.30 4.00 (roofZ-0.15) 4.20 (plotD-1.0) roofZ mTaupe nm:"FF_Bay_Head"
		-- solid taupe box with wood louvers
		bx 4.20 3.20 (gf+0.25) 9.60 (plotD-1.0) roofZ mTaupe nm:"FF_Box"
		slats 4.40 6.40 3.02 3.20 (gf+0.40) (roofZ-0.10) 0.06 0.07 mWood "Louver"
		for gz in #(gf+1.40, gf+2.40) do bx 6.40 3.196 gz 9.60 3.20 (gz+0.015) mGroove nm:"Panel_Groove"
		for gx in #(7.50, 8.55) do bx gx 3.196 (gf+0.25) (gx+0.015) 3.20 roofZ mGroove nm:"Panel_Groove"
		-- parapet + roof stair box
		bx 0.50 3.00 roofZ 9.60 (plotD-1.0) (roofZ+0.30) mTaupe nm:"Parapet"
		bx 1.30 3.40 roofZ 9.20 (plotD-1.4) (roofZ+0.31) mPlaster nm:"Roof_Infill"
		bx 1.60 6.50 roofZ 4.00 10.00 (roofZ+2.40) mWhite nm:"Roof_Stair_Box"
		bx 1.50 6.40 (roofZ+2.40) 4.10 10.10 (roofZ+2.55) mTaupe nm:"Roof_Stair_Cap"
	)

	-- ==================================================================
	--  RUN
	-- ==================================================================
	seed 11
	disableSceneRedraw()
	try (
		with undo off (
			curLayer = LayerManager.getLayerFromName "Villas_Row"
			if curLayer == undefined do curLayer = LayerManager.newLayerFromName "Villas_Row"
			for i = 1 to nVillas do (
				curNodes = #()
				buildVilla i
				move curNodes (p3 ((i-1)*plotW) 0 0)
				local g = group curNodes name:("Villa_0" + (i as string))
				curLayer.addNode g
			)

			-- street
			curLayer = LayerManager.getLayerFromName "Villas_Street"
			if curLayer == undefined do curLayer = LayerManager.newLayerFromName "Villas_Street"
			curNodes = #()
			local x0 = -15.0
			local x1 = nVillas*plotW + 10.0
			bx x0 (-14.0) (-0.02) x1 (-2.0) 0.0 mAsphalt nm:"Road"
			bx x0 (-2.0) 0 x1 (-1.75) 0.15 mCurb nm:"Curb"
			bx x0 (-1.75) 0 x1 0.0 0.12 mWalk nm:"Sidewalk"
			local x = x0
			while x < x1 do (
				bx x (-8.08) 0.0 (x+3.0) (-7.92) 0.005 mMark nm:"Lane_Mark"
				x += 6.0
			)
			bx x0 (-4.0) 0.0 x1 (-3.88) 0.005 mMark nm:"Edge_Line"
			local gp = Plane length:(mU 60) width:(mU (x1-x0)) lengthsegs:1 widthsegs:1
			gp.pos = p3 ((x0+x1)/2.0) 16.0 (-0.03)
			reg gp mPlant "Ground_Behind"
			palm (-9.0) (-1.0) 8.5
			palm (-5.5) 1.5 6.5
			palm (-12.0) 2.5 7.5

			-- camera like the street render
			local tgt = Targetobject pos:(p3 22.0 4.0 3.5)
			local cam = Targetcamera fov:62 pos:(p3 (-7.0) (-13.0) 1.6) target:tgt
			cam.name = uniqueName "Cam_Villas_Street"
			tgt.name = cam.name + ".Target"
			curLayer.addNode cam
			curLayer.addNode tgt
		)
		format "Villas row built: % villas, plot % x % m.\n" nVillas plotW plotD
	) catch (
		format "Villas script error: %\n" (getCurrentException())
	)
	enableSceneRedraw()
	try (max zoomext sel all) catch ()
	completeRedraw()
)

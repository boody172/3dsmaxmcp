-- ======================================================================
--  Villas_Night_Scene.ms   (3ds Max 2024 + Arnold - real meters)
--
--  Night, render-ready version of the 5-villa street render:
--   - villas with the same massing, materials and details as the image
--     (taupe cladding with panel joints, dark side fin, recessed glazing +
--     glass balcony, teak louvers, stone boundary wall "Villa 0X", teak
--     pedestrian door + car gate, white entrance canopy, planters, flowers)
--   - night lighting: pillar sconces (up/down wash), canopy downlights +
--     LED strip, uplights on the name wall, lit interiors behind glazing
--     with sheer curtains, LED under the cantilever, street lights
--   - 2 cars (headlights + tail lights on), 4 people (proxy figures)
--   - night sky dome, wet-look asphalt, physical camera, Arnold, 1920 px
--
--  Run:  Scripting > Run Script...   (or open it and press Ctrl+E)
--  X = along the street, -Y = towards the street, Z = up. Sizes in meters.
-- ======================================================================
(
	local nVillas = 5
	local plotW   = 10.5
	local plotD   = 16.0
	local gf      = 3.60
	local ff      = 3.40
	local roofZ   = gf + ff

	local U1m = units.decodeValue "1m"
	local curLayer = undefined
	local curNodes = #()

	fn mU v = v * U1m
	fn p3 x y z = [mU x, mU y, mU z]

	fn useLayer nm = (
		curLayer = LayerManager.getLayerFromName nm
		if curLayer == undefined do curLayer = LayerManager.newLayerFromName nm
		curLayer
	)
	fn reg o mat nm = (
		if mat != undefined do o.material = mat
		o.name = uniqueName nm
		curLayer.addNode o
		append curNodes o
		o
	)

	-- ---------------- materials ----------------
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
	fn mkGlass nm col trans = (
		local mt = mkMat nm col 0.02 0.0
		try (mt.transparency = trans; mt.trans_color = (color 225 238 245); mt.trans_ior = 1.52) catch ()
		mt
	)
	fn noiseBump mt sz amt = (
		try (
			local n = Noise()
			n.size = mU sz
			mt.bump_map = n
			mt.bump_map_amt = amt
		) catch ()
		mt
	)
	fn woodGrain mt c1 c2 = (
		try (
			local w = Wood()
			w.color1 = c1
			w.color2 = c2
			w.thickness = mU 0.02
			mt.base_color_map = w
		) catch ()
		mt
	)

	local mStone   = noiseBump (mkMat "Villa_Stone_Beige" (color 226 218 205) 0.85 0.0) 0.02 0.15
	local mTaupe   = noiseBump (mkMat "Villa_Cladding_Taupe" (color 176 156 143) 0.60 0.0) 0.05 0.05
	local mTaupeDk = noiseBump (mkMat "Villa_Cladding_Dark" (color 132 114 104) 0.60 0.0) 0.05 0.05
	local mPlaster = noiseBump (mkMat "Villa_Plaster_Light" (color 214 204 192) 0.85 0.0) 0.01 0.10
	local mWhite   = mkMat "Villa_White" (color 238 236 230) 0.70 0.0
	local mWood    = woodGrain (mkMat "Villa_Wood_Teak" (color 140 92 55) 0.50 0.0) (color 150 98 58) (color 112 70 40)
	local mAlu     = mkMat "Villa_Alu_DarkGrey" (color 48 48 50) 0.35 0.85
	local mGlass   = mkGlass "Villa_Glass" (color 120 140 150) 0.80
	local mRail    = mkGlass "Villa_Balcony_Glass" (color 160 180 185) 0.90
	local mCurtain = mkGlass "Villa_Sheer_Curtain" (color 245 240 230) 0.45
	local mGroove  = mkMat "Villa_Groove" (color 120 112 104) 0.80 0.0
	local mSign    = mkMat "Villa_Sign_Text" (color 40 40 40) 0.40 0.30
	local mPlant   = noiseBump (mkMat "Plant_Green" (color 50 88 38) 0.75 0.0) 0.03 0.4
	local mFlowerP = mkMat "Flower_Purple" (color 120 70 170) 0.60 0.0
	local mFlowerY = mkMat "Flower_Yellow" (color 235 200 60) 0.60 0.0
	local mFlowerR = mkMat "Flower_Pink" (color 220 90 130) 0.60 0.0
	local mSoil    = mkMat "Soil" (color 60 45 32) 0.95 0.0
	-- night light sources (Physical emission, Arnold-ready)
	local mLamp     = mkEmit "Light_Sconce_Warm"   (color 255 196 130) 3000.0
	local mLED      = mkEmit "Light_LED_Strip"     (color 255 205 150) 2500.0
	local mInterior = mkEmit "Light_Interior_Wall" (color 255 210 160) 120.0
	local mStreetL  = mkEmit "Light_Street_Lamp"   (color 255 225 190) 6000.0
	local mHead     = mkEmit "Car_Headlight"       (color 245 248 255) 8000.0
	local mTail     = mkEmit "Car_Taillight"       (color 255 30 20) 900.0
	-- street
	local mAsphalt = noiseBump (mkMat "Road_Asphalt_Wet" (color 46 48 52) 0.32 0.0) 0.01 0.35
	local mMark    = mkMat "Road_Marking_White" (color 230 230 230) 0.55 0.0
	local mWalk    = noiseBump (mkMat "Sidewalk_Paver" (color 160 158 152) 0.70 0.0) 0.02 0.2
	local mCurb    = mkMat "Curb_Concrete" (color 196 194 188) 0.80 0.0
	local mTrunk   = noiseBump (mkMat "Palm_Trunk" (color 110 88 64) 0.90 0.0) 0.03 0.8
	local mFrond   = mkMat "Palm_Frond" (color 62 95 52) 0.75 0.0
	local mPole    = mkMat "StreetLight_Pole" (color 70 72 75) 0.40 0.80
	local mSky     = mkEmit "Night_Sky_Dome" (color 30 48 95) 0.35
	-- cars
	local mCarGold = mkMat "Car_Paint_Champagne" (color 168 140 105) 0.18 0.75
	local mCarGrey = mkMat "Car_Paint_Graphite" (color 52 56 62) 0.18 0.75
	local mCarGlass= mkGlass "Car_Glass_Tint" (color 20 24 28) 0.25
	local mTire    = mkMat "Car_Tire" (color 22 22 22) 0.85 0.0
	local mRim     = mkMat "Car_Rim_Alloy" (color 190 190 195) 0.25 0.95
	local mChrome  = mkMat "Car_Trim_Black" (color 15 15 15) 0.30 0.50
	-- people (proxy figures)
	local mSkin    = mkMat "People_Skin" (color 196 150 120) 0.55 0.0
	local mHair    = mkMat "People_Hair" (color 30 24 20) 0.60 0.0
	local mShirtW  = mkMat "People_Shirt_White" (color 228 226 220) 0.80 0.0
	local mShirtB  = mkMat "People_Shirt_Navy" (color 35 45 75) 0.80 0.0
	local mAbaya   = mkMat "People_Dress_Beige" (color 190 170 140) 0.80 0.0
	local mPants   = mkMat "People_Pants_Dark" (color 40 40 45) 0.80 0.0
	local mShoes   = mkMat "People_Shoes" (color 25 25 25) 0.50 0.0

	-- ---------------- geometry helpers ----------------
	fn bx x0 y0 z0 x1 y1 z1 mat nm:"Part" = (
		local o = Box length:(mU (abs (y1-y0))) width:(mU (abs (x1-x0))) height:(mU (abs (z1-z0)))
		o.pos = p3 ((x0+x1)/2.0) ((y0+y1)/2.0) (amin z0 z1)
		reg o mat nm
	)
	fn cbx cx cy z0 lx ly h f mat nm = (
		local o = ChamferBox length:(mU ly) width:(mU lx) height:(mU h) fillet:(mU f) Fillet_Segments:3
		o.pos = p3 cx cy z0
		reg o mat nm
	)
	fn cyl x y z r h mat dir:[0,0,1] nm:"Cyl" sides:16 = (
		local o = Cylinder radius:(mU r) height:(mU h) sides:sides heightsegs:1
		o.dir = dir
		o.pos = p3 x y z
		reg o mat nm
	)
	fn ball x y z r mat nm:"Leaf" segs:8 = (
		local o = Sphere radius:(mU r) segs:segs
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

	-- ---------------- light helpers (photometric, Arnold renders them) ----------------
	fn spot x y z tx ty tz cd kelvin hot fall nm = (
		local tgt = Targetobject pos:(p3 tx ty tz)
		local L = Target_Light pos:(p3 x y z) target:tgt
		try (L.distribution = 1) catch ()
		try (L.useKelvin = true; L.kelvin = kelvin) catch ()
		try (L.intensityType = 1; L.intensity = cd) catch ()
		try (L.hotspot = hot; L.falloff = fall) catch ()
		reg L undefined nm
		reg tgt undefined (nm + "_Target")
		L
	)
	fn pointL x y z cd kelvin nm = (
		local L = Free_Light pos:(p3 x y z)
		try (L.distribution = 0) catch ()
		try (L.useKelvin = true; L.kelvin = kelvin) catch ()
		try (L.intensityType = 1; L.intensity = cd) catch ()
		reg L undefined nm
	)

	fn palm x y h = (
		local o = Cone radius1:(mU 0.28) radius2:(mU 0.18) height:(mU h) sides:12 heightsegs:6
		o.pos = p3 x y 0
		reg o mTrunk "Palm_Trunk"
		for i = 1 to 16 do (
			local yaw = i * (360.0/16) + (random (-8) 8)
			local tilt = if (mod i 2) == 0 then (random 5 20) else (random 30 55)
			local d = [(cos yaw)*(cos tilt), (sin yaw)*(cos tilt), -(sin tilt)]
			local f = Cylinder radius:(mU 0.38) height:(mU (random 2.6 3.4)) sides:8 heightsegs:1
			f.dir = d
			f.scale = [1, 0.10, 1]
			f.pos = p3 x y h
			reg f mFrond "Palm_Frond"
		)
		ball x y (h + 0.1) 0.38 mTrunk nm:"Palm_Head"
	)

	fn streetLight x y = (
		cyl x y 0 0.10 0.40 mPole nm:"SL_Base"
		cyl x y 0 0.07 7.50 mPole nm:"SL_Pole"
		cyl x y 7.40 0.05 1.60 mPole dir:[0,-1,0] nm:"SL_Arm"
		bx (x-0.25) (y-1.85) 7.35 (x+0.25) (y-1.25) 7.50 mPole nm:"SL_Head"
		bx (x-0.20) (y-1.80) 7.33 (x+0.20) (y-1.30) 7.35 mStreetL nm:"SL_Lens"
		spot x (y-1.55) 7.30 x (y-1.0) 0 9000 4000 70 120 "SL_Light"
	)

	-- ---------------- car (sedan ~4.6 x 1.8 x 1.45 m) ----------------
	fn car cx cy heading paint nm = (
		local s0 = curNodes.count
		cbx 0 0 0.28 4.60 1.80 0.72 0.14 paint "Car_Body"
		cbx (-0.20) 0 0.92 2.50 1.62 0.50 0.20 mCarGlass "Car_Cabin_Glass"
		cbx (-0.30) 0 1.36 1.90 1.50 0.08 0.04 paint "Car_Roof"
		cbx 1.70 0 0.92 0.90 1.70 0.08 0.04 paint "Car_Bonnet_Top"
		bx 2.28 (-0.62) 0.38 2.32 0.62 0.55 mChrome nm:"Car_Grille"
		for wx in #(-1.42, 1.40) do
			for sd in #(-1, 1) do (
				local wy = sd * 0.80
				cyl wx (wy - 0.11) 0.33 0.33 0.22 mTire dir:[0,1,0] nm:"Car_Tire" sides:24
				cyl wx (if sd > 0 then wy + 0.11 else wy - 0.12) 0.33 0.21 0.01 mRim dir:[0,1,0] nm:"Car_Rim" sides:24
			)
		for sd in #(-1, 1) do (
			bx 2.25 (sd*0.55 - 0.18) 0.68 2.31 (sd*0.55 + 0.18) 0.80 mHead nm:"Car_Headlight"
			bx (-2.31) (sd*0.60 - 0.20) 0.74 (-2.25) (sd*0.60 + 0.20) 0.84 mTail nm:"Car_Taillight"
			spot 2.35 (sd*0.55) 0.74 14.0 (sd*0.55) 0.0 12000 6000 25 55 "Car_Headbeam"
		)
		local parts = for i = s0+1 to curNodes.count collect curNodes[i]
		local g = group parts name:nm
		curLayer.addNode g
		try (g.pivot = [0,0,0]) catch ()
		rotate g (eulerangles 0 0 heading)
		move g (p3 cx cy 0)
		g
	)

	-- ---------------- person (proxy figure ~1.75 m) ----------------
	fn person px py heading top female nm = (
		local s0 = curNodes.count
		local legM = if female then top else mPants
		for sd in #(-1, 1) do (
			cyl 0 (sd*0.09) 0.0 0.055 0.05 mShoes nm:"P_Shoe"
			cyl 0 (sd*0.09) 0.05 0.065 0.82 legM nm:"P_Leg"
		)
		if female do cyl 0 0 0.05 0.24 0.85 top nm:"P_Dress" sides:16
		local tor = Sphere radius:(mU 0.20) segs:16
		tor.scale = [0.65, 1.0, 1.55]
		tor.pos = p3 0 0 1.20
		reg tor top "P_Torso"
		for sd in #(-1, 1) do cyl 0 (sd*0.23) 0.82 0.045 0.58 top nm:"P_Arm"
		cyl 0 0 1.46 0.05 0.10 mSkin nm:"P_Neck"
		local hd = Sphere radius:(mU 0.105) segs:16
		hd.scale = [1.0, 0.85, 1.1]
		hd.pos = p3 0 0 1.64
		reg hd mSkin "P_Head"
		local hr = Sphere radius:(mU 0.11) segs:16 hemisphere:0.45
		hr.pos = p3 (-0.01) 0 1.65
		reg hr (if female then top else mHair) "P_Hair"
		local parts = for i = s0+1 to curNodes.count collect curNodes[i]
		local g = group parts name:nm
		curLayer.addNode g
		try (g.pivot = [0,0,0]) catch ()
		rotate g (eulerangles 0 0 heading)
		move g (p3 px py 0)
		g
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
		for hx in #(1.62, 1.72) do bx hx 0.02 0.90 (hx+0.03) 0.08 1.90 mAlu nm:"Door_Handle"
		bx 1.90 0.00 0 5.40 0.30 2.50 mStone nm:"Name_Wall"
		for gx in #(2.60, 3.30, 4.00, 4.70) do bx gx (-0.004) 0.05 (gx+0.015) 0.0 2.45 mGroove nm:"Wall_Groove"
		signText ("Villa 0" + (idx as string)) 4.40 2.05 0.0 0.30 0.012 mSign "Villa_Sign"
		slats 5.42 9.88 0.08 0.16 0.05 2.40 0.10 0.025 mWood "Car_Gate_Slat"
		bx 5.40 0.04 2.40 9.90 0.20 2.50 mAlu nm:"Gate_Head"
		bx 9.90 0.00 0 10.40 0.30 2.60 mStone nm:"Pillar_Shared"
		bx (-0.30) (-0.60) 2.95 5.60 1.20 3.20 mWhite nm:"Entrance_Canopy"
		bx 5.30 0.00 0 5.60 0.30 2.95 mWhite nm:"Canopy_Post"
		bx 9.95 0.30 0 10.35 plotD 2.40 mPlaster nm:"Side_Wall"

		-- ---------- landscape ----------
		bx (-0.10) (-1.00) 0 1.20 (-0.15) 0.55 mStone nm:"Planter"
		bx (-0.05) (-0.95) 0.55 1.15 (-0.20) 0.57 mSoil nm:"Planter_Soil"
		shrub 0.55 (-0.58) 0.57 0.42 mPlant
		ball 0.30 (-0.40) 1.55 0.30 mPlant nm:"Shrub"
		bx 2.00 (-0.45) 0 5.30 (-0.02) 0.12 mStone nm:"Flower_Bed"
		for i = 1 to 30 do (
			local m = case ((mod i 3) as integer) of (0: mFlowerP; 1: mFlowerY; default: mFlowerR)
			ball (random 2.10 5.20) (random (-0.40) (-0.08)) (random 0.15 0.24) (random 0.06 0.10) m nm:"Flower"
		)
		for i = 1 to 10 do ball (random 2.10 5.20) (random (-0.40) (-0.08)) 0.12 (random 0.08 0.12) mPlant nm:"Bed_Leaf"
		-- shrubs peeking over the wall + tree in the front yard
		shrub 3.00 1.20 1.80 0.55 mPlant
		shrub 8.80 1.40 1.90 0.60 mPlant

		-- ---------- house ----------
		bx 0.80 4.00 0 9.60 (plotD-1.0) gf mPlaster nm:"GF_Body"
		-- GF glazing: lit interior wall + glass in front
		bx 1.40 3.985 0.10 4.20 4.00 2.90 mInterior nm:"GF_Interior_Glow"
		bx 1.40 3.96 0.10 4.20 3.975 2.90 mGlass nm:"GF_Glass"
		bx 5.00 3.98 0.00 6.40 4.00 2.60 mWood nm:"GF_Entry_Door"
		bx 0.50 3.10 gf 9.60 (plotD-1.0) (gf+0.25) mWhite nm:"FF_Slab"
		bx 0.80 3.10 (gf-0.02) 9.60 3.18 gf mLED nm:"Cantilever_LED"
		bx 0.50 3.00 0 1.30 (plotD-1.0) (roofZ+1.20) mTaupeDk nm:"Side_Fin"
		-- recessed glass bay with a real lit room behind
		bx 1.30 4.00 (gf+0.25) 4.20 4.03 (roofZ-0.15) mGlass nm:"FF_Glass"
		for mx in #(1.30, 2.25, 3.20, 4.12) do bx mx 3.96 (gf+0.25) (mx+0.08) 4.04 (roofZ-0.15) mAlu nm:"Mullion"
		bx 1.30 3.96 (gf+2.20) 4.20 4.04 (gf+2.28) mAlu nm:"Transom"
		bx 2.70 4.15 (gf+0.30) 4.15 4.20 (roofZ-0.25) mCurtain nm:"Sheer_Curtain"
		bx 1.30 7.80 (gf+0.25) 4.20 8.00 (roofZ-0.15) mInterior nm:"Room_BackWall"
		bx 1.30 4.03 (roofZ-0.30) 4.20 8.00 (roofZ-0.15) mPlaster nm:"Room_Ceiling"
		bx 2.40 5.80 (roofZ-0.32) 3.10 6.20 (roofZ-0.30) mLED nm:"Room_Ceiling_Light"
		pointL 2.75 6.00 (roofZ-0.60) 250 3000 "Room_Light"
		bx 1.30 3.10 (gf+0.25) 4.20 3.14 (gf+1.25) mRail nm:"Balcony_Glass"
		bx 1.30 3.08 (gf+1.25) 4.20 3.16 (gf+1.29) mAlu nm:"Balcony_Rail"
		bx 1.30 4.00 (roofZ-0.15) 4.20 (plotD-1.0) roofZ mTaupe nm:"FF_Bay_Head"
		bx 1.30 8.00 (gf+0.25) 4.20 (plotD-1.0) (roofZ-0.15) mTaupe nm:"FF_Bay_Back"
		-- solid box with backlit teak louvers + panel joints
		bx 4.20 3.20 (gf+0.25) 9.60 (plotD-1.0) roofZ mTaupe nm:"FF_Box"
		bx 4.40 3.195 (gf+0.40) 6.40 3.20 (roofZ-0.10) mInterior nm:"Louver_Backlight"
		slats 4.40 6.40 3.02 3.19 (gf+0.40) (roofZ-0.10) 0.06 0.07 mWood "Louver"
		for gz in #(gf+1.40, gf+2.40) do bx 6.40 3.196 gz 9.60 3.20 (gz+0.015) mGroove nm:"Panel_Groove"
		for gx in #(7.50, 8.55) do bx gx 3.196 (gf+0.25) (gx+0.015) 3.20 roofZ mGroove nm:"Panel_Groove"
		bx 0.50 3.00 roofZ 9.60 (plotD-1.0) (roofZ+0.30) mTaupe nm:"Parapet"
		bx 1.60 6.50 roofZ 4.00 10.00 (roofZ+2.40) mWhite nm:"Roof_Stair_Box"
		bx 1.50 6.40 (roofZ+2.40) 4.10 10.10 (roofZ+2.55) mTaupe nm:"Roof_Stair_Cap"
		bx 2.30 6.48 (roofZ+0.90) 3.30 6.50 (roofZ+2.00) mInterior nm:"Stair_Window_Glow"

		-- ---------- night lights ----------
		-- pillar sconce (glow + up/down wash)
		bx 0.15 (-0.10) 2.30 0.35 0.0 2.70 mAlu nm:"Sconce_Body"
		bx 0.18 (-0.105) 2.32 0.32 (-0.10) 2.68 mLamp nm:"Sconce_Glow"
		spot 0.25 (-0.15) 2.30 0.25 (-0.20) 0.0 350 3000 40 90 "Sconce_Down"
		spot 0.25 (-0.15) 2.70 0.25 (-0.20) 4.0 250 3000 30 80 "Sconce_Up"
		bx 10.05 (-0.10) 2.10 10.25 0.0 2.40 mAlu nm:"Sconce_Body"
		bx 10.08 (-0.105) 2.12 10.22 (-0.10) 2.38 mLamp nm:"Sconce_Glow"
		spot 10.15 (-0.15) 2.10 10.15 (-0.20) 0.0 300 3000 40 90 "Sconce_Down"
		-- canopy LED strip + downlights
		bx (-0.25) (-0.55) 2.93 5.55 (-0.50) 2.95 mLED nm:"Canopy_LED"
		spot 1.20 (-0.20) 2.90 1.20 (-0.20) 0.0 450 3000 50 100 "Canopy_Downlight"
		spot 3.60 (-0.20) 2.90 3.60 (-0.20) 0.0 450 3000 50 100 "Canopy_Downlight"
		-- uplights washing the name wall
		spot 2.80 (-0.35) 0.10 2.80 0.0 2.50 220 3000 20 50 "Wall_Uplight"
		spot 4.60 (-0.35) 0.10 4.60 0.0 2.50 220 3000 20 50 "Wall_Uplight"
		-- uplight on the side fin + soft light behind the gate
		spot 0.90 2.70 0.10 0.90 3.00 (roofZ+1.0) 400 3000 15 40 "Fin_Uplight"
		pointL 6.00 2.00 2.20 120 3000 "Yard_Glow"
	)

	-- ==================================================================
	--  RUN
	-- ==================================================================
	seed 11
	disableSceneRedraw()
	try (
		with undo off (
			-- villas
			useLayer "Villas_Row"
			for i = 1 to nVillas do (
				curNodes = #()
				buildVilla i
				move curNodes (p3 ((i-1)*plotW) 0 0)
				local g = group curNodes name:("Villa_0" + (i as string))
				curLayer.addNode g
			)

			-- street
			useLayer "Villas_Street"
			curNodes = #()
			local x0 = -25.0
			local x1 = nVillas*plotW + 15.0
			bx x0 (-14.0) (-0.02) x1 (-2.0) 0.0 mAsphalt nm:"Road"
			bx x0 (-2.0) 0 x1 (-1.75) 0.15 mCurb nm:"Curb"
			bx x0 (-1.75) 0 x1 0.0 0.12 mWalk nm:"Sidewalk"
			bx x0 (-14.25) 0 x1 (-14.0) 0.15 mCurb nm:"Curb_Far"
			local x = x0
			while x < x1 do (
				bx x (-8.08) 0.0 (x+3.0) (-7.92) 0.004 mMark nm:"Lane_Mark"
				bx x (-5.08) 0.0 (x+3.0) (-4.92) 0.004 mMark nm:"Lane_Mark"
				x += 6.0
			)
			bx x0 (-2.50) 0.0 x1 (-2.38) 0.004 mMark nm:"Edge_Line"
			bx x0 (-13.60) 0.0 x1 (-13.48) 0.004 mMark nm:"Edge_Line"
			local gp = Plane length:(mU 80) width:(mU (x1-x0)) lengthsegs:1 widthsegs:1
			gp.pos = p3 ((x0+x1)/2.0) 26.0 (-0.03)
			reg gp mPlant "Ground_Behind"
			local gp2 = Plane length:(mU 30) width:(mU (x1-x0)) lengthsegs:1 widthsegs:1
			gp2.pos = p3 ((x0+x1)/2.0) (-29.0) (-0.03)
			reg gp2 mWalk "Ground_Front"
			palm (-9.0) (-1.0) 8.5
			palm (-5.5) 1.5 6.5
			palm (-12.0) 2.5 7.5
			palm (-16.0) (-0.8) 9.0
			for sx in #(-3.0, 18.0, 39.0) do streetLight sx (-1.5)

			-- night sky dome
			local dome = Sphere radius:(mU 400) segs:32
			dome.pos = p3 25 0 0
			addModifier dome (Normalmodifier flip:true)
			reg dome mSky "Night_Sky_Dome"
			try (dome.castShadows = false; dome.receiveShadows = false) catch ()
			try (backgroundColor = color 10 14 28) catch ()

			-- cars
			useLayer "Villas_Cars"
			curNodes = #()
			car 1.5 (-10.0) 180 mCarGold "Car_01_Champagne"
			curNodes = #()
			car 24.0 (-6.5) 0 mCarGrey "Car_02_Graphite"

			-- people
			useLayer "Villas_People"
			curNodes = #()
			person 12.0 (-0.9) 180 mShirtW false "Person_01_Man"
			curNodes = #()
			person 12.6 (-1.1) 175 mAbaya true "Person_02_Woman"
			curNodes = #()
			person 33.6 (-0.6) 95 mShirtB false "Person_03_Man_AtGate"
			curNodes = #()
			person (-2.5) (-0.9) 10 mAbaya true "Person_04_Woman"

			-- physical camera, like the street render
			useLayer "Villas_Camera"
			curNodes = #()
			local tgt = Targetobject pos:(p3 22.0 4.0 3.5)
			local cam = undefined
			try (cam = Physical targeted:true pos:(p3 (-7.0) (-13.0) 1.6) target:tgt) catch ()
			if cam == undefined do cam = Targetcamera fov:62 pos:(p3 (-7.0) (-13.0) 1.6) target:tgt
			try (cam.specify_fov = false; cam.focal_length_mm = 24.0) catch ()
			try (cam.exposure_gain_type = 1; cam.exposure_value = 3.5) catch ()
			try (cam.vignetting_enabled = true; cam.vignetting_amount = 0.6) catch ()
			cam.name = uniqueName "Cam_Villas_Night"
			tgt.name = cam.name + ".Target"
			curLayer.addNode cam
			curLayer.addNode tgt
			try (SceneExposureControl.exposureControl = Physical_Camera_Exposure_Control()) catch ()
			try (viewport.setCamera cam) catch ()

			-- render setup
			try (renderers.current = Arnold()) catch ()
			renderWidth = 1920
			renderHeight = 932
		)
		format "Night villas scene built: % villas, cars, people, lights, camera.\n" nVillas
	) catch (
		format "Villas night script error: %\n" (getCurrentException())
	)
	enableSceneRedraw()
	completeRedraw()
)

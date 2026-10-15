-- ======================================================================
--  Booth_Models.ms   (3ds Max 2024 - Physical Materials - real meters)
--
--  Builds two booth models side by side:
--    A) Booth_A_White  : the white arched booth from the workshop photo
--    B) Booth_B_Merged : same footprint/height + ideas and materials from
--                        the black container cafe (corrugated black steel,
--                        wood slats, warm LED lines, planters, roof terrace,
--                        pendant lamps, COFFEE sign, bar stools)
--
--  Run:  Scripting > Run Script...  (or drag this file into a viewport)
--  Units: works with any System Unit - every size below is in meters.
-- ======================================================================
(
	-- ---------------- main dimensions (meters) ----------------
	local Wd  = 3.00   -- front width
	local Dp  = 4.00   -- depth
	local zb  = 0.15   -- steel skid height = finished floor level
	local Hw  = 3.60   -- top of walls
	local Hc  = 4.20   -- top of cornice (total booth height)
	local tw  = 0.10   -- wall thickness (steel studs + cement board)
	local rc  = 0.30   -- plan corner radius
	local ov  = 0.04   -- cornice overhang
	local xL  = 0.45   -- arch opening left edge
	local xR  = 2.55   -- arch opening right edge  (opening = 2.10 m)
	local zs  = 2.40   -- arch spring height        (crown = 3.45 m)
	local zm  = 2.20   -- mezzanine underside
	local tm  = 0.12   -- mezzanine thickness

	local U1m = units.decodeValue "1m"
	local curLayer = undefined
	local curNodes = #()

	-- ---------------- helpers ----------------
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
		local mt = mkMat nm (color 190 205 210) 0.02 0.0
		try (mt.transparency = 1.0; mt.trans_color = (color 235 245 248); mt.trans_ior = 1.52) catch ()
		mt
	)

	-- materials
	local mWhite  = mkMat "Booth_CementBoard_White" (color 222 218 208) 0.75 0.0
	local mGroove = mkMat "Booth_Groove_Grey"       (color 120 118 112) 0.80 0.0
	local mSteel  = mkMat "Booth_Steel_Black"       (color 22 22 22)    0.35 0.85
	local mAlu    = mkMat "Booth_Aluminium"         (color 160 160 158) 0.30 0.90
	local mFloor  = mkMat "Booth_Floor_Grey"        (color 140 140 135) 0.70 0.0
	local mGlass  = mkGlass "Booth_Glass"
	local mCorr   = mkMat "Cafe_Corrugated_Black"   (color 30 30 32)    0.45 0.60
	local mWood   = mkMat "Cafe_Wood_Oak"           (color 176 124 78)  0.55 0.0
	local mWoodDk = mkMat "Cafe_Wood_Dark"          (color 105 70 42)   0.50 0.0
	local mBrass  = mkMat "Cafe_Brass"              (color 181 140 70)  0.30 0.90
	local mChalk  = mkMat "Cafe_MenuBoard"          (color 35 38 36)    0.85 0.0
	local mPlant  = mkMat "Cafe_Plant_Green"        (color 52 92 40)    0.70 0.0
	local mPot    = mkMat "Cafe_Pot"                (color 60 60 60)    0.60 0.0
	local mLED    = mkEmit "Cafe_LED_Warm"          (color 255 186 110) 2000.0
	local mGround = mkMat "Ground_Concrete"         (color 120 120 118) 0.85 0.0

	-- box from two corners (meters)
	fn bx x0 y0 z0 x1 y1 z1 mat nm:"Part" = (
		local o = Box length:(mU (abs (y1-y0))) width:(mU (abs (x1-x0))) height:(mU (abs (z1-z0)))
		o.pos = p3 ((x0+x1)/2.0) ((y0+y1)/2.0) (amin z0 z1)
		reg o mat nm
	)

	-- cylinder; base at (x,y,z), grows along dir
	fn cyl x y z r h mat dir:[0,0,1] nm:"Cyl" sides:24 = (
		local o = Cylinder radius:(mU r) height:(mU h) sides:sides heightsegs:1
		o.dir = dir
		o.pos = p3 x y z
		reg o mat nm
	)

	fn ball x y z r mat nm:"Leaf" = (
		local o = Sphere radius:(mU r) segs:10
		o.pos = p3 x y z
		reg o mat nm
	)

	fn addPoly sh pts = (
		local s = addNewSpline sh
		for pp in pts do addKnot sh s #corner #line (p3 pp.x pp.y 0)
		close sh s
		s
	)

	fn roundRectPts x0 y0 x1 y1 r n:6 = (
		local pts = #()
		local cs = #([x1-r, y0+r, -90], [x1-r, y1-r, 0], [x0+r, y1-r, 90], [x0+r, y0+r, 180])
		for c in cs do
			for i = 0 to n do (
				local a = c.z + 90.0*i/n
				append pts [c.x + r*(cos a), c.y + r*(sin a)]
			)
		pts
	)

	-- horizontal profile (with optional hole) extruded upward
	fn planRing outerPts innerPts z0 h mat nm = (
		local sh = SplineShape()
		addPoly sh outerPts
		if innerPts != undefined do addPoly sh innerPts
		updateShape sh
		addModifier sh (Extrude amount:(mU h) capStart:true capEnd:true)
		sh.pos = p3 0 0 z0
		reg sh mat nm
	)

	-- quarter-round wall corner
	fn cornerSector cx cy r t a0 z0 h mat nm n:8 = (
		local pts = #()
		for i = 0 to n do (local a = a0 + 90.0*i/n; append pts [cx + r*(cos a), cy + r*(sin a)])
		for i = n to 0 by -1 do (local a = a0 + 90.0*i/n; append pts [cx + (r-t)*(cos a), cy + (r-t)*(sin a)])
		planRing pts undefined z0 h mat nm
	)

	-- a profile drawn as (x , height) and stood up facing the front (-Y)
	fn finishFront sh yFront thick zBase mat nm = (
		updateShape sh
		addModifier sh (Extrude amount:(mU thick) capStart:true capEnd:true)
		sh.transform = matrix3 [1,0,0] [0,0,1] [0,-1,0] (p3 0 (yFront+thick) zBase)
		reg sh mat nm
	)

	-- wall infill above the arch
	fn addTympanum sh xa xb zsr hr = (
		local r = (xb - xa)/2.0
		local cx = (xa + xb)/2.0
		local k = 0.5523*r
		local s = addNewSpline sh
		addKnot sh s #bezierCorner #curve (p3 xa zsr 0) (p3 xa (zsr+k) 0) (p3 xa zsr 0)
		addKnot sh s #corner #line (p3 xa hr 0)
		addKnot sh s #corner #line (p3 xb hr 0)
		addKnot sh s #bezierCorner #curve (p3 xb zsr 0) (p3 xb zsr 0) (p3 xb (zsr+k) 0)
		addKnot sh s #bezier #curve (p3 cx (zsr+r) 0) (p3 (cx+k) (zsr+r) 0) (p3 (cx-k) (zsr+r) 0)
		close sh s
		s
	)

	-- U-shaped arch band of width f around the opening xa..xb
	fn addArchBand sh xa xb zsr f = (
		local r = (xb - xa)/2.0
		local cx = (xa + xb)/2.0
		local ro = r + f
		local k = 0.5523*r
		local ko = 0.5523*ro
		local s = addNewSpline sh
		addKnot sh s #corner #line (p3 (xa-f) 0 0)
		addKnot sh s #bezierCorner #curve (p3 (xa-f) zsr 0) (p3 (xa-f) zsr 0) (p3 (xa-f) (zsr+ko) 0)
		addKnot sh s #bezier #curve (p3 cx (zsr+ro) 0) (p3 (cx-ko) (zsr+ro) 0) (p3 (cx+ko) (zsr+ro) 0)
		addKnot sh s #bezierCorner #curve (p3 (xb+f) zsr 0) (p3 (xb+f) (zsr+ko) 0) (p3 (xb+f) zsr 0)
		addKnot sh s #corner #line (p3 (xb+f) 0 0)
		addKnot sh s #corner #line (p3 xb 0 0)
		addKnot sh s #bezierCorner #curve (p3 xb zsr 0) (p3 xb zsr 0) (p3 xb (zsr+k) 0)
		addKnot sh s #bezier #curve (p3 cx (zsr+r) 0) (p3 (cx+k) (zsr+r) 0) (p3 (cx-k) (zsr+r) 0)
		addKnot sh s #bezierCorner #curve (p3 xa zsr 0) (p3 xa (zsr+k) 0) (p3 xa zsr 0)
		addKnot sh s #corner #line (p3 xa 0 0)
		close sh s
		s
	)

	-- renderable steel strip along a 3D path
	fn tubeLine pts thick mat nm = (
		local sh = SplineShape()
		local s = addNewSpline sh
		for pp in pts do addKnot sh s #smooth #curve (p3 pp.x pp.y pp.z)
		updateShape sh
		try (sh.render_renderable = true; sh.render_displayRenderMesh = true; sh.render_thickness = mU thick; sh.render_sides = 8) catch ()
		reg sh mat nm
	)

	fn signText str x z yFront sz thick mat nm = (
		local t = text text:str size:(mU sz) font:"Arial Black"
		addModifier t (Extrude amount:(mU thick) capStart:true capEnd:true)
		t.transform = matrix3 [1,0,0] [0,0,1] [0,-1,0] [0,0,0]
		CenterPivot t
		t.pos = p3 x (yFront - thick/2.0) z
		reg t mat nm
	)

	fn stool x y = (
		cyl x y 0 0.18 0.02 mSteel nm:"Stool_Base"
		cyl x y 0.02 0.025 0.76 mSteel nm:"Stool_Post"
		cyl x y 0.78 0.19 0.05 mWood nm:"Stool_Seat"
	)

	-- ==================================================================
	--  BOOTH
	-- ==================================================================
	fn buildBooth isB = (
		local wallMat = if isB then mCorr else mWhite
		local gm = if isB then mBrass else mGroove
		local innerRect = #([tw,tw], [Wd-tw,tw], [Wd-tw,Dp-tw], [tw,Dp-tw])
		local sh

		-- steel skid + floor
		planRing (roundRectPts 0.02 0.02 (Wd-0.02) (Dp-0.02) (rc-0.02)) undefined 0 zb mSteel "Skid"
		bx tw tw zb (Wd-tw) (Dp-tw) (zb+0.02) (if isB then mWood else mFloor) nm:"Floor"

		-- rounded corners (front corners stay white in both models)
		cornerSector rc rc rc tw 180 zb (Hw-zb) mWhite "Corner_FL"
		cornerSector (Wd-rc) rc rc tw 270 zb (Hw-zb) mWhite "Corner_FR"
		cornerSector (Wd-rc) (Dp-rc) rc tw 0 zb (Hw-zb) wallMat "Corner_BR"
		cornerSector rc (Dp-rc) rc tw 90 zb (Hw-zb) wallMat "Corner_BL"

		-- front pilasters + wall above the arch
		bx rc 0 zb xL tw Hw mWhite nm:"Front_Pilaster_L"
		bx xR 0 zb (Wd-rc) tw Hw mWhite nm:"Front_Pilaster_R"
		sh = SplineShape()
		addTympanum sh xL xR (zs-zb) (Hw-zb)
		finishFront sh 0 tw zb mWhite "Front_Arch_Infill"

		-- black steel arch frame (8 cm face, 16 cm deep)
		sh = SplineShape()
		addArchBand sh xL xR (zs-zb) 0.08
		finishFront sh (-0.03) 0.16 zb mSteel "Arch_Frame"

		-- fluted grooves on the front corners
		for a in #(195, 215, 235, 255) do (
			cyl (rc + (rc+0.002)*(cos a)) (rc + (rc+0.002)*(sin a)) (zb+0.03) 0.006 (Hw-zb-0.06) gm nm:"Groove" sides:6
			cyl ((Wd-rc) - (rc+0.002)*(cos a)) (rc + (rc+0.002)*(sin a)) (zb+0.03) 0.006 (Hw-zb-0.06) gm nm:"Groove" sides:6
		)
		for y in #(0.36, 0.43) do (
			cyl (-0.002) y (zb+0.03) 0.006 (Hw-zb-0.06) gm nm:"Groove" sides:6
			cyl (Wd+0.002) y (zb+0.03) 0.006 (Hw-zb-0.06) gm nm:"Groove" sides:6
		)

		-- left wall with window opening
		local wy0 = 0.55
		local wy1 = 1.25
		local wz0 = 1.00
		local wz1 = 2.55
		bx 0 rc zb tw wy0 Hw wallMat nm:"Wall_L"
		bx 0 wy1 zb tw (Dp-rc) Hw wallMat nm:"Wall_L"
		bx 0 wy0 zb tw wy1 wz0 wallMat nm:"Wall_L"
		bx 0 wy0 wz1 tw wy1 Hw wallMat nm:"Wall_L"
		local fm = if isB then mWood else mSteel
		bx (-0.02) (wy0-0.05) (wz0-0.05) (tw+0.01) wy0 (wz1+0.05) fm nm:"Window_Frame"
		bx (-0.02) wy1 (wz0-0.05) (tw+0.01) (wy1+0.05) (wz1+0.05) fm nm:"Window_Frame"
		bx (-0.02) wy0 (wz0-0.05) (tw+0.01) wy1 wz0 fm nm:"Window_Frame"
		bx (-0.02) wy0 wz1 (tw+0.01) wy1 (wz1+0.05) fm nm:"Window_Frame"
		bx 0.045 wy0 wz0 0.055 wy1 wz1 mGlass nm:"Window_Glass"

		-- right wall with service door
		local dy0 = 2.40
		local dy1 = 3.30
		local dz1 = zb + 2.10
		bx (Wd-tw) rc zb Wd dy0 Hw wallMat nm:"Wall_R"
		bx (Wd-tw) dy1 zb Wd (Dp-rc) Hw wallMat nm:"Wall_R"
		bx (Wd-tw) dy0 dz1 Wd dy1 Hw wallMat nm:"Wall_R"
		bx (Wd-0.01) (dy0-0.05) zb (Wd+0.02) dy0 (dz1+0.05) mSteel nm:"Door_Frame"
		bx (Wd-0.01) dy1 zb (Wd+0.02) (dy1+0.05) (dz1+0.05) mSteel nm:"Door_Frame"
		bx (Wd-0.01) dy0 dz1 (Wd+0.02) dy1 (dz1+0.05) mSteel nm:"Door_Frame"
		bx (Wd-0.06) dy0 zb (Wd-0.02) dy1 dz1 (if isB then mCorr else mAlu) nm:"Door_Leaf"

		-- back wall
		bx rc (Dp-tw) zb (Wd-rc) Dp Hw wallMat nm:"Wall_Back"

		-- cornice band with rounded corners + shadow gap / LED line under it
		planRing (roundRectPts (-ov) (-ov) (Wd+ov) (Dp+ov) (rc+ov)) innerRect (Hw+0.012) (Hc-Hw-0.012) mWhite "Cornice"
		if isB then
			planRing (roundRectPts (-0.015) (-0.015) (Wd+0.015) (Dp+0.015) (rc+0.015)) innerRect Hw 0.012 mLED "Cornice_LED"
		else
			planRing (roundRectPts (-0.004) (-0.004) (Wd+0.004) (Dp+0.004) (rc+0.004)) innerRect Hw 0.012 mGroove "Cornice_Reveal"
		bx tw tw (Hc-0.14) (Wd-tw) (Dp-tw) (Hc-0.04) mWhite nm:"Roof_Slab"

		-- steel mezzanine (visible through the arch)
		bx tw 0.55 zm (Wd-tw) (Dp-tw) (zm+tm) mSteel nm:"Mezzanine_Deck"
		bx tw 0.50 (zm-0.10) (Wd-tw) 0.55 (zm+tm) mSteel nm:"Mezzanine_Beam"
		for x in #(0.60, 1.20, 1.80, 2.40) do
			bx x (Dp-tw-0.06) (zm+tm) (x+0.05) (Dp-tw) Hw mSteel nm:"Upper_Stud"

		-- service counter behind the arch + back counter
		bx (xL+0.05) 0.15 zb (xR-0.05) 0.70 (zb+1.00) (if isB then mSteel else mWhite) nm:"Counter"
		bx (xL+0.02) 0.08 (zb+1.00) (xR-0.02) 0.75 (zb+1.04) (if isB then mWoodDk else mWhite) nm:"Counter_Top"
		bx tw (Dp-tw-0.60) zb (Wd-tw-0.10) (Dp-tw) (zb+0.90) (if isB then mWood else mWhite) nm:"Back_Counter"

		if not isB then (
			-- ===== A only: details from the workshop booth =====
			-- roller-shutter box above the side window
			cyl (-0.12) (wy0-0.08) (wz1+0.17) 0.11 (wy1-wy0+0.16) mAlu dir:[0,1,0] nm:"Shutter_Box"
			-- black steel swoop line on the left side
			tubeLine #([-0.012,1.30,3.58], [-0.012,1.75,3.45], [-0.012,2.35,3.05], [-0.012,2.65,2.50], [-0.012,2.70,1.80], [-0.012,2.70,0.17]) 0.05 mSteel "Side_Swoop"
		) else (
			-- ===== B only: container-cafe ideas =====
			-- corrugated container ribs
			for y = (rc+0.03) to (dy0-0.10) by 0.10 do bx Wd y (zb+0.02) (Wd+0.02) (y+0.035) (Hw-0.02) mCorr nm:"Rib"
			for y = (dy1+0.08) to (Dp-rc-0.06) by 0.10 do bx Wd y (zb+0.02) (Wd+0.02) (y+0.035) (Hw-0.02) mCorr nm:"Rib"
			for x = (rc+0.03) to (Wd-rc-0.06) by 0.10 do bx x Dp (zb+0.02) (x+0.035) (Dp+0.02) (Hw-0.02) mCorr nm:"Rib"
			for y = (wy1+0.08) to (Dp-rc-0.06) by 0.10 do bx (-0.02) y (zb+0.02) 0 (y+0.035) (Hw-0.02) mCorr nm:"Rib"

			-- warm LED on the arch frame face
			sh = SplineShape()
			addArchBand sh (xL+0.02) (xR-0.02) (zs-zb) 0.02
			finishFront sh (-0.045) 0.015 zb mLED "Arch_LED"

			-- wood-slat counter front + LED under the top
			for z = (zb+0.10) to (zb+0.92) by 0.10 do bx (xL+0.05) 0.12 z (xR-0.05) 0.15 (z+0.08) mWood nm:"Counter_Slat"
			bx (xL+0.05) 0.10 zb (xR-0.05) 0.15 (zb+0.08) mSteel nm:"Counter_Kick"
			bx (xL+0.05) 0.085 (zb+0.985) (xR-0.05) 0.10 (zb+1.00) mLED nm:"Counter_LED"

			-- 3 pendant lamps under the mezzanine
			for x in #(0.95, 1.50, 2.05) do (
				cyl x 0.62 1.98 0.004 (zm-1.98) mSteel nm:"Pendant_Cord" sides:6
				local c = Cone radius1:(mU 0.12) radius2:(mU 0.035) height:(mU 0.14) sides:24
				c.pos = p3 x 0.62 1.84
				reg c mSteel "Pendant_Shade"
				ball x 0.62 1.835 0.04 mLED nm:"Pendant_Bulb"
			)

			-- menu board on the back wall
			bx 0.75 (Dp-tw-0.04) (zb+1.25) 2.25 (Dp-tw-0.02) (zb+1.95) mWoodDk nm:"Menu_Frame"
			bx 0.80 (Dp-tw-0.05) (zb+1.30) 2.20 (Dp-tw-0.04) (zb+1.90) mChalk nm:"Menu_Board"

			-- planter with trailing plants on the mezzanine edge
			bx 0.50 0.56 (zm+tm) 2.50 0.86 (zm+tm+0.30) mSteel nm:"Planter_Mezz"
			for i = 0 to 14 do (
				local x = 0.57 + i*0.133
				ball x (random 0.62 0.80) (zm+tm+0.33) (random 0.07 0.11) mPlant
				if (mod i 2) == 0 do cyl x 0.49 (zm+tm+0.30-(random 0.25 0.60)) 0.008 0.6 mPlant nm:"Vine" sides:5
			)

			-- side window: wood ledge + small steel awning
			bx (-0.30) wy0 (wz0-0.04) 0 wy1 wz0 mWood nm:"Window_Ledge"
			bx (-0.35) (wy0-0.10) (wz1+0.10) 0 (wy1+0.10) (wz1+0.14) mSteel nm:"Window_Awning"

			-- vertical green wall on the left side
			bx (-0.04) 1.55 0.90 (-0.005) 3.45 3.00 mSteel nm:"GreenWall_Frame"
			for y = 1.62 to 3.40 by 0.11 do
				for z = 0.97 to 2.95 by 0.11 do
					ball (random (-0.08) (-0.05)) (y + random (-0.02) 0.02) (z + random (-0.02) 0.02) (random 0.06 0.085) mPlant

			-- COFFEE sign on the cornice
			signText "COFFEE" (Wd/2.0) (Hw+0.30) (-ov) 0.30 0.025 mLED "Sign_COFFEE"

			-- roof terrace: deck, railing, planters, lamp
			for x = tw to (Wd-tw-0.14) by 0.15 do bx x tw (Hc-0.04) (x+0.13) (Dp-tw) (Hc-0.02) mWood nm:"Roof_Deck"
			for h in #(0.50, 0.97) do (
				bx 0.08 0.08 (Hc+h) (Wd-0.08) 0.12 (Hc+h+0.03) mSteel nm:"Rail"
				bx 0.08 (Dp-0.12) (Hc+h) (Wd-0.08) (Dp-0.08) (Hc+h+0.03) mSteel nm:"Rail"
				bx 0.08 0.08 (Hc+h) 0.12 (Dp-0.08) (Hc+h+0.03) mSteel nm:"Rail"
				bx (Wd-0.12) 0.08 (Hc+h) (Wd-0.08) (Dp-0.08) (Hc+h+0.03) mSteel nm:"Rail"
			)
			for x in #(0.08, 1.00, 1.96, Wd-0.12) do (
				bx x 0.08 Hc (x+0.04) 0.12 (Hc+1.0) mSteel nm:"Rail_Post"
				bx x (Dp-0.12) Hc (x+0.04) (Dp-0.08) (Hc+1.0) mSteel nm:"Rail_Post"
			)
			for y in #(1.05, 2.00, 2.95) do (
				bx 0.08 y Hc 0.12 (y+0.04) (Hc+1.0) mSteel nm:"Rail_Post"
				bx (Wd-0.12) y Hc (Wd-0.08) (y+0.04) (Hc+1.0) mSteel nm:"Rail_Post"
			)
			bx 0.15 0.15 (Hc-0.02) (Wd-0.15) 0.55 (Hc+0.45) mSteel nm:"Planter_Roof"
			bx 0.15 0.55 (Hc-0.02) 0.55 2.60 (Hc+0.45) mSteel nm:"Planter_Roof"
			for i = 1 to 40 do (
				if i <= 24 then
					ball (random 0.25 (Wd-0.25)) (random 0.22 0.48) (Hc+0.50+(random 0.0 0.25)) (random 0.10 0.18) mPlant
				else
					ball (random 0.22 0.48) (random 0.60 2.50) (Hc+0.50+(random 0.0 0.25)) (random 0.10 0.18) mPlant
			)
			cyl (Wd-0.25) (Dp-0.25) (Hc-0.02) 0.03 2.30 mSteel nm:"Lamp_Post"
			cyl (Wd-0.25) (Dp-0.25) (Hc+2.25) 0.02 0.90 mSteel dir:[-0.7071,-0.7071,0] nm:"Lamp_Arm"
			local lc = Cone radius1:(mU 0.16) radius2:(mU 0.05) height:(mU 0.18) sides:24
			lc.pos = p3 (Wd-0.89) (Dp-0.89) (Hc+2.02)
			reg lc mSteel "Lamp_Shade"
			ball (Wd-0.89) (Dp-0.89) (Hc+2.01) 0.05 mLED nm:"Lamp_Bulb"

			-- outside: bar stools + potted tree (furniture, outside the booth)
			stool 0.95 (-0.50)
			stool 2.05 (-0.50)
			cyl (-0.70) 0.70 0 0.25 0.55 mPot nm:"Pot"
			cyl (-0.70) 0.70 0.55 0.03 0.80 mWoodDk nm:"Tree_Trunk" sides:8
			for i = 1 to 9 do
				ball ((-0.70) + random (-0.25) 0.25) (0.70 + random (-0.25) 0.25) (random 1.30 1.95) (random 0.16 0.24) mPlant
		)
	)

	fn buildModel nm isB offsetX = (
		curLayer = LayerManager.getLayerFromName nm
		if curLayer == undefined do curLayer = LayerManager.newLayerFromName nm
		curNodes = #()
		buildBooth isB
		move curNodes (p3 offsetX 0 0)
		local g = group curNodes name:nm
		curLayer.addNode g
		local tgt = Targetobject pos:(p3 (offsetX + Wd/2.0) (Dp/2.0) 2.0)
		local cam = Targetcamera fov:50 pos:(p3 (offsetX - 3.2) (-6.5) 2.4) target:tgt
		cam.name = uniqueName ("Cam_" + nm)
		tgt.name = cam.name + ".Target"
		curLayer.addNode cam
		curLayer.addNode tgt
		g
	)

	-- ==================================================================
	--  RUN
	-- ==================================================================
	seed 7
	disableSceneRedraw()
	try (
		with undo off (
			buildModel "Booth_A_White" false 0.0
			buildModel "Booth_B_Merged" true 7.0
			curLayer = LayerManager.getLayerFromName "Booth_Ground"
			if curLayer == undefined do curLayer = LayerManager.newLayerFromName "Booth_Ground"
			local gp = Plane length:(mU 30) width:(mU 30) lengthsegs:1 widthsegs:1
			gp.pos = p3 5.0 2.0 0
			reg gp mGround "Ground"
		)
		format "Booth models built: A at X=0 m, B at X=7 m. Footprint % x % m, height % m.\n" Wd Dp Hc
	) catch (
		format "Booth script error: %\n" (getCurrentException())
	)
	enableSceneRedraw()
	try (max zoomext sel all) catch ()
	completeRedraw()
)

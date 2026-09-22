-- restat remake by haya
-- somewhat based on hostmod restat

local FRACUNIT = FRACUNIT
local MFE_VERTICALFLIP = MFE_VERTICALFLIP
local V_VFLIP = V_VFLIP
local V_60TRANS = V_60TRANS
local V_HUDTRANS = V_HUDTRANS

local restat_enabled = CV_RegisterVar({
	name = "mogi_restat",
	defaultvalue = "On",
	flags = CV_NETVAR,
	possiblevalue = CV_OnOff,
	description = "Allow players to change their stats."
})
local restat_notify = CV_RegisterVar({
	name = "mogi_restat_notify",
	defaultvalue = "On",
	flags = CV_NETVAR,
	possiblevalue = CV_OnOff,
	description = "Notify players when a player changes their stats."
})
local restat_limiter = CV_RegisterVar({
	name = "mogi_restat_limiter",
	defaultvalue = "On",
	flags = CV_NETVAR,
	possiblevalue = CV_OnOff,
	description = "Whether to limit the stats provided to max out at 9."
})
local restat_nametags = CV_RegisterVar({
	name = "mogi_restat_nametags",
	defaultvalue = "On",
	possiblevalue = CV_OnOff,
	description = "Display stats on nametags."
})
local restat_moddedstats = CV_RegisterVar({
	name = "mogi_restat_moddedstats",
	defaultvalue = "On",
	possiblevalue = CV_OnOff,
	description = "Always display stats for modded characters, even if they aren't restatted."
})

local fmt = string.format

local function initstats(p)
	if not p.mogi_restat then
		p.mogi_restat = {
			speed = 0,
			weight = 0,
			pendingspeed = 0,
			pendingweight = 0,
			random = false,
			skin = ""
		}
	end
end

local function statstring(spd, wt)
	return fmt("%d spd, %d wt", spd, wt)
end

local function updatestats(p)
	initstats(p)
	
	local restat = p.mogi_restat
	
	if restat.random then
		restat.pendingspeed = P_RandomRange(1, 9)
		restat.pendingweight = P_RandomRange(1, 9)
		restat.skin = ""
	end
	
	if restat.pendingspeed ~= restat.speed or restat.pendingweight ~= restat.weight then
		restat.speed = restat.pendingspeed
		restat.weight = restat.pendingweight
		if not restat.speed then
			p.kartspeed = skins[p.mo.skin].kartspeed
			p.kartweight = skins[p.mo.skin].kartweight
		end
		if restat_notify.value then
			if restat.speed then
				if restat.skin ~= "" then
					chatprint(fmt("\x86* %s is now using \x82%s (%s)\x86 stats.", p.name, restat.skin, statstring(restat.speed, restat.weight)), true)
				else
					chatprint(fmt("\x86* %s is now \x82%s\x86.", p.name, statstring(restat.speed, restat.weight)), true)
				end
			else
				chatprint(fmt("\x86* %s returned to default stats.", p.name), true)
			end
		end
	end
end

local function findskin(skinname)
	-- Find skin by their id
	for skin in skins.iterate do
		if skinname == skin.name:lower() then
			return skin
		end
	end
	-- Find skin by their display name
	for skin in skins.iterate do
		if skinname == skin.realname:lower() then
			return skin
		end
	end
	return nil
end

local function usage(p, str)
	CONS_Printf(p, str)
	CONS_Printf(p, "\x86".."Try something like \x87restat 6 7\x86, \x87restat chao\x86, or \x87restat "..(p.mogi_restat.pendingspeed and "off" or "random"))
end

COM_AddCommand("restat", function(p, ...)
	if not restat_enabled.value then
		CONS_Printf(p, "\x8A".."This function has been disabled by the server host.")
		return
	end
	
	local args = {...}
	local nspeed, nweight = tonumber(args[1]), tonumber(args[2])
	local cmd = args[1]
	
	initstats(p)
	local restat = p.mogi_restat
	
	if not cmd then
		local speed = restat.pendingspeed or p.kartspeed
		local weight = restat.pendingweight or p.kartweight
		usage(p, fmt("\x86".."You are currently using \x82%s\x86 stats.", statstring(speed, weight)))
		return
	end
	cmd = cmd:lower()
	if cmd == "random" then
		restat.random = true
		restat.skin = ""
		S_StartSound(nil, sfx_3db06, p)
		CONS_Printf(p, "\x86".."Random restat \x82on\x86. Your stats will be randomized every round.")
		CONS_Printf(p, "\x86".."Use \x87restat off\x86 or change into other stats/skins to turn it off.")
		return
	elseif cmd == "randomonce" then
		nspeed = P_RandomRange(1, 9)
		nweight = P_RandomRange(1, 9)
	elseif cmd == "default" or cmd == "off" or cmd == "reset" or cmd == "pleaseletmedisablethisplsibegyou" then
		restat.pendingspeed = 0
		restat.pendingweight = 0
		restat.random = false
		restat.skin = ""
		S_StartSound(nil, sfx_kc2b, p)
		CONS_Printf(p, "\x86".."Restat\x82 disabled\x86. You will use the stats of your skin again.")
		return
	elseif nspeed ~= nil and nweight ~= nil then
		if min(nspeed, nweight) < 1 or (max(nspeed, nweight) > 9 and restat_limiter.value) then
			local legal = restat_limiter.value and "(1-9)" or "(1-?)"
			CONS_Printf(p, "\x86".."Stats out of bounds. Legal values are "..legal)
			return
		end
	else
		local skin = table.concat(args, " "):lower()
		skin = findskin(skin)
		if skin then
			nspeed = skin.kartspeed
			nweight = skin.kartweight
			restat.skin = skin.realname
		else
			CONS_Printf(p, "\x86".."Could not find a matching skin.")
			return
		end
	end
	
	restat.pendingspeed = nspeed
	restat.pendingweight = nweight
	restat.random = false
	
	S_StartSound(nil, sfx_mbs41, p)
	CONS_Printf(p, fmt("\x86".."OK! You will be \x82%s\x86 for the next race.", statstring(restat.pendingspeed, restat.pendingweight)))
	CONS_Printf(p, "\x86".."Use \x87restat off\x86 to revert to your skin's usual stats.")
end)

addHook("ThinkFrame", function()
	if not restat_enabled.value then return end
	
	if leveltime == 1 then
		for p in players.iterate do
			updatestats(p)
		end
	end
	
	for p in players.iterate do
		local restat = p.mogi_restat
		if p.spectator or not restat then continue end
		if restat.speed then
			p.kartspeed = restat.speed
			p.kartweight = restat.weight
		end
	end
end)

local fovvars
rawset(_G, "R_FOV", function(num)
	if not fovvars then
		fovvars = { [0] = CV_FindVar("fov"), CV_FindVar("fov2"), CV_FindVar("fov3"), CV_FindVar("fov4") }
	end
	return fovvars[num].value
end)
local cv_tilting
rawset(_G, "R_GetViewVars", function(v, p, c)
	if not cv_tilting then cv_tilting = CV_FindVar("tilting") end
	local roll = p.viewrollangle + (cv_tilting.value and not (p.spectator --[[or c.freecam]]) and p.tilt or 0)

	if p.awayviewtics then
		local mo = p.awayviewmobj
		return mo.x, mo.y, mo.z, mo.angle, mo.pitch, roll
	elseif c.chase then
		return c.x, c.y, c.z + c.height/2, c.angle, c.aiming, roll
	elseif p.mo then
		return p.mo.x, p.mo.y, p.viewz, p.mo.angle, p.aiming, roll
	end
end)
-- https://github.com/GenericHeroGuy/ringracers-scripts/blob/master/src/sglua/Lua/Utils/libsg2.lua
-- I'm too lazy to actually reimplement this myself
local baseFov = 90*FRACUNIT
local BASEVIDWIDTH = 320
local BASEVIDHEIGHT = 200
local function K_ObjectTracking(v, p, c, point, reverse)
	local cameraNum = c.pnum - 1
	local viewx, viewy, viewz, viewangle, aimingangle, viewroll = R_GetViewVars(v, p, c)

	// Initialize defaults
	local result = {
		x = 0,
		y = 0,
		scale = FRACUNIT,
		onScreen = false
	}

	// Take the view's properties as necessary.
	local viewpointAngle, viewpointAiming, viewpointRoll
	if reverse then
		viewpointAngle = viewangle + ANGLE_180
		viewpointAiming = InvAngle(aimingangle)
		viewpointRoll = viewroll
	else
		viewpointAngle = viewangle
		viewpointAiming = aimingangle
		viewpointRoll = InvAngle(viewroll)
	end

	// Calculate screen size adjustments.
	local screenWidth = v.width()/v.dupx()
	local screenHeight = v.height()/v.dupy()

	-- what's the difference between this and r_splitscreen?
	-- future G: seems to alternate between view count and view number depending on where you are in the codebase
	-- may i interest the Krew in stplyrnum? :^)
	-- future H: v.splitscreen is now a thing as of 2.4!
	local split = v.splitscreen()
	
	if split >= 2 then
		// Half-wide screens
		screenWidth = $ >> 1
	end

	if split >= 1 then
		// Half-tall screens
		screenHeight = $ >> 1
	end

	local screenHalfW = (screenWidth >> 1) << FRACBITS
	local screenHalfH = (screenHeight >> 1) << FRACBITS

	// Calculate FOV adjustments.
	local fovDiff = R_FOV(cameraNum) - baseFov
	local fov = ((baseFov - fovDiff) / 2) - (p.fovadd / 2)
	local fovTangent = tan(FixedAngle(fov))

	if split == 1 then
		// Splitscreen FOV is adjusted to maintain expected vertical view
		fovTangent = 10*fovTangent/17
	end

	local fg = (screenWidth >> 1) * fovTangent

	// Determine viewpoint factors.
	local h = R_PointToDist2(point.x, point.y, viewx, viewy)
	local da = viewpointAngle - R_PointToAngle2(viewx, viewy, point.x, point.y)
	local dp = viewpointAiming - R_PointToAngle2(0, 0, h, viewz)

	if reverse then da = -da end

	// Set results relative to top left!
	result.x = FixedMul(tan(da), fg)
	result.y = FixedMul((tan(viewpointAiming) - FixedDiv((point.z - viewz), 1 + FixedMul(cos(da), h))), fg)

	result.angle = da
	result.pitch = dp
	result.fov = fg

	// Rotate for screen roll...
	if viewpointRoll then
		local tempx = result.x
		result.x = FixedMul(cos(viewpointRoll), tempx) - FixedMul(sin(viewpointRoll), result.y)
		result.y = FixedMul(sin(viewpointRoll), tempx) + FixedMul(cos(viewpointRoll), result.y)
	end

	// Flipped screen?
	if encoremode then result.x = -result.x end

	// Center results.
	result.x = $ + screenHalfW
	result.y = $ + screenHalfH

	result.scale = FixedDiv(screenHalfW, h+1)

	result.onScreen = not ((abs(da) > ANG60) or (abs(viewpointAiming - R_PointToAngle2(0, 0, h, (viewz - point.z))) > ANGLE_45))

	// Cheap dirty hacks for some split-screen related cases
	if result.x < 0 or result.x > (screenWidth << FRACBITS) then
		result.onScreen = false
	end

	if result.y < 0 or result.y > (screenHeight << FRACBITS) then
		result.onScreen = false
	end

	// adjust to non-green-resolution screen coordinates
	result.x = $ - ((v.width()/v.dupx()) - BASEVIDWIDTH)<<(FRACBITS-(split >= 2 and 2 or 1))
	result.y = $ - ((v.height()/v.dupy()) - BASEVIDHEIGHT)<<(FRACBITS-(split >= 1 and 2 or 1))
	return result
end

local function stringdraw(v, x, y, str, flags, colormap)
	for i = 1, #str do
		local char = str:sub(i, i)
		local patch = v.cachePatch(string.format("OPPRF%03d", char:byte()))
		v.drawScaled(x, y, FRACUNIT, patch, flags, colormap)
		x = x + 6*FRACUNIT
	end
end

local function drawsmallprofilenum(v, x, y, str, flags, colormap)
	for i = 1, #str do
		local char = str:sub(i, i)
		local patch = v.cachePatch(string.format("PINGF%03d", char:byte()))
		v.drawScaled(x, y, FRACUNIT, patch, flags, colormap)
		x = x + 4*FRACUNIT
	end
end

local local_indicator_flags = V_SNAPTOLEFT | V_SNAPTOBOTTOM | V_SLIDEIN
local cv_seenames

local function draw_indicator(v, p, c, x, y, flags, mode)
	-- Big indicator, for on screen hud
	if mode == 0 then
		v.drawScaled(x, y, FRACUNIT, v.cachePatch("GFXHUS"), flags)
		v.drawScaled(x + 20*FRACUNIT, y, FRACUNIT, v.cachePatch("GFXHUW"), flags)

		local smap = v.getColormap(TC_RAINBOW, SKINCOLOR_ORANGE)
		local wmap = v.getColormap(TC_RAINBOW, SKINCOLOR_BLUE)
		stringdraw(v, x+11*FRACUNIT, y+2*FRACUNIT, tostring(p.kartspeed), flags, smap)
		stringdraw(v, x+31*FRACUNIT, y+2*FRACUNIT, tostring(p.kartweight), flags, wmap)
	-- Smaller indicator, for nametags
	else
		x = $ + 5*FRACUNIT
		y = $ - 13*FRACUNIT
		
		v.drawScaled(x, y + FRACUNIT, FRACUNIT, v.cachePatch("GFXHUSS"), flags)
		v.drawScaled(x+(6+6)*FRACUNIT, y + FRACUNIT, FRACUNIT, v.cachePatch("GFXHUWS"), flags)

		local smap = v.getColormap(TC_RAINBOW, SKINCOLOR_ORANGE)
		local wmap = v.getColormap(TC_RAINBOW, SKINCOLOR_BLUE)
		drawsmallprofilenum(v, x+6*FRACUNIT, y, tostring(p.kartspeed), flags, smap)
		drawsmallprofilenum(v, x+(6+6+6)*FRACUNIT, y, tostring(p.kartweight), flags, wmap)
	end
end

local function K_ShowPlayerNametag(p, stplyr)
	if not (cv_seenames and cv_seenames.value) then return false end
	if stplyr == p then return false end
	if (gametyperules & GTR_CIRCUIT) then
		if (p.position == 0 or stplyr.position == 0 or p.position < stplyr.position-2 or p.position > stplyr.position+2) then
			return false
		end
	end
	-- restat specific: only if that player has restat enabled
	if not (p.mogi_restat and p.mogi_restat.speed) and not (p.skin > 63 and restat_moddedstats.value) then
		return false
	end
	return true
end

local function is_player_nametag_on_screen(tr)
	local p = tr.mobj.player
	
	if tr.mobj.renderflags & K_GetPlayerDontDrawFlag(p) then
		return false
	end
	
	if tr.camdist > 8192*mapobjectscale then
		return false
	end
	
	if not P_CheckSight(tr.origin, tr.mobj) then
		return false
	end
	
	return true
end

-- Culling constants
local blockWidth = 20
local blockHeight = 10
local xBlocks = 320 / blockWidth
local yBlocks = 200 / blockHeight

hud.add(function(v, p, c)
	if not restat_enabled.value then return end
	if not (p.mo and p.mo.valid) then return end
	if p.spectator then return end
	
	cv_seenames = $ or CV_FindVar("seenames")
	
	draw_indicator(v, p, c, 17*FRACUNIT, 189*FRACUNIT, local_indicator_flags, 0)
	
	if not hud.enabled("names") then return end
	if not restat_nametags.value then return end
	
	local tracking = {}
	local origin = p.mo
	for q in players.iterate do
		if not (q.mo and q.mo.valid) then continue end
		if q.spectator then continue end
		
		local mo = q.mo
		if mo.health < 0 then continue end
		
		if not K_ShowPlayerNametag(q, p) then continue end
		
		local pos = { x = mo.x + mo.sprxoff, y = mo.y + mo.spryoff, z = mo.z + mo.sprzoff + (mo.height >> 1) }
		local tr = {
			mobj = mo,
			origin = origin,
			camdist = R_PointToDist2(origin.x, origin.y, pos.x, pos.y),
			id = #q
		}
		
		if not is_player_nametag_on_screen(tr) then continue end
		
		local headoffset = 36*mo.scale*P_MobjFlip(mo)
		pos.z = $ + headoffset
		
		local res = K_ObjectTracking(v, p, c, pos, false)
		if res.onScreen then
			tr.result = res
			tracking[#tracking+1] = tr
		end
	end
	
	table.sort(tracking, function(a, b) return a.camdist > b.camdist end)
	-- No culling i aint doing allat
	-- (Sonia) nevermind
	-- We are only implementing whats needed for nametags SPECIFICALLY
	local map = {}
	for x = 1, xBlocks do
		map[x] = {}
		for y = 1, yBlocks do
			map[x][y] = 0
		end
	end
	for _, tr in ipairs(tracking) do
		if not tr.result.onScreen then continue end
		
		local x1, x2, y1, y2
		local player = tr.mobj.player
		local bit = 2 -- nametags will cull on a different plane
		local w = v.stringWidth(player.name, 0, "thin")
		
		-- Does not handle bot names, or viewpoint letters or anything else
		-- Just nametags
		x1 = tr.result.x
		x2 = tr.result.x + ((6 + w) * FRACUNIT)
		y1 = tr.result.y - (30*FRACUNIT)
		y2 = tr.result.y - (4*FRACUNIT)
		
		if (p.itemtype ~= 0 and p.itemamount ~= 0) or (p.itemroulette.active and not p.itemroulette.ringbox) then
			x1 = $ - (24*FRACUNIT)
		end
		
		x1 = max($ / blockWidth / FRACUNIT, 0)
		x2 = min($ / blockWidth / FRACUNIT, xBlocks - 1)
		y1 = max($ / blockHeight / FRACUNIT, 0)
		y2 = min($ / blockHeight / FRACUNIT, yBlocks - 1)
		
		local allmine = true
		for x = x1+1, x2+1 do
			for y = y1+1, y2+1 do
				if (map[x][y] & bit) then 
					allmine = false
				else
					map[x][y] = $ | bit
				end
			end
		end
		
		if allmine then
			tr.foreground = true
		end
	end
	
	for _, tr in ipairs(tracking) do
		local flags = (tr.mobj.eflags & MFE_VERTICALFLIP == MFE_VERTICALFLIP) and (V_VFLIP) or 0
		flags = $ | V_HUDTRANS
		if not tr.foreground then
			flags = $ | V_60TRANS
		end
		if v.interpolate then v.interpolate(tr.id) end
		-- todo vflip
		draw_indicator(v, tr.mobj.player, c, tr.result.x, tr.result.y, 1)
		if v.interpolate then v.interpolate(false) end
	end
end, "game")

local function Y_PlayerRestatDrawer(v, info, xoffset)
	if info.numplayers == 0 then return end
	
	local yspacing = 14
	local heightcount = info.numplayers - 1
	
	local verticalresults = info.numplayers < 4
	local drawping = (netgame and gamestate == GS_LEVEL)
	
	local x, y = 0, 0
	local x2 = 0
	local inwardshim = drawping and 8 or 0
	local returny = 0
	
	if verticalresults then
		x = (BASEVIDWIDTH / 2) - 61
	else
		x = 29
		inwardshim = $ / 2
		heightcount = $ / 2
	end
	
	x = $ + xoffset + inwardshim
	x2 = x
	
	if drawping then x2 = $ - 9 end
	
	local halfway = info.halfway
	if halfway > 4 then
		yspacing = $ - 1
	elseif halfway <= 2 then
		yspacing = $ + (verticalresults and 2 or 1)
	end
	
	y = 106 - (heightcount * yspacing) / 2
	if y < 70 then y = 70 end
	returny = y
	
	for i = 0, info.numplayers - 1 do
		local restat = info.restat[i]
		if restat then
			local smap = v.getColormap(TC_RAINBOW, SKINCOLOR_ORANGE)
			local wmap = v.getColormap(TC_RAINBOW, SKINCOLOR_BLUE)
			
			-- draw restat markers
			drawsmallprofilenum(v, (x+14)*FRACUNIT, (y-6)*FRACUNIT, tostring(restat.speed), 0, smap)
			drawsmallprofilenum(v, (x+14+8)*FRACUNIT, y*FRACUNIT, tostring(restat.weight), 0, wmap)
		end
		
		y = $ + yspacing
		
		if not verticalresults and i == halfway then
			x = 169 + xoffset - inwardshim
			y = returny
			x2 = x + 118 + 5
		end
	end
end

-- Scoreboard restat indicators
hud.add(function(v, p, c)
	local info = {
		numplayers = 0,
		halfway = 0,
		restat = {},
		num = {}
	}
	local numplayersingame = 0
	local completed = {}
	for q in players.iterate do
		if q.spectator then continue end
		if not (q.mo and q.mo.valid) then continue end
		numplayersingame = $ + 1
	end
	
	for j = 0, numplayersingame - 1 do
		local lowestposition = 17
		for q in players.iterate do
			if q.spectator then continue end
			if not (q.mo and q.mo.valid) then continue end
			if completed[#q] then continue end
			if q.position >= lowestposition then continue end
			info.num[info.numplayers] = #q
			lowestposition = q.position
		end
		
		local i = info.num[info.numplayers]
		completed[i] = true
		
		if players[i].mogi_restat and players[i].mogi_restat.speed then
			info.restat[info.numplayers] = {
				speed = players[i].kartspeed,
				weight = players[i].kartweight
			}
		end
		
		info.numplayers = $ + 1
	end
	
	info.halfway = (info.numplayers-1)/2
	
	Y_PlayerRestatDrawer(v, info, 0)
end, "scores")


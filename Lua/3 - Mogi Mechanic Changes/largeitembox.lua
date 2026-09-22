local HITBOX_REQUIRED = 0
local HITBOX_INHERIT = 1
local HITBOX_EXTRA = 2

freeslot(
	'MT_RANDOMITEM_EXTRAHITBOX',
	'S_RANDOMITEM_EXTRAHITBOX_TANGIBLE',
	'S_RANDOMITEM_EXTRAHITBOX_RESPAWNING'
)
states[S_RANDOMITEM_EXTRAHITBOX_TANGIBLE] = {S_NULL, 0, -1, A_SetObjectFlags, MF_NOCLIPTHING, 1, S_RANDOMITEM_EXTRAHITBOX_RESPAWNING}
states[S_RANDOMITEM_EXTRAHITBOX_RESPAWNING] = {S_NULL, 0, TICRATE-5, A_SetObjectFlags, MF_NOCLIPTHING, 2, S_RANDOMITEM_EXTRAHITBOX_TANGIBLE}
mobjinfo[MT_RANDOMITEM_EXTRAHITBOX] = {
	spawnstate = S_RANDOMITEM_EXTRAHITBOX_TANGIBLE,
	radius = mobjinfo[MT_RANDOMITEM].radius,
	height = mobjinfo[MT_RANDOMITEM].height,
	flags = mobjinfo[MT_RANDOMITEM].flags,
}

local function spawn_hitbox(origin, sx, sy, rad)
	local h = P_SpawnMobj(origin.x + sx * rad, origin.y + sy * rad, origin.z, MT_RANDOMITEM_EXTRAHITBOX)
	h.radius = rad
	h.height = origin.height
	h.flags = origin.flags & ~(MF_NOCLIPTHING|MF_NOBLOCKMAP)
	h.flags2 = origin.flags2
	h.target = origin
end

addHook('MobjSpawn', function(mo)
	mo.extra_hitbox_state = HITBOX_INHERIT
end, MT_RANDOMITEM)

addHook('MapThingSpawn', function(mo)
	mo.extra_hitbox_state = HITBOX_REQUIRED
end, MT_RANDOMITEM)

addHook('MobjThinker', function(origin)
	if origin.extra_hitbox_state then return end
	-- Do not spawn extra hitboxes if the original hitbox can function in tne blockmap
	if origin.radius <= 64*FU then
		origin.extra_hitbox_state = HITBOX_INHERIT
		return
	end
	local map_radius = fixmul(mobjinfo[MT_RANDOMITEM].radius, fixmul(origin.spawnpoint.scale, mapobjectscale) * 3)
	local hbox_radius = min(map_radius / 2, 64*FU)
	spawn_hitbox(origin, 1, 1, hbox_radius)
	spawn_hitbox(origin, 1, -1, hbox_radius)
	spawn_hitbox(origin, -1, -1, hbox_radius)
	spawn_hitbox(origin, -1, 1, hbox_radius)
	origin.radius = 1
	origin.extra_hitbox_state = HITBOX_EXTRA
	origin.flags = $ & ~MF_SPECIAL
end, MT_RANDOMITEM)

addHook('TouchSpecial', function(special, toucher)
	local box = special.target
	if box.extra_touch_mobj then
		return true
	end
	if box.flags & MF_NOCLIPTHING then
		return true
	end
	if not P_CanPickupItem(toucher.player, PICKUP_ITEMBOX) then  -- p_inter.c
		return true
	end
	box.extra_touch_mobj = toucher
	box.flags = $ | MF_SPECIAL
	local x, y, z = box.x, box.y, box.z
	P_MoveOrigin(box, toucher.x, toucher.y, toucher.z)
	P_CheckPosition(toucher, toucher.x, toucher.y)
	P_MoveOrigin(box, x, y, z)
	box.extra_touch_mobj = nil
	box.flags = $ & ~MF_SPECIAL
	-- This code copies the respawn timing of MT_RANDOMITEM
	if box.fuse and special.tics == -1 then
		special.tics = 5  -- p_inter.c
	end
	return true
end, MT_RANDOMITEM_EXTRAHITBOX)

addHook('TouchSpecial', function(special, toucher)
	if special.extra_hitbox_state == HITBOX_EXTRA and special.extra_touch_mobj ~= toucher then
		return true
	end
end, MT_RANDOMITEM)

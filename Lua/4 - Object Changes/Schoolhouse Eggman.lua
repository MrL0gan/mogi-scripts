--- Alternate Schoolhouse Eggman Behavior
--- by Yellow/@GlowingTail
local S_SCHOOLHOUSEEGGMAN_TARGET = freeslot "S_SCHOOLHOUSEEGGMAN_TARGET"

---Validates an userdata.
---@param ud userdata
---@return boolean
local function isValid(ud)
	return ud and ud.valid
end

---Create a lock on for the actor to use on the target.
---@param actor mobj_t
---@return mobj_t
local function makeegglockon(actor)
	local lockon = P_SpawnMobjFromMobj(actor, 0, 0, 0, MT_OVERLAY)
	lockon.state = S_SCHOOLHOUSEEGGMAN_TARGET
	lockon.color = SKINCOLOR_BLACK

	---Place the lock on directly above the target.
	lockon.threshold = OV_DONTSCREENOFFSET | OV_DONTROLL
	lockon.spriteyoffset = 64 * FU

	return lockon
end

---Makes the actor constantly look for targets they can see while chasing.
---@param actor mobj_t
local function retarget(actor)
	if not isValid(actor)
		return end

	---Clear the current target, we must try to get a new one always. Even if it's the same one.
	actor.target = nil
	if P_LookForPlayers(actor, MISSILERANGE * 2, true)
		---Make a lock on if we don't have one.
		if not isValid(actor.tracer)
			actor.tracer = makeegglockon(actor)
		end

		---Set the lock on to the target.
		actor.tracer.target = actor.target
		actor.tracer.hitlag = 0
		return end

	---Remove the lock on if we didn't get a target.
	if isValid(actor.tracer)
		P_RemoveMobj(actor.tracer)
	end
end

states[S_SCHOOLHOUSEEGGMAN_CHASE4].action = retarget
states[S_SCHOOLHOUSEEGGMAN_TARGET] = {SPR_FITM, FF_FULLBRIGHT | FF_ADD | Y, -1}
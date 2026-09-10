--- Item Changes for MOGI Lounge
--- by Yellow/@GlowingTail

local PROJECTILESPEEDCAP_DISTFROM1ST = 5000
local PROJECTILESPEEDCAP_MAXSPEED = 35 * FU

local TOXOMISTERCLOUD_RETURNDELAY = TICRATE / 3

local FLAMESHIELD_MAX = 120
local FLAMESHOTS_DIV = 4
local FLAMELENGTH_REGENRATE = TICRATE / 2

---Holds damage modifying functions by object type.
---@type table<mobjtype_t, fun(player: player_t, target: mobj_t, inflictor: mobj_t, source: mobj_t?, damage: integer, damagetype: damagetype): boolean?>
local inflictorTypes = {}

---Validates an userdata.
---@param ud userdata
---@return boolean
local function isValid(ud)
	return ud and ud.valid
end

---Clamps a number within a range of values between a defined minimum bound and a maximum bound.
---@param value number
---@param low number
---@param high number
---@return number
local function clamp(value, low, high)
	return min(max(value, low), high)
end

---Recales a number from the provided `inmin`/`inmax` to `outmin`/`outmax` using an easing function.
---@param value number
---@param inmin number
---@param inmax number
---@param outmin number
---@param outmax number
---@param easingfunc function?
---@param easingparam fixed_t?
---@return number
local function rescale(value, inmin, inmax, outmin, outmax, easingfunc, easingparam)
	---Handle edge case where min == max.
	if inmin == inmax
		return outmin
	end

	---Clamp the input value to the range and normalize it to the `FRACUNIT` range.
	value = fixdiv(clamp($, inmin, inmax) - inmin, inmax - inmin)

	---Return the result of using the specified easing function or linear function.
	return (easingfunc or ease.linear)(value, outmin, outmax, easingparam)
end

---Spawn and setup an image of the object that will make it look like it got punted.
---@param mobj mobj_t
local function createPuntedImage(mobj)
	local img = P_SpawnGhostMobj(mobj)
	K_MakeObjectReappear(mobj)

	img.flags = $ & ~MF_NOGRAVITY
	img.renderflags = mobj.renderflags & ~RF_DONTDRAW
	img.extravalue1 = 1
	img.extravalue2 = 2
	img.fuse = 2 * TICRATE

	local angle = K_MomentumAngle(mobj)
	local speed = max(60 * mapobjectscale, fixhypot(mobj.momx, mobj.momy) * 2)
	P_InstaThrust(img, angle, speed)
	P_SetObjectMomZ(img, speed)
end

---Runs damage modifier functions based on the inflictor's type.
---@param target mobj_t
---@param inflictor mobj_t?
---@param ... [mobj_t?, integer, damagetype]
local function damageModifierbyInflictor(target, inflictor, ...)
	if not isValid(target)
		return end

	local player = target.player
	if not isValid(player)
		return end

	if not isValid(inflictor)
		return end

	local objecttype = inflictor.type
	if inflictorTypes[objecttype]
		return inflictorTypes[objecttype](player, target, inflictor, ...)
	end
end

---Applies stumble damage to a player that works similarly to a normal damage type.
---@param player player_t
---@param target mobj_t
---@param inflictor mobj_t
---@param source mobj_t?
---@param damage integer
---@param damagetype damagetype
local function doStumbleDamage(player, target, inflictor, source, damage, damagetype)
	if not (gametyperules & GTR_CIRCUIT)
		return end

	if player.flashing and not P_PlayerInPain(player)
		K_DoInstashield(player)
		return end

	if not P_DamageMobj(target, inflictor, source, damage, DMG_STUMBLE | DMG_WOMBO)
		return end

	player.flashing = K_GetKartFlashing(player)
	K_TryHurtSoundExchange(target, source)
	K_ApplyStun(player, inflictor, source, damage, damagetype)

	if player.curshield
		K_PopPlayerShield(player)

	else
		P_PlayerRingBurst(player, 5)
		P_PlayRinglossSound(target, player)
	end

	if isValid(source)
		local attacker = source.player
		if isValid(attacker)
			local amount = K_PvPAmpReward(20, attacker, player)
			K_SpawnAmps(attacker, amount, target)
		end
	end

	return true
end

---Returns a speed limit based on how far the player is from first place.
---@param player player_t
---@return fixed_t
local function getProjectileSpeedCap(player)
	local distance = INT32_MAX
	for others in players.iterate do
		if not isValid(others)
			continue end

		if others.spectator
			continue end

		distance = min($, others.distancetofinish)
	end

	distance = player.distancetofinish - $
	if distance == 0
		return PROJECTILESPEEDCAP_MAXSPEED
	end

	return rescale(distance,
	0, PROJECTILESPEEDCAP_DISTFROM1ST,
	PROJECTILESPEEDCAP_MAXSPEED, FU,
	ease.insine)
end

---Toxomister Cloud: Modifies the behavior when being passed to another player.
---@param cloud mobj_t
---@param pmo mobj_t
local function toxomisterCloudPass(cloud, pmo)
	if not (gametyperules & GTR_CIRCUIT)
		return end

	if not (isValid(cloud) and isValid(pmo))
		return end

	---Cloud was just passed to this target, let it sit for a moment before being able to pass it.
	if (cloud.reactiontime > leveltime)
		return true
	end

	local target = cloud.hnext
	if target == pmo
		---Hook triggered on the target, ignore.
		return end

	local player = pmo.player
	if not isValid(player)
		return end

	---Update the time it was passed.
	cloud.reactiontime = leveltime + TOXOMISTERCLOUD_RETURNDELAY
	cloud.lastlook = -1

	if not isValid(target)
		return end

	local lastPlayer = target.player
	if not isValid(lastPlayer)
		return end

	---Store the last target, and unlink the cloud from them.
	lastPlayer.toxomistercloud = nil
	cloud.lastlook = #lastPlayer
end

---Stone Shoe: Reduces the duration or removes it when it gets punted.
---@param stoneshoe mobj_t
---@param punted boolean
local function stoneShoeThinker(stoneshoe, punted)
	if not isValid(stoneshoe)
		return end

	stoneshoe.fuse = min($, 10 * TICRATE)

	---If the stone shoe or any part of it's chain get punted, remove the stone shoe.
	---This allows the target player to move at a normal speed
	---instead of having an invisible object drag them down.
	local chain = stoneshoe
	while isValid(chain) do
		if not punted and chain.reappear
			stoneShoeThinker(stoneshoe, true)
			P_RemoveMobj(stoneshoe)
			return

		---If a part got punted, make the rest of the chain look like
		---they've been punted too instead of disappearing suddendly.
		elseif punted and not chain.reappear
			createPuntedImage(chain)
		end

		chain = $.hnext
	end
end

---Flame Shield: Resets the gauge penalty of a player.
---@param player player_t
local function resetFlameLengthReduce(player)
	if isValid(player)
		player.flamelengthreduce = 0
	end
end

---Flame Shield: Resets the gauge penalty when the shield disappears.
---@param flameshield mobj_t
local function resetFlameLengthReducebyFlameshield(flameshield)
	if not (gametyperules & GTR_CIRCUIT)
		return end

	if not isValid(flameshield)
		return end

	local pmo = flameshield.target
	if not isValid(pmo)
		return end

	resetFlameLengthReduce(pmo.player)
end

---Flame Shield: Apply maximum gauge reduction based on the amount of times attacked with it.
---@param flameshield mobj_t
local function reduceFlameGaugeCap(flameshield)
	if not (gametyperules & GTR_CIRCUIT)
		return end

	if not isValid(flameshield)
		return end

	local pmo = flameshield.target
	if not isValid(pmo)
		return end

	local player = pmo.player
	if not isValid(player)
		return end

	if not player.flamelengthreduce
		return end

	---Cap the gauge based on the amount of reduction applied.
	player.flamelength = max(min($, FLAMESHIELD_MAX - player.flamelengthreduce), 0)

	---Regenerate the gauge by reducing the gauge penalty.
	if (leveltime % FLAMELENGTH_REGENRATE) == 0
		player.flamelengthreduce = $ - 1
	end
end

---Controls what happens when a player attacks another player.
---@param inflictor mobj_t
inflictorTypes[MT_PLAYER] = function(_, _, inflictor)
	local attacker = inflictor.player
	if not isValid(attacker)
		return end

	if attacker.flamedash and attacker.itemtype == KITEM_FLAMESHIELD
		---Add to the gauge penalty as the player attacks others with a flame shield.
		attacker.flamelengthreduce = ($ or 0) + FLAMESHIELD_MAX / FLAMESHOTS_DIV

		---If the gauge penalty leaves the player with no usable gauge,
		---use up the flame shield.
		if attacker.flamelengthreduce >= FLAMESHIELD_MAX
			K_PopPlayerShield(attacker)
		end
	end
end

---Controls what happens when a landmine hits a player.
---@param player player_t
---@param target mobj_t
---@param landmine mobj_t
---@param source mobj_t
---@param damage integer
---@param damagetype damagetype
---@return boolean
inflictorTypes[MT_LANDMINE] = function(player, target, landmine, source, damage, damagetype)
	if not landmine.reactiontime
		return end

	if damagetype & DMG_TYPEMASK ~= DMG_TUMBLE
		return end

	---Landmine: Change the damage type to stumble if the landmine was sliding on-hit.
	if doStumbleDamage(player, target, landmine, source, damage, damagetype)
		return false
	end
end

---Controls what happens when an orbinaut hits a player.
---@param player player_t
---@param orbinaut mobj_t
inflictorTypes[MT_ORBINAUT] = function(player, _, orbinaut)
	---Orbinaut: Cap the impact speed based on how far this player is from first place.
	local projectileSpeedCap = getProjectileSpeedCap(player)
	orbinaut.momx = clamp($, -projectileSpeedCap, projectileSpeedCap)
	orbinaut.momy = clamp($, -projectileSpeedCap, projectileSpeedCap)
	orbinaut.momz = clamp($, -projectileSpeedCap, projectileSpeedCap)
end

inflictorTypes[MT_ORBINAUT_SHIELD] = inflictorTypes[MT_ORBINAUT]

---Controls what happens when a jawz hits a player.
---@param player player_t
---@param target mobj_t
---@param jawz mobj_t
---@param source mobj_t
---@param damage integer
---@param damagetype damagetype
---@return boolean
inflictorTypes[MT_JAWZ] = function(player, target, jawz, source, damage, damagetype)
	if damagetype & DMG_TYPEMASK ~= DMG_WIPEOUT
		return end

	---Jawz: Change the damage type to stumble.
	if doStumbleDamage(player, target, inflictor, source, damage, damagetype)
		return false
	end
end

inflictorTypes[MT_JAWZ_SHIELD] = inflictorTypes[MT_JAWZ]

---Ballhog: Makes ballhog explosions unpuntable, as it looks visually weird.
---It also disables hitlag for the object, to prevent locking a
---player in a consecutive hitstop for various seconds.
mobjinfo[MT_BALLHOGBOOM].flags = $ | MF_DONTPUNT | MF_NOHITLAGFORME

addHook("ShouldDamage", damageModifierbyInflictor, MT_PLAYER)
addHook("TouchSpecial", toxomisterCloudPass, MT_TOXOMISTER_CLOUD)
addHook("MobjThinker", stoneShoeThinker, MT_STONESHOE)
addHook("PlayerSpawn", resetFlameLengthReduce)
addHook("MobjThinker", reduceFlameGaugeCap, MT_FLAMESHIELD)
addHook("MobjRemoved", resetFlameLengthReducebyFlameshield, MT_FLAMESHIELD)
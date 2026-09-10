--- Item Changes for MOGI Lounge
--- by Yellow/@GlowingTail

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

---Caps the momentum of an object based on the tripwire speed threshold for the target player.
---@param player player_t
---@param mobj mobj_t
local function capMomentumByTripwireSpeedThreshold(player, _, mobj)
	local speedcap = K_PlayerTripwireSpeedThreshold(player)

	mobj.momx = min(max($, -speedcap), speedcap)
	mobj.momy = min(max($, -speedcap), speedcap)
	mobj.momz = min(max($, -speedcap), speedcap)
end

---Ballhog: Makes ballhog explosions unpuntable, as it looks visually weird.
---It also disables hitlag for the object, to prevent locking a
---player in a consecutive hitstop for various seconds.
---@param boom mobj_t
local function modifyBallhogBoom(boom)
	if not isValid(boom)
		return end

	boom.flags = $ | MF_DONTPUNT | MF_NOHITLAGFORME
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
local function stoneShoeThinker(stoneshoe)
	if not isValid(stoneshoe)
		return end

	stoneshoe.fuse = min($, 10 * TICRATE)

	---If the stone shoe got punted, remove the object.
	---This allows the target player to move at a normal speed
	---instead of having an invisible object drag them down.
	if stoneshoe.reappear
		P_RemoveMobj(stoneshoe)
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

inflictorTypes[MT_ORBINAUT] = capMomentumByTripwireSpeedThreshold
inflictorTypes[MT_ORBINAUT_SHIELD] = capMomentumByTripwireSpeedThreshold

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

addHook("ShouldDamage", damageModifierbyInflictor, MT_PLAYER)
addHook("TouchSpecial", toxomisterCloudPass, MT_TOXOMISTER_CLOUD)
addHook("MobjSpawn", modifyBallhogBoom, MT_BALLHOGBOOM)
addHook("MobjThinker", stoneShoeThinker, MT_STONESHOE)
addHook("PlayerSpawn", resetFlameLengthReduce)
addHook("MobjThinker", reduceFlameGaugeCap, MT_FLAMESHIELD)
addHook("MobjRemoved", resetFlameLengthReducebyFlameshield, MT_FLAMESHIELD)
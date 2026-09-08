--- Item Changes for MOGI Lounge
--- by Yellow/@GlowingTail

--#region Helper Functions

---Validates an userdata.
---@param ud userdata
---@return boolean
local function isValid(ud)
	return ud and ud.valid
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

	---Don't damage a player that is already in pain or have flashtics.
	if player.flashing and not P_PlayerInPain(player)
		K_DoInstashield(player)
		return false
	end

	---Try to stumble the player.
	if not P_DamageMobj(target, inflictor, source, damage, DMG_STUMBLE | DMG_WOMBO)
		return end

	player.flashing = K_GetKartFlashing(player)
	K_TryHurtSoundExchange(target, source)
	K_ApplyStun(player, inflictor, source, damage, damagetype)

	---If they have a shield, pop it. Otherwise, lose some rings.
	if player.curshield
		K_PopPlayerShield(player)
	else
		P_PlayerRingBurst(player, 5)
		P_PlayRinglossSound(target, player)
	end

	---Reward amps for the attacker.
	if isValid(source)
		local attacker = source.player
		if isValid(attacker)
			local amount = K_PvPAmpReward(20, attacker, player)
			K_SpawnAmps(attacker, amount, target)
		end
	end

	return true
end

---Holds damage modifying functions by object type.
---@type table<mobjtype_t, function>
local inflictorTypes = {}

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
--#endregion

--#region [ Orbinaut ] --
--- Removes the momentum on-hit to prevent players being flung far off when a jawz hits them at extreme speeds.

---Controls what happens when an orbinaut hits a player.
---@param player player_t
---@param target mobj_t
---@param orbinaut mobj_t
---@param source mobj_t?
---@param damage integer
---@param damagetype damagetype
inflictorTypes[MT_ORBINAUT] = function(player, target, orbinaut, source, damage, damagetype)
	---Remove all momentum.
	orbinaut.momx, orbinaut.momy, orbinaut.momz = 0, 0, 0
end
--#endregion

--#region [ Jawz ] --
--- Removes the momentum on-hit to prevent players being flung far off when a jawz hits them at extreme speeds.

---Controls what happens when a jawz hits a player.
---@param player player_t
---@param target mobj_t
---@param jawz mobj_t
---@param source mobj_t?
---@param damage integer
---@param damagetype damagetype
inflictorTypes[MT_JAWZ] = function(player, target, jawz, source, damage, damagetype)
	---Remove all momentum.
	jawz.momx, jawz.momy, jawz.momz = 0, 0, 0

	/*if damagetype & DMG_TYPEMASK ~= DMG_WIPEOUT
		return end*/

	/*if doStumbleDamage(player, target, inflictor, source, damage, damagetype)
		return false
	end*/
end
--#endregion

--#region [ Landmine ] --
--- Changes the damage type to stumble if the landmine was sliding on-hit.

---Controls what happens when a landmine hits a player.
---@param player player_t
---@param target mobj_t
---@param landmine mobj_t
---@param source mobj_t?
---@param damage integer
---@param damagetype damagetype
inflictorTypes[MT_LANDMINE] = function(player, target, landmine, source, damage, damagetype)
	if not landmine.reactiontime
		return end

	if damagetype & DMG_TYPEMASK ~= DMG_TUMBLE
		return end

	if doStumbleDamage(player, target, inflictor, source, damage, damagetype)
		return false
	end
end
--#endregion

--#region [ Ballhog ] --
--- Disables hitlag to prevent ballhog explosion from locking players in a consecutive hitstop.
--- Disables punting to prevent the ballhog explosion from being punted.

---Makes ballhog explosions unpuntable, as it looks visually weird.
---It also disables hitlag for the object, to prevent locking a
---player in a consecutive hitstop for various seconds.
---@param boom mobj_t
local function modifyBallhogBoom(boom)
	if not isValid(boom)
		return end

	boom.flags = $ | MF_DONTPUNT | MF_NOHITLAGFORME
end
--#endregion

--#region [ Toxomister ] --
--- Adds a delay of 1/3 of a second before being able to pass the toxomister cloud to another player.
--- Fixes players getting slowed down passing the cloud back and forth to each other.

---Delay before being able to pass the toxomister cloud back to the player who passed it to them.
local TOXOMISTER_CLOUD_RETURNDELAY = TICRATE / 3

---Modifies the behavior of Toxomister Clouds when being passed to another player.
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
	cloud.reactiontime = leveltime + TOXOMISTER_CLOUD_RETURNDELAY
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
--#endregion

--#region [ Flame Shield ] --
--- Using flame shield to attack a player reduces the maximum gauge by 1/4 for every hit.
--- When the gauge penalty removes all the gauge, flame dashing will not be able to do damage.

---Maximum amount of gauge the flameshield can have.
local FLAMESHIELD_MAX = 120

---Amount of hits the player can do with the flameshield before losing all their gauge.
local FLAMESHOTS_DIV = 4

---Regeneration rate for flameshield gauge after being capped.
local FLAMELENGTH_REGENRATE = TICRATE / 2

---Resets the flame shield gauge penalty of a player.
---@param player player_t
local function resetFlameLengthReduce(player)
	if isValid(player)
		player.flamelengthreduce = 0
	end
end

---Resets the flame shield gauge penalty when the flame shield disappears.
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

---Reduce the maximum flameshield gauge based on the amount of times attacked with it.
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
---@param player player_t
---@param target mobj_t
---@param inflictor mobj_t
---@param source mobj_t?
---@param damage integer
---@param damagetype damagetype
inflictorTypes[MT_PLAYER] = function(player, target, inflictor, source, damage, damagetype)
	local attacker = inflictor.player
	if not isValid(attacker)
		return end

	if attacker.flamedash and attacker.itemtype == KITEM_FLAMESHIELD
		---Gauge penalty exceeds the highest possible gauge,
		---make the flame shield not be able to damage anymore.
		if attacker.flamelengthreduce > FLAMESHIELD_MAX
			return false
		end

		---Count the amount of times this player attacked with a flameshield.
		attacker.flamelengthreduce = ($ or 0) + FLAMESHIELD_MAX / FLAMESHOTS_DIV
	end
end
--#endregion

--#region [ Stone Shoe ] --
--- Reduced duration from 15 seconds to 10 seconds.
--- Detaches the stone shoe from a player if the stone shoe got punted by something.

---Reduces the duration of Stone Shoe or removes it when it gets punted.
---@param stoneshoe mobj_t
local function stoneShoeThinker(stoneshoe)
	if not isValid(stoneshoe)
		return end

	---Reduce the duration.
	stoneshoe.fuse = INT32_MAX

	---If the stone shoe got punted, remove the object.
	---This allows the target player to move at a normal speed
	---instead of having an invisible object drag them down.
	if stoneshoe.reappear
		P_RemoveMobj(stoneshoe)
	end
end
--#endregion

addHook("ShouldDamage", damageModifierbyInflictor, MT_PLAYER)
addHook("TouchSpecial", toxomisterCloudPass, MT_TOXOMISTER_CLOUD)
addHook("PlayerSpawn", resetFlameLengthReduce)
addHook("MobjSpawn", modifyBallhogBoom, MT_BALLHOGBOOM)
addHook("MobjThinker", reduceFlameGaugeCap, MT_FLAMESHIELD)
addHook("MobjThinker", stoneShoeThinker, MT_STONESHOE)
addHook("MobjRemoved", resetFlameLengthReducebyFlameshield, MT_FLAMESHIELD)
--- Player Changes for MOGI Lounge
--- by Yellow/@GlowingTail

---Sets a player's Hyudoro state duration after entering a sonic loop.
---@param looppoint mobj_t
---@param pmo mobj_t
local function loopIntangibility(looppoint, pmo)
	if not (looppoint.valid and pmo.valid)
		return end

	---Object must be a valid player.
	local player = pmo.player
	if not (player and player.valid)
		return end

	---Set the Hyudoro state tics after making contact with a loop point.
	local invulntics = min(tonumber(mapheaderinfo[gamemap].loopintangibilitytics) or 0, UINT16_MAX)
	player.hyudorotimer = max($, invulntics)
end

---Sets a player's Hyudoro state duration while riding a turbine.
---It also forces the detachment to the turbine if a player is stuck on it.
---@param player player_t
local function turbineIntangibility(player)
	---Player must be on a turbine.
	if player.turbine == 0
		return end

	---Player's object must be valid.
	local pmo = player.mo
	if not (pmo and pmo.valid)
		return end

	---Player must be attached to a turbine object.
	local turbine = pmo.tracer
	if not (turbine and turbine.valid and turbine.type == MT_WATERPALACETURBINE)
		return end

	---Set Hyudoro state tics while on a turbine.
	local invulntics = min(tonumber(mapheaderinfo[gamemap].turbineintangibilitytics) or 0, UINT16_MAX)
	player.hyudorotimer = max($, invulntics)

	---Hyudoro and flashing are two different intangibility states with different properties. Flashing timer
	---gets activated for the same duration that Hyudoro is active to complete its intangible effect.
	---However, there is a check that prevents flashing timer and the hyudoro visuals from being updated
	---That check is whenever the player going through a turbine. Even though the Hyudoro state is applied
	---during the turbine, the flashing state that is meant to protect you from instawhip would never activated because of this check
	---So we set it manually here alongside Hyudoro timer too.
	player.flashing = max($, invulntics)

	---Reduce extremely high speeds on turbine.
	local excessiveSpeedThreshold = K_GetKartSpeed(player) * 5
	if player.speed > excessiveSpeedThreshold
		P_InstaThrust(pmo, player.turbineangle, excessiveSpeedThreshold)
	end
end

local MINGRADINGFACTOR = FRACUNIT / 2
local MAXGRADINGFACTOR = FRACUNIT * 3 / 2

local baseawardincrease = CV_RegisterVar{"ringbox_rewardincrease", 0, CV_NETVAR | CV_SHOWMODIF, {MIN = 0, MAX = UINT8_MAX - KSM_JACKPOT}}
local gradingfactor_req = CV_RegisterVar{"ringbox_rewardexpfactor", 1, CV_NETVAR | CV_FLOAT | CV_SHOWMODIF, {MIN = MINGRADINGFACTOR, MAX = MAXGRADINGFACTOR}}

---Upgrade the base ring award when a player's EXP rate is below a specific amount.
---@param player player_t
local function gradingFactorBaseRingAwardIncrease(player)
	if not player.ringboxdelay
		return end

	local itemroulette = player.itemroulette
	if not itemroulette.ringbox
		return end

	---Increase pay amount if EXP rate is below the set amount.
	if player.gradingfactor <= gradingfactor_req.value
		player.ringboxaward = itemroulette.itemlist[itemroulette.index + 1] + baseawardincrease.value
	end
end

---Runs player modifying functions.
---@param player player_t
local function playerThink(player)
	if not player.valid
		return end

	turbineIntangibility(player)
	gradingFactorBaseRingAwardIncrease(player)
end

addHook("TouchSpecial", loopIntangibility, MT_LOOPENDPOINT)
addHook("PlayerThink", playerThink)
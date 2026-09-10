--- Player Changes for MOGI Lounge
--- by Yellow/@GlowingTail

local MINGRADINGFACTOR = FRACUNIT / 2
local MAXGRADINGFACTOR = FRACUNIT * 3 / 2

local baseawardincrease = CV_RegisterVar{
	name = "ringbox_rewardincrease",
	flags = CV_NETVAR | CV_SHOWMODIF,
	defaultvalue = 2,
	possiblevalue = {MIN = 0, MAX = UINT8_MAX - KSM_JACKPOT}
}

local gradingfactor_req = CV_RegisterVar{
	name = "ringbox_rewardexpfactor",
	flags = CV_NETVAR | CV_FLOAT | CV_SHOWMODIF,
	defaultvalue = "0.6",
	possiblevalue = {MIN = MINGRADINGFACTOR, MAX = MAXGRADINGFACTOR}
}

---Validates an userdata.
---@param ud userdata
---@return boolean
local function isValid(ud)
	return ud and ud.valid
end

---Sets a player's Hyudoro state duration after entering a sonic loop.
---@param looppoint mobj_t
---@param pmo mobj_t
local function loopIntangibility(looppoint, pmo)
	if not (isValid(looppoint) and isValid(pmo))
		return end

	local player = pmo.player
	if not isValid(player)
		return end

	local invulntics = min(tonumber(mapheaderinfo[gamemap].loopintangibilitytics) or 0, UINT16_MAX)
	player.hyudorotimer = max($, invulntics)
end

---Sets a player's Hyudoro state duration while riding a turbine.
---It also forces the detachment to the turbine if a player is stuck on it.
---@param player player_t
local function turbineIntangibility(player)
	if player.turbine == 0
		return end

	local pmo = player.mo
	if not isValid(pmo)
		return end

	local turbine = pmo.tracer
	if not (isValid(turbine) and turbine.type == MT_WATERPALACETURBINE)
		return end

	local invulntics = min(tonumber(mapheaderinfo[gamemap].turbineintangibilitytics) or 0, UINT16_MAX)
	player.hyudorotimer = max($, invulntics)

	---Hyudoro and flashing are two different intangibility states with different properties. Flashing timer
	---gets activated for the same duration that Hyudoro is active to complete its intangible effect.
	---However, there is a check that prevents flashing timer and the hyudoro visuals from being updated
	---That check is whenever the player going through a turbine. Even though the Hyudoro state is applied
	---during the turbine, the flashing state that is meant to protect you from instawhip would never activated because of this check
	---So we set it manually here alongside Hyudoro timer too.
	player.flashing = max($, invulntics)

	---Reduce travel speed to prevent players getting stuck going at extremely high speeds.
	local excessiveSpeedThreshold = K_GetKartSpeed(player) * 5
	if player.speed > excessiveSpeedThreshold
		P_InstaThrust(pmo, player.turbineangle, excessiveSpeedThreshold)
	end
end

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
	if not isValid(player)
		return end

	turbineIntangibility(player)
	gradingFactorBaseRingAwardIncrease(player)
end

addHook("TouchSpecial", loopIntangibility, MT_LOOPENDPOINT)
addHook("PlayerThink", playerThink)
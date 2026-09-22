// Capsule Mod by Yellow/@GlowingTail
-- Let's put the unimaginable into these capsules!

local BUILD = 3
if (CapsuleMod and CapsuleMod.build >= BUILD) return end
local CapsuleMod = CapsuleMod or {build = BUILD}

local moddedCapsules = {}
local BATTLE_POWERUP_TIME = 30 * TICRATE
local SKINCOLOR_MATCHPLAYER = 1 << 16
local ITEMCAPSULE_THINGNUM = mobjinfo[MT_ITEMCAPSULE].doomednum
local SPR_RINGBOX = SPR_RBXR or freeslot('SPR_RBXR')
local SPR_POWERUP = SPR_PWRU or freeslot('SPR_PWRU')
local KSM_BAR, KSM_DOUBLEBAR, KSM_TRIPLEBAR, KSM_RING, KSM_SEVEN, KSM_JACKPOT = 0, 1, 2, 3, 4, 5

local countInGamePlayers = do
    local count = 0
    for player in players.iterate do
        if not player.valid continue end
        if player.spectator continue end
        count = $ + 1
    end

    return count
end

local function checkGametypeRules(capsuleType)
    if capsuleType:sub(0, 4) == 'KSM_'
        return (gametyperules & GTR_SPHERES) ~= GTR_SPHERES
    end

    if countInGamePlayers() < 2 return false end

    if capsuleType == 'POWERUP_BUMPER'
        return (gametyperules & GTR_BUMPERS) == GTR_BUMPERS
    
    elseif capsuleType == 'POWERUP_POINTS'
        return (gametyperules & GTR_POINTLIMIT) == GTR_POINTLIMIT
    end

    return true
end

local function setCapsuleSprite(capsule, item, sprite, frame, hOffset, vOffset, scale)
    item.sprite = sprite
    item.frame = frame | FF_PAPERSPRITE | FF_SEMIBRIGHT
    item.spritexoffset = hOffset * FU
    item.spriteyoffset = vOffset * FU
    item.spritexscale = FixedMul($, scale)
    item.spriteyscale = FixedMul($, scale)
end

local function setCapsuleSkinSprite(capsule, item, spr2, frame, hOffset, vOffset, scale)
    local player = players[0]
    if not (player and player.valid) return false end

    setCapsuleSprite(capsule, item, SPR_PLAY, frame, hOffset, vOffset, scale)
    item.skin = skins[player.skin].name
    item.sprite2 = spr2
    item.color = player.skincolor
end

local function giveRingBoxAward(player, award, delay)
    if (player.pflags & PF_RINGLOCK) return end
    if player.ringboxdelay return end

    player.ringboxaward = award
	player.ringboxdelay = delay

	S_StartSoundAtVolume(nil, sfx_slot00 + award, 100, player)
end

local function givePlayerLives(player, lives)
    P_GivePlayerLives(player, lives)
    S_StartSound(nil, sfx_cdfm73, player)
end

local function givePowerUp(player, powerup, amount)
    local pmo = player.mo
    if not (pmo and pmo.valid) return end

    if (powerup == POWERUP_SMONITOR) or (powerup == POWERUP_BARRIER) or (powerup == POWERUP_BADGE) or (powerup == POWERUP_SUPERFLICKY)
        K_GivePowerUp(player, powerup, amount)
        if amount < BATTLE_POWERUP_TIME / 3
            pmo.hitlag = 0
            pmo.flashing = 0
        end

    elseif (powerup == POWERUP_BUMPER)
        if amount >= 5
            K_GivePowerUp(player, powerup, 0)
            amount = $ - 5
        end

        for i = 1, amount do
            K_TakeBumpersFromPlayer(player, player, 1)
        end

    elseif (powerup == POWERUP_POINTS)
        if amount >= 6
            K_GivePowerUp(player, powerup, 0)
            amount = $ - 6
        else
            S_StartSound(pmo, sfx_token)
        end
        P_AddPlayerScore(player, amount)
    end
end

CapsuleMod.mods = {
    KSM_BAR =               {cooldown = 20, pickupdist = 1800,  color = SKINCOLOR_SUPERGOLD4,       thinkFunc = setCapsuleSprite,       thinkArgs = {SPR_RINGBOX, A, 0, 8, 8 * FU / 9}, touchFunc = giveRingBoxAward,   touchArgs = {KSM_BAR, 1},           init = checkGametypeRules},
    KSM_DOUBLEBAR =         {cooldown = 20, pickupdist = 1850,  color = SKINCOLOR_SUPERGOLD4,       thinkFunc = setCapsuleSprite,       thinkArgs = {SPR_RINGBOX, B, 0, 8, 8 * FU / 9}, touchFunc = giveRingBoxAward,   touchArgs = {KSM_DOUBLEBAR, 1},     init = checkGametypeRules},
    KSM_TRIPLEBAR =         {cooldown = 25, pickupdist = 1900,  color = SKINCOLOR_SUPERGOLD4,       thinkFunc = setCapsuleSprite,       thinkArgs = {SPR_RINGBOX, C, 0, 8, 8 * FU / 9}, touchFunc = giveRingBoxAward,   touchArgs = {KSM_TRIPLEBAR, 1},     init = checkGametypeRules},
    KSM_RING =              {cooldown = 25, pickupdist = 1933,  color = SKINCOLOR_SUPERGOLD3,       thinkFunc = setCapsuleSprite,       thinkArgs = {SPR_RINGBOX, D, 0, 8, 8 * FU / 9}, touchFunc = giveRingBoxAward,   touchArgs = {KSM_RING, 1},          init = checkGametypeRules},
    KSM_SEVEN =             {cooldown = 30, pickupdist = 1966,  color = SKINCOLOR_SUPERGOLD3,       thinkFunc = setCapsuleSprite,       thinkArgs = {SPR_RINGBOX, E, 0, 8, 8 * FU / 9}, touchFunc = giveRingBoxAward,   touchArgs = {KSM_SEVEN, 1},         init = checkGametypeRules},
    KSM_JACKPOT =           {cooldown = 30, pickupdist = 2000,  color = SKINCOLOR_SUPERGOLD3,       thinkFunc = setCapsuleSprite,       thinkArgs = {SPR_RINGBOX, F, 0, 8, 8 * FU / 9}, touchFunc = giveRingBoxAward,   touchArgs = {KSM_JACKPOT, 1},       init = checkGametypeRules},

    POWERUP_SMONITOR =      {cooldown = 60, pickupdist = 4000,  color = SKINCOLOR_SUPERPERIDOT3,    thinkFunc = setCapsuleSprite,       thinkArgs = {SPR_POWERUP, A, 0, 10, FRACUNIT},  touchFunc = givePowerUp,        touchArgs = {POWERUP_SMONITOR},     init = checkGametypeRules,  amountMod = TICRATE},
    POWERUP_BARRIER =       {cooldown = 60, pickupdist = 3500,  color = SKINCOLOR_SUPERSKY3,        thinkFunc = setCapsuleSprite,       thinkArgs = {SPR_POWERUP, B, 0, 10, FRACUNIT},  touchFunc = givePowerUp,        touchArgs = {POWERUP_BARRIER},      init = checkGametypeRules,  amountMod = TICRATE},
    POWERUP_BUMPER =        {cooldown = 60, pickupdist = 3000,  color = SKINCOLOR_SUPERORANGE3,     thinkFunc = setCapsuleSprite,       thinkArgs = {SPR_POWERUP, C, 0, 10, FRACUNIT},  touchFunc = givePowerUp,        touchArgs = {POWERUP_BUMPER},       init = checkGametypeRules,  amountMod = 1},
    POWERUP_BADGE =         {cooldown = 60, pickupdist = 3500,  color = SKINCOLOR_SUPERPURPLE4,     thinkFunc = setCapsuleSprite,       thinkArgs = {SPR_POWERUP, D, 0, 10, FRACUNIT},  touchFunc = givePowerUp,        touchArgs = {POWERUP_BADGE},        init = checkGametypeRules,  amountMod = TICRATE},
    POWERUP_SUPERFLICKY =   {cooldown = 60, pickupdist = 3500,  color = SKINCOLOR_SUPERTAN3,        thinkFunc = setCapsuleSprite,       thinkArgs = {SPR_POWERUP, E, 0, 10, FRACUNIT},  touchFunc = givePowerUp,        touchArgs = {POWERUP_SUPERFLICKY},  init = checkGametypeRules,  amountMod = TICRATE,    min = TICRATE},
    POWERUP_POINTS =        {cooldown = 60, pickupdist = 3000,  color = SKINCOLOR_SUPERPURPLE3,     thinkFunc = setCapsuleSprite,       thinkArgs = {SPR_POWERUP, F, 0, 10, FRACUNIT},  touchFunc = givePowerUp,        touchArgs = {POWERUP_POINTS},       init = checkGametypeRules,  amountMod = 1},

    EXTRA_LIFE =            {cooldown = FU, pickupdist = 0,     color = SKINCOLOR_MATCHPLAYER,      thinkFunc = setCapsuleSkinSprite,   thinkArgs = {SPR2_XTRA, B, 16, 40, FU},         touchFunc = givePlayerLives,    touchArgs = {},                     init = G_GametypeUsesLives, amountMod = 1}
}

local function spawnModdedCapsule(x, y, z, type, amount, scale, noGrav, gravFlip)
    local mod = CapsuleMod.mods[type]
    if not mod return end

    local capsule = P_SpawnMobj(x, y, z, MT_ITEMCAPSULE)
    capsule.capsulemodType = type
    capsule.capsulemodAmount = amount

    if noGrav == true
        capsule.flags = $ | MF_NOGRAVITY

    elseif noGrav == false
        capsule.flags = $ & ~MF_NOGRAVITY

    elseif not P_IsObjectOnGround(capsule)
        capsule.flags = $ | MF_NOGRAVITY
    end

    if gravFlip
        capsule.flags2 = $ | MF2_OBJECTFLIP
        capsule.eflags = $ | MFE_VERTICALFLIP
    end

    local color = mod.color
    if color & SKINCOLOR_MATCHPLAYER
        color = $ & ~SKINCOLOR_MATCHPLAYER
        color = players[$].skincolor or 0
    end
    capsule.extravalue2 = color or $

    capsule.extravalue1 = scale or $
    capsule.scalespeed = capsule.extravalue1 / TICRATE

    capsule.threshold = KITEM_SNEAKER
    capsule.movecount = mod.amountMod and (amount / mod.amountMod) or 0
    
    table.insert(moddedCapsules, capsule)
    return capsule
end

local function removeMapthingMobj(mapthing)
    local mobj = mapthing.mobj
    if not (mobj and mobj.valid) return end

    P_RemoveMobj(mobj)
end

CapsuleMod.mapspawn = do
    for mapthing in mapthings.iterate do
        if mapthing.type ~= ITEMCAPSULE_THINGNUM continue end

        local capsuleModType = mapthing.stringargs[0]
        if not capsuleModType continue end

        local mod = CapsuleMod.mods[capsuleModType]
        if (mod == nil) continue end            

        if mod.init and (mod.init(capsuleModType, mapthing) == false)
            removeMapthingMobj(mapthing)
            continue end

        if modeattacking
            removeMapthingMobj(mapthing)
            continue end
        
        local x, y, z = mapthing.x << FRACBITS, mapthing.y << FRACBITS, mapthing.z << FRACBITS
		local flip = (mapthing.options & MTF_OBJECTFLIP) > 0

        if flip
            z = P_CeilingzAtPos(x, y, $, 0) - $
        else
            z = P_FloorzAtPos(x, y, $, 0) + $
        end

        spawnModdedCapsule(x, y, z, capsuleModType, mapthing.args[1] * (mod.amountMod or 1), FixedMul(mapthing.scale, mapobjectscale), nil, flip)
        removeMapthingMobj(mapthing)
    end
end

function CapsuleMod.fuse(capsule)
	if not capsule.valid return end

	local mod = CapsuleMod.mods[capsule.capsulemodType]
	if (mod == nil) return end

	local newCapsule = spawnModdedCapsule(capsule.x, capsule.y, capsule.z, capsule.capsulemodType, capsule.capsulemodAmount, capsule.extravalue1, (capsule.flags & MF_NOGRAVITY) > 0, (capsule.flags2 & MF2_OBJECTFLIP) > 0)
	P_RemoveMobj(capsule)
end

function CapsuleMod.touch(capsule, toucher)
	if not (capsule.valid and toucher.valid) return end
    if (capsule.scale < capsule.extravalue1) return end

	local mod = CapsuleMod.mods[capsule.capsulemodType]
	if (mod == nil) return end

	local player = toucher.player
	if not (player and player.valid) return true end

    local pickupDist = FixedMul(mod.pickupdist, mapobjectscale)

    if player.distancetofinish and (abs(player.capsulemodpickupdist - player.distancetofinish) < pickupDist) return true end
    if not P_CanPickupItem(player, 3) return true end

    capsule.threshold = KCAPSULE_RING
    capsule.movecount = 0

    player.capsulemodpickupdist = player.distancetofinish
    mod.touchFunc(player, unpack({[#mod.touchArgs + 1] = max(capsule.capsulemodAmount, mod.min or 1), unpack(mod.touchArgs)}))
	P_KillMobj(capsule)
    table.insert(moddedCapsules, capsule)
end

CapsuleMod.think = do
    for c = 1, #moddedCapsules do
        local capsule = moddedCapsules[c]
        if not (capsule and capsule.valid)
            table.remove(moddedCapsules, c)
            continue end

        local mod = CapsuleMod.mods[capsule.capsulemodType]
        if (mod == nil)
            table.remove(moddedCapsules, c)
            continue end

        if (capsule.fuse > 0)
            capsule.fuse = mod.cooldown * TICRATE
            table.remove(moddedCapsules, c)
            continue end

        local item = capsule.tracer
        if not (item and item.valid) continue end

        local process = mod.thinkFunc(capsule, item, unpack(mod.thinkArgs))
        if process == true
            continue
        
        elseif process == false
            P_RemoveMobj(capsule)
        end

        table.remove(moddedCapsules, c)
    end
end

function CapsuleMod.initPlayer(player)
    player.capsulemodpickupdist = INT32_MAX
end

function CapsuleMod.netSync(n)
    moddedCapsules = n($)
end

if rawget(_G, 'CapsuleMod') ~= nil return end

addHook('MapLoad', CapsuleMod.mapspawn)
addHook('MobjFuse', CapsuleMod.fuse, MT_ITEMCAPSULE)
addHook('TouchSpecial', CapsuleMod.touch, MT_ITEMCAPSULE)
addHook('ThinkFrame', CapsuleMod.think)
addHook('PlayerSpawn', CapsuleMod.initPlayer)
addHook('NetVars', CapsuleMod.netSync)

rawset(_G, 'CapsuleMod', CapsuleMod)
rawset(_G, 'P_SpawnModdedCapsule', spawnModdedCapsule)
print(('\132Capsule Mod\x80 has been loaded. \134[Build #%d]'):format(CapsuleMod.build))
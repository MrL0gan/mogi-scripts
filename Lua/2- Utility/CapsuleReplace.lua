// Item Capsule Replacer revamp by Yellow/@GlowingTail [ 5th Revision ]

// Original script by Mr.Logan
-- because we cant edit maps with capsule placement issues for mogi

---Enabling this will add a HUD hook that shows the IDs of the capsules as well as what the capsules are meant to be before being replaced by something else.
local debug = false

local capsuleParameters, argToParam = {
    KITEM_SAD               = {"Sad",                       KITEM_SAD,              0},
    KITEM_NONE              = {"None",                      KITEM_NONE,             0},
    KITEM_SNEAKER           = {"Sneaker",                   KITEM_SNEAKER,          1},
    KITEM_ROCKETSNEAKER     = {"Rocket Sneaker" ,           KITEM_ROCKETSNEAKER,    1},
    KITEM_INVINCIBILITY     = {"Invincibility",             KITEM_INVINCIBILITY,    1},
    KITEM_BANANA            = {"Banana",                    KITEM_BANANA,           1},
    KITEM_EGGMAN            = {"Eggman",                    KITEM_EGGMAN,           1},
    KITEM_ORBINAUT          = {"Orbinaut",                  KITEM_ORBINAUT,         1},
    KITEM_JAWZ              = {"Jawz",                      KITEM_JAWZ,             1},
    KITEM_MINE              = {"Mine",                      KITEM_MINE,             1},
    KITEM_LANDMINE          = {"Landmine",                  KITEM_LANDMINE,         1},
    KITEM_BALLHOG           = {"Ballhog",                   KITEM_BALLHOG,          1},
    KITEM_SPB               = {"Self-Propelled Bomb",       KITEM_SPB,              1,  alt = true},
    KITEM_GROW              = {"Grow",                      KITEM_GROW,             1},
    KITEM_SHRINK            = {"Shrink",                    KITEM_SHRINK,           1},
    KITEM_LIGHTNINGSHIELD   = {"Lightning Shield",          KITEM_LIGHTNINGSHIELD,  1},
    KITEM_BUBBLESHIELD      = {"Bubble Shield",             KITEM_BUBBLESHIELD,     1},
    KITEM_FLAMESHIELD       = {"Flame Shield",              KITEM_FLAMESHIELD,      1},
    KITEM_HYUDORO           = {"Hyudoro",                   KITEM_HYUDORO,          1},
    KITEM_POGOSPRING        = {"Pogo Spring",               KITEM_POGOSPRING,       1},
    KITEM_SUPERRING         = {"Super Ring",                KITEM_SUPERRING,        1},
    KITEM_KITCHENSINK       = {"Kitchen Sink",              KITEM_KITCHENSINK,      1},
    KITEM_DROPTARGET        = {"Drop Target",               KITEM_DROPTARGET,       1},
    KITEM_GARDENTOP         = {"Garden Top",                KITEM_GARDENTOP,        1},
    KITEM_GACHABOM          = {"Gachabom",                  KITEM_GACHABOM,         1},
    KITEM_STONESHOE         = {"Stone Shoe",                KITEM_STONESHOE,        1},
    KITEM_TOXOMISTER        = {"Toxomister",                KITEM_TOXOMISTER,       1},

    KCAPSULE_RING           = {"Rings",                     KCAPSULE_RING,          1},
    KCAPSULE_SPB            = {"Auto Self-Propelled Bomb",  KITEM_SPB,              1,  alt = false},

---CapsuleMod is required for these replacements.
    KSM_BAR                 = {"Ringbox Bar",               "KSM_BAR",              0},
    KSM_DOUBLEBAR           = {"Ringbox Double Bar",        "KSM_DOUBLEBAR",        0},
    KSM_TRIPLEBAR           = {"Ringbox Triple Bar",        "KSM_TRIPLEBAR",        0},
    KSM_RING                = {"Ringbox Ring",              "KSM_RING",             0},
    KSM_SEVEN               = {"Ringbox Seven",             "KSM_SEVEN",            0},
    KSM_JACKPOT             = {"Ringbox Jackpot",           "KSM_JACKPOT",          0},
    POWERUP_SMONITOR        = {"Super Power",               "POWERUP_SMONITOR",     30, amountMod = TICRATE},
    POWERUP_BARRIER         = {"Mega Barrier",              "POWERUP_BARRIER",      30, amountMod = TICRATE},
    POWERUP_BUMPER          = {"Bumper Restock",            "POWERUP_BUMPER",       5},
    POWERUP_BADGE           = {"Rhythm Badge",              "POWERUP_BADGE",        30, amountMod = TICRATE},
    POWERUP_SUPERFLICKY     = {"Super Flicky",              "POWERUP_SUPERFLICKY",  30, amountMod = TICRATE},
    POWERUP_POINTS          = {"Bonus",                     "POWERUP_POINTS",       6},
}, {}

for param, info in pairs(capsuleParameters) do
    info = {
        name = $[1],
        const = param,
        type = $[2],
        minAmount = $[3],
        alt = $.alt,
        amountMod = $.amountMod
    }

    if param:sub(0, 6) == "KITEM_"
        local value = _G[param]
        info.replaceName = param:sub(7):lower()
        info.patch = "ISPY\$K_GetItemPatch(value, true):sub(5)\"
        argToParam[value] = info
    end

    capsuleParameters[param] = info
end

capsuleParameters.KCAPSULE_RING.replaceName = "rings"
capsuleParameters.KCAPSULE_RING.patch = "K_SRING1"
argToParam[0] = capsuleParameters.KCAPSULE_RING

local capsuleQueue = setmetatable({}, {__index = table})
local capsuleList = {}

local function isValid(ud)
	return ud and ud.valid
end

local function splitString(string, separator)
	local strTable = {}
    for split in string:gmatch("[^\$separator\]+") do
        table.insert(strTable, tonumber(split) or split:upper())
    end

	return strTable
end

local function catchMapCapsule(capsule, mapthing)
    if debug
        capsuleList[#mapthing] = {
            mobj = capsule,
            thing = mapthing,
            x = capsule.x,
            y = capsule.y,
            z = capsule.z,
            threshold = capsule.threshold,
            movecount = capsule.movecount
        }
    end

    local mapinfo = mapheaderinfo[gamemap]
    if (mapinfo.mogi_capsules and mapinfo.mogi_capsules:lower() ~= "true")
        return end

    if not isValid(mapthing)
        return end

    local spawnItem = argToParam[mapthing.args[0]]
    if not spawnItem
        return end

    local replaceInfo = mapinfo["mogicap_\$#mapthing\"] or mapinfo["mogicap_\$spawnItem.replaceName\"]
    if not replaceInfo
        return end

    replaceInfo = splitString($, ",")
    if not capsuleParameters[replaceInfo[1]]
        if leveltime <= starttime
            print("Attempted to replace Capsule #\$#mapthing\ (\$spawnItem.name\) with '\$replaceInfo[1]\', which is not a valid type.")
        end
        return end

    replaceInfo = {
        mobj = capsule,
        amount = tonumber($[2]) or 0,
        param = capsuleParameters[$[1]]
    }

    capsuleQueue:insert(replaceInfo)
end

local function setupCapsuleMod(capsule, modType, amount)
    capsule.capsulemodType = modType
    capsule.capsulemodAmount = amount or 0
    capsule.spawnpoint = nil
    capsule.fuse = 1
end

local processQueuedCapsules = do
    for c = 1, #capsuleQueue do
        local replaceInfo = capsuleQueue:remove()
        local parameters = replaceInfo.param

        local capsule = replaceInfo.mobj
        if not isValid(capsule)
            continue end

        local replaceType = parameters.type
        local replaceAmount = (replaceInfo.amount or parameters.minAmount) * (parameters.amountMod or 1)

        if type(replaceType) == "number"
            if ((replaceType <= KITEM_NONE) or (replaceType >= NUMKARTITEMS)) and (replaceType ~= KCAPSULE_RING)
                if debug
                    print("Capsule #\$#capsule.spawnpoint\ has been removed as instructed by the replacement (\$parameters.const\).")
                end
                P_RemoveMobj(capsule)
                continue end

            capsule.threshold = replaceType
            capsule.movecount = replaceAmount

            if parameters.alt == true
                capsule.flags2 = $ | MF2_STRONGBOX
            elseif parameters.alt == false
                capsule.flags2 = $ & ~MF2_STRONGBOX
            end

        elseif type(replaceType) == "string"
            setupCapsuleMod(capsule, replaceType, replaceAmount)
        end
    end
end

addHook("MapThingSpawn", catchMapCapsule, MT_ITEMCAPSULE)
addHook("ThinkFrame", processQueuedCapsules)

if debug
    assert(SG_ObjectTracking,
        "SG_ObjectTracking() function is required for drawing capsule info.")

    local function drawCapsuleInfo(drawlib, player, camera)
        local namestem = drawlib.cachePatch("K_NAMEST")
        local itmframe = drawlib.cachePatch("ISPYBG")

        for id, mCap in pairs(capsuleList) do
            local capsulePoint = mCap
            if isValid(capsulePoint.mobj)
                capsulePoint = $.mobj
            end

            if R_PointToDist(capsulePoint.x, capsulePoint.y) > 4095 * mapobjectscale
            or abs(R_PointToAngle(capsulePoint.x, capsulePoint.y) - camera.angle) > ANG105
                continue end

            local drawCoords = SG_ObjectTracking(drawlib, player, camera, capsulePoint)
            drawCoords.x, drawCoords.y = $ / FU, $ / FU

            local function drawPatch(x, y, patch)
                drawlib.draw(drawCoords.x + x - (patch.width / 2), drawCoords.y + y - (patch.height / 2), patch, 0)
            end

            drawPatch(3, 8, namestem)
            drawlib.drawFill(drawCoords.x + 6, drawCoords.y - 16, 20, 3, 31)
            drawlib.drawFill(drawCoords.x + 5, drawCoords.y - 15, 20, 1, 0)
            drawlib.drawString(drawCoords.x + 22, drawCoords.y - 25, #mCap.thing, 0, "thin-right")

            local parameters = argToParam[mCap.thing.args[0]]
            if not parameters
                continue end

            if type(parameters.patch) == "string"
                parameters.patch = drawlib.patchExists($) and drawlib.cachePatch($) or nil
            end

            if not parameters.patch
                continue end

            drawPatch(28, -21, itmframe)
            drawPatch(28, -21, parameters.patch)
        end
    end

    local clearStoredCapsules = do
        capsuleList = {}
    end

    addHook("HUD", drawCapsuleInfo)
    addHook("MapChange", clearStoredCapsules)
end
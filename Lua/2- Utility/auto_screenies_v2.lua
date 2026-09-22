-- how many tics intermission has already ran
local int_tic = 0

-- when the scores appear on the intermission screen
local sorttic = 0
-- when intermission ends
local inttimer = 0

-- is auto_screenies active?
-- clientside variable
local take_screenies = false

addHook('IntermissionThinker', function ()
	if int_tic == 0 then
		-- copied from source code:
		inttimer = CV_FindVar('inttime').value * TICRATE
		sorttic = max((inttimer/2) - 2*TICRATE, 2*TICRATE)

		if take_screenies then
			COM_BufInsertText(consoleplayer, 'screenshot')
		end
	end

	if take_screenies then
		-- take a screenshot twice:
		-- 1) when the scores slide over (this is before they're totaled but it still displays the pending paycheck)
		-- 2) right before the intermission ends
		if int_tic == sorttic + 16 or int_tic == inttimer - 1 then
			COM_BufInsertText(consoleplayer, 'screenshot')
		end
	end

	int_tic = $ + 1
end)

addHook('MapChange', function ()
	-- intermission has ended
	int_tic = 0
end)

COM_AddCommand('auto_screenies', function ()
	-- toggle automatic screenies
	take_screenies = not take_screenies

	-- send a chat message notifying EVERYONE that you turned it on/off
	COM_BufInsertText(consoleplayer, '_notify_auto_screenies ' .. (take_screenies and 'on' or 'off'))
end, COM_LOCAL)

COM_AddCommand('_notify_auto_screenies', function (p, n)
	-- this handles sending the chat message
	chatprint('\x83*' .. p.name .. ' turned ' .. n .. ' AUTOMATIC SCREENIES')
end)

local function hud(v)
	-- if automatic screenies is turned on, place a watermark at the bottom of the screen
	if take_screenies then
		v.drawString(160, 191, 'AUTOMATIC SCREENIES', V_GREENMAP | V_SNAPTOBOTTOM, 'thin-center')
	end
end

addHook('HUD', hud, 'game')
addHook('HUD', hud, 'intermission')

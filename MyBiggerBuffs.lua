BiggerBuffs = {}


--split string (stack overflow)
local function strsplit(inputstr, sep)
    if sep == nil then
        sep = "%s"
    end
	local t = {}
	local i = 0
    for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
		t[i] = str
		i = i + 1
    end
    return t
end


-- Send this function a group/raid member's unitID or GUID and it will return their raid frame.
-- THANK YOU LUA GOD ASAKAWA and weakauras team
local function GetFrame(target)
    if not UnitExists(target) then
        if type(target) == "string" and target:find("Player") then
            target = select(6,GetPlayerInfoByGUID(target))
        else
            return
        end
    end

    --Lastly, default frames
    if CompactRaidFrameContainer.groupMode == "flush" then
        for _,frame in pairs(CompactRaidFrameContainer.flowFrames) do
            if frame.unit and frame:IsVisible() and UnitIsUnit(frame.unit, target) then
                return frame
            end
        end
    else
        for i = 1,8 do
            for j = 1,5 do
				local frame = _G["CompactRaidGroup"..i.."Member"..j]
                if frame and frame:IsVisible() and frame.unit and UnitIsUnit(frame.unit, target)
                then
                    return frame
                end
            end
        end
    end
    -- debug - uncomment below if you're seeing issues
    --print("GlowOnDemand (WA) - No frame found. Target sent: ".. target)
end


-- loops the raid group, callcacks with frame name
local loopAllMembers = function(callback)
	local it = 1;
	if not UnitInRaid('player') then return end
	local nplayers = GetNumGroupMembers()
	while it <= nplayers do
		local playerName = GetRaidRosterInfo(it)
		if playerName == nil then return end
		local frameName = GetFrame(playerName)
		if frameName ~= nil then callback(frameName); end
		it = it + 1;
	end
end


-- [ slash commands ] --

SLASH_BIGGERBUFFS1 = "/bigger";
function SlashCmdList.BIGGERBUFFS ( msg )

	local splitted = strsplit(msg);

	if splitted[0] == "scale" and tonumber(splitted[1]) ~= nil then

		biggerbuffsSaved.Options.scalefactor = tonumber(splitted[1]);
		print("Updated.");
		print("In order to get a display update, switch between raid profiles.");

	elseif splitted[0] == "maxbuffs" and tonumber(splitted[1]) ~= nil then


		biggerbuffsSaved.Options.maxbuffs = tonumber(splitted[1]);

		print("Updated.");
		print("In order to get a display update, switch between raid profiles.");

	elseif splitted[0] == "hidenames" and tonumber(splitted[1]) ~= nil then

		biggerbuffsSaved.Options.hidenames = tonumber(splitted[1]);

	else

		print ("Invalid arguments. Possible options are:");
		print ("scale xx - Aura size factor. Default is 15. Blizzard's is 11.");
		print ("maxbuffs xx");
		print ("hidenames 0/1 - hides names in combat.")

	end

end


local function setSize(f)
	-- buff sizes
	local options = DefaultCompactUnitFrameSetupOptions;
	local scale = min(options.height / 36, options.width / 72);
	local buffSize = biggerbuffsSaved.Options.scalefactor * scale;

	loopAllMembers(function(f2)
		if not f2 then return end
		for i=1, #f2.buffFrames do
			f2.buffFrames[i]:SetSize(buffSize, buffSize);
		end
	end);

end


local function showBuff(buffFrame, icon, count, expirationTime, duration)

	--paste
	buffFrame.icon:SetTexture(icon);
	if ( count > 1 ) then
		local countText = count;
		if ( count >= 10 ) then
			countText = BUFF_STACKS_OVERFLOW;
		end

		buffFrame.count:Show();
		buffFrame.count:SetText(countText);
	else
		buffFrame.count:Hide();
	end

	if ( expirationTime and expirationTime ~= 0 ) then
		local startTime = expirationTime - duration;
		buffFrame.cooldown:SetCooldown(startTime, duration);
		buffFrame.cooldown:Show();
	else
		buffFrame.cooldown:Hide();
	end
	buffFrame:Show();
	--end paste

end


local function activateMe()

	if started == true then return end

	started = true;

	setSize();

	hooksecurefunc("CompactUnitFrame_SetMaxBuffs", function(frame,numbuffs)

		if InCombatLockdown() == true then return end
		-- insert missing frames (for >3 buffs)
		local maxbuffs = biggerbuffsSaved.Options.maxbuffs;
		local child;
		while table.getn(frame.buffFrames) < maxbuffs do

			child = CreateFrame("Button",frame:GetName().."Buff"..(table.getn(frame.buffFrames)+1),frame,"CompactBuffTemplate");

		end

		frame.maxBuffs = maxbuffs;

	end);

	hooksecurefunc("DefaultCompactUnitFrameSetup", function(f)
		if InCombatLockdown() == true then return end
		setSize();
	end);


	hooksecurefunc("CompactUnitFrame_UpdateBuffs", function(frame)

		local additionalBuffs = BiggerBuffs.MY_ADDITIONAL_BUFFS or {}

		--copy-pasted and adapted from blizz UI code
		if ( not frame.optionTable.displayBuffs ) then
			CompactUnitFrame_HideAllBuffs(frame);
			return;
		end

		--slow
		local frameNum = 1
		local classBuffIdx = 1
		local additionalBuffIdx = 1
		local _,_,clazz = UnitClass(frame.displayedUnit);
		while ( frameNum <= frame.maxBuffs ) do
			local buffFrame = frame.buffFrames[frameNum];
			if buffFrame:IsShown() then

				frameNum = frameNum + 1;

			else
				if BiggerBuffs.CDS[clazz] == nil then return end
				while ( classBuffIdx <= #BiggerBuffs.CDS[clazz] ) do
					local buffName,rank, icon, count, debuffType, duration, expirationTime, unitCaster, isStealable
						, shouldConsolidate,spellId = UnitBuff(frame.displayedUnit, BiggerBuffs.CDS[clazz][classBuffIdx]);
					classBuffIdx = classBuffIdx + 1;
					if buffName ~= nil then
						showBuff(buffFrame, icon, count, expirationTime, duration)
						frameNum = frameNum + 1;
						break;
					end
				end

				while ( additionalBuffIdx <= #additionalBuffs ) do
					local buffName = additionalBuffs[additionalBuffIdx]
					local buffName, rank, icon, count, debuffType, duration, expirationTime, unitCaster, isStealable
						, shouldConsolidate,spellId = UnitBuff(frame.displayedUnit, buffName);
					additionalBuffIdx  = additionalBuffIdx + 1
					if buffName ~= nil and unitCaster == 'player' then
						showBuff(buffFrame, icon, count, expirationTime, duration)
						frameNum = frameNum + 1;
						break;
					end
				end



				return;
			end

		end


	end);

end


local started = false;

-- load saved variables
local frame = CreateFrame("FRAME");
frame:RegisterEvent("ADDON_LOADED");
frame:RegisterEvent("READY_CHECK");
frame:RegisterEvent("PLAYER_REGEN_ENABLED");
frame:RegisterEvent("PLAYER_REGEN_DISABLED");



function frame:OnEvent(event, arg1)

	if event == "ADDON_LOADED" and arg1 == "MyBiggerBuffs" then

		if biggerbuffsSaved == nil then
			biggerbuffsSaved = {
				["Options"] = {
					["scalefactor"] = 15 ,
					["maxbuffs"] = 5 ,
					["hidenames"] = 0
				}
			};
		end

		local options = biggerbuffsSaved.Options

		--version 4
		if options.maxbuffs == nil then options.maxbuffs = 3; end
		--version 6
		if options.hidenames == nil then options.hidenames = 0; end

		activateMe()


	elseif event == "PLAYER_REGEN_ENABLED" and biggerbuffsSaved.Options.hidenames == 1 and started == true then

		loopAllMembers(function(frameName)
			_G[frameName.."Name"]:Show();
		end);

	elseif event == "PLAYER_REGEN_DISABLED" and biggerbuffsSaved.Options.hidenames == 1 and started == true then

		loopAllMembers(function(frameName)
			_G[frameName.."Name"]:Hide();
		end);

	end

end


local function showBuff(buffFrame, icon, count, expirationTime, duration)

	--paste
	buffFrame.icon:SetTexture(icon);
	if ( count > 1 ) then
		local countText = count;
		if ( count >= 10 ) then
			countText = BUFF_STACKS_OVERFLOW;
		end

		buffFrame.count:Show();
		buffFrame.count:SetText(countText);
	else
		buffFrame.count:Hide();
	end

	if ( expirationTime and expirationTime ~= 0 ) then
		local startTime = expirationTime - duration;
		buffFrame.cooldown:SetCooldown(startTime, duration);
		buffFrame.cooldown:Show();
	else
		buffFrame.cooldown:Hide();
	end
	buffFrame:Show();
	--end paste

end



frame:SetScript("OnEvent", frame.OnEvent);


BiggerBuffs.MY_ADDITIONAL_BUFFS = {
	"Tranquil Mist"
}


BiggerBuffs.CDS = {
	[ 6 ] = { -- dk
		"Icebound Fortitude",
		"Anti-Magic Shell",
		"Vampiric Blood",
		"Corpse Shield"
	} ,
	[ 11 ] = { --dr00d
		"Barkskin",
		"Survival Instincts"
	} ,
	[ 3 ] = { -- hunter
		"Aspect of the turtle"
	} ,
	[ 8 ] = { --mage
		"Ice Block",
		"Evanesce",
		"Greater Invisibility",
		"Alter Time"
	} ,
	[ 10 ] = { --monk
		"Zen Meditation",
		"Diffuse Magic",
		"Dampen Harm",
		"Touch of Karma"
	} ,
	[ 2 ] = { --paladin
		"Divine Shield",
		"Divine Protection",
		"Ardent Defender",
		"Aegis of Light",
		"Eye for an Eye",
		"Shield of Vengeance",
		"Guardian of Ancient Kings",
		"Seraphim",
		"Guardian of the fortress"
	} ,
	[ 5 ] = { --priest
		"Dispersion"
	} ,
	[ 4 ] = { --rogue
		"Evasion",
		"Feint",
		"Cloak of Shadows",
		"Readiness",
		"Riposte"
	} ,
	[ 7 ] = { --shaman
		"Astral Shift",
		"Shamanistic Rage"
	} ,
	[ 9 ] = { --lock
		"Unending Resolve",
		"Dark Pact"
	} ,
	[ 1 ] = { --warrior
		"Shield Wall",
		"Spell Reflection",
		"Last Stand",
		"Die By The Sword"
	},
	[ 12 ] = { --dh
		"Blur",
		"Darkness"
	}
};

local EXTERNALS = {
	"Ironbark",
	"Life Cocoon",
	"Blessing of Protection",
	"Hand of Sacrifice",
	"Hand of Purity",
	"Pain Suppression",
	"Guardian Spirit",
	"Safeguard",
	"Vigilance",
	--"Power Word: Shield"
};


for key1,val1 in pairs(BiggerBuffs.CDS) do

	for it=1 , #EXTERNALS do

		tinsert(val1,EXTERNALS[it]);

	end

end
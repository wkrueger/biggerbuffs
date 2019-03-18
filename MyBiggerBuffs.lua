-- luacheck: globals BiggerBuffs BiggerBuffs_Utils BiggerBuffs_CooldownsData biggerbuffsSaved
-- luacheck: globals hooksecurefunc InCombatLockdown CompactUnitFrame_HideAllBuffs UnitClass

BiggerBuffs = BiggerBuffs or {}

-- import utils
local Utl = BiggerBuffs_Utils
-- local WA_GetUnitAura = Utl.WA_GetUnitAura
local WA_GetUnitBuff = Utl.WA_GetUnitBuff
-- local WA_GetUnitDebuff = Utl.WA_GetUnitDebuff
-- local WA_IterateGroupMembers = Utl.WA_IterateGroupMembers
-- local WA_ClassColorName = Utl.WA_ClassColorName
local strsplit = Utl.strsplit
-- local GetFrame = Utl.GetFrame
local loopAllMembers = Utl.loopAllMembers

-- import cooldowns
local Cooldowns = BiggerBuffs_CooldownsData
local MY_ADDITIONAL_BUFFS = Cooldowns.MY_ADDITIONAL_BUFFS

-- [ slash commands ] --

SLASH_BIGGERBUFFS1 = "/bigger"
function SlashCmdList.BIGGERBUFFS(msg)
  local splitted = strsplit(msg)

  if splitted[0] == "scale" and tonumber(splitted[1]) ~= nil then
    biggerbuffsSaved.Options.scalefactor = tonumber(splitted[1])
    print("Updated.")
    print("In order to get a display update, switch between raid profiles.")
  elseif splitted[0] == "maxbuffs" and tonumber(splitted[1]) ~= nil then
    biggerbuffsSaved.Options.maxbuffs = tonumber(splitted[1])
    print("Updated.")
    print("In order to get a display update, switch between raid profiles.")
  elseif splitted[0] == "hidenames" and tonumber(splitted[1]) ~= nil then
    biggerbuffsSaved.Options.hidenames = tonumber(splitted[1])
  elseif splitted[0] == "rowsize" and tonumber(splitted[1]) ~= nil and tonumber(splitted[1]) >= 3 then
    biggerbuffsSaved.Options.rowsize = tonumber(splitted[1])
    print("Rowsize updated.")
    print("In order to get a display update, switch between raid profiles.")
  else
    print("Invalid arguments. Possible options are:")
    print("scale xx - Aura size factor. Default is 15. Blizzard's is 11.")
    print("maxbuffs xx")
    print("hidenames 0/1 - hides names in combat.")
  end
end

-- [ startup ] --

local started = false
local addonFrameInit, activateMe, setSize, showBuff, createBuffFrames

addonFrameInit = function(self, event, arg1)
  if event == "ADDON_LOADED" and arg1 == "MyBiggerBuffs" then
    if biggerbuffsSaved == nil then
      biggerbuffsSaved = {
        ["Options"] = {
          ["scalefactor"] = 15,
          ["maxbuffs"] = 5,
          ["hidenames"] = 0,
          ["rowsize"] = 3
        }
      }
    end

    local options = biggerbuffsSaved.Options

    --"schema migrations"

    --version 4
    if options.maxbuffs == nil then
      options.maxbuffs = 3
    end
    --version 6
    if options.hidenames == nil then
      options.hidenames = 0
    end
    --multiple rows version
    if options.rowsize == nil then
      options.rowsize = 3
    end

    activateMe()
  elseif event == "PLAYER_REGEN_ENABLED" and biggerbuffsSaved.Options.hidenames == 1 and started == true then
    loopAllMembers(
      function(frameName)
        _G[frameName .. "Name"]:Show()
      end
    )
  elseif event == "PLAYER_REGEN_DISABLED" and biggerbuffsSaved.Options.hidenames == 1 and started == true then
    loopAllMembers(
      function(frameName)
        _G[frameName .. "Name"]:Hide()
      end
    )
  end
end

activateMe = function()
  if started == true then
    return
  end
  started = true
  setSize()

  hooksecurefunc("CompactUnitFrame_UpdateAll", createBuffFrames)
  hooksecurefunc(
    "DefaultCompactUnitFrameSetup",
    function(f)
      if InCombatLockdown() == true then
        return
      end
      setSize()
    end
  )

  hooksecurefunc(
    "CompactUnitFrame_UpdateBuffs",
    function(frame)
      local additionalBuffs = MY_ADDITIONAL_BUFFS or {}

      --copy-pasted and adapted from blizz UI code
      if (not frame.optionTable.displayBuffs) then
        CompactUnitFrame_HideAllBuffs(frame)
        return
      end

      -- debug code to fill all buffs with icons
      -- for i=1,10 do
      -- local name = frame:GetName() .. "Buff"
      -- local frame = _G[name .. i]
      -- if frame == nil then break end
      -- frame.icon:SetTexture(132089)
      -- frame.count:SetText(i)
      -- frame.count:Show()
      -- frame:Show()
      -- end
      -- if true then return end
      -- end debuff code

      local frameNum = 1
      local additionalBuffIdx = 1
      while (frameNum <= frame.maxBuffs) do
        local buffFrame = frame.buffFrames[frameNum]
        if buffFrame:IsShown() then
          frameNum = frameNum + 1
        else
          while (additionalBuffIdx <= #additionalBuffs) do
            local buffName = additionalBuffs[additionalBuffIdx]
            local _, icon, _, _, duration, expirationTime, unitCaster = WA_GetUnitBuff(frame.displayedUnit, buffName)
            additionalBuffIdx = additionalBuffIdx + 1
            if buffName ~= nil and unitCaster == "player" then
              showBuff(buffFrame, icon, nil, expirationTime, duration)
              frameNum = frameNum + 1
              break
            end
          end
          return
        end
      end
    end
  )
end

setSize = function(f)
  local options = DefaultCompactUnitFrameSetupOptions
  local scale = min(options.height / 36, options.width / 72)
  local buffSize = biggerbuffsSaved.Options.scalefactor * scale

  loopAllMembers(
    function(f2)
      if not f2 then
        return
      end
      for i = 1, #f2.buffFrames do
        f2.buffFrames[i]:SetSize(buffSize, buffSize)
      end
    end
  )
end

showBuff = function(buffFrame, icon, count, expirationTime, duration)
  if icon == nil then
    return
  end
  --paste from blizzard ui code
  buffFrame.icon:SetTexture(icon)
  if (count or 0 > 1) then
    local countText = count
    if (count >= 10) then
      countText = BUFF_STACKS_OVERFLOW
    end

    buffFrame.count:Show()
    buffFrame.count:SetText(countText)
  else
    buffFrame.count:Hide()
  end

  if (type(expirationTime) == "number" and expirationTime ~= 0) then
    local startTime = expirationTime - duration
    buffFrame.cooldown:SetCooldown(startTime, duration)
    buffFrame.cooldown:Show()
  else
    buffFrame.cooldown:Hide()
  end
  buffFrame:Show()
  --end paste
end

createBuffFrames = function(frame)
  if InCombatLockdown() == true then
    return
  end

  -- insert and reposition missing frames (for >3 buffs)
  local maxbuffs = biggerbuffsSaved.Options.maxbuffs
  local rowsize = biggerbuffsSaved.Options.rowsize or 3

  for i = 4, maxbuffs do
    local name = frame:GetName() .. "Buff"
    local child = _G[name .. i] or CreateFrame("Button", name .. i, frame, "CompactBuffTemplate")
    child:ClearAllPoints()
    if math.fmod(i - 1, rowsize) == 0 then -- (i-1) % 3 == 0
      child:SetPoint("BOTTOMRIGHT", _G[name .. i - rowsize], "TOPRIGHT")
    else
      child:SetPoint("BOTTOMRIGHT", _G[name .. i - 1], "BOTTOMLEFT")
    end
  end
  frame.maxBuffs = maxbuffs
end

local frame = CreateFrame("FRAME")
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("READY_CHECK")
frame:RegisterEvent("PLAYER_REGEN_ENABLED")
frame:RegisterEvent("PLAYER_REGEN_DISABLED")
frame:SetScript("OnEvent", addonFrameInit)

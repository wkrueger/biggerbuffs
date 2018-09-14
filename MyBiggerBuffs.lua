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
local CDS = Cooldowns.CDS
local EXTERNALS = Cooldowns.EXTERNALS

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
  else
    print("Invalid arguments. Possible options are:")
    print("scale xx - Aura size factor. Default is 15. Blizzard's is 11.")
    print("maxbuffs xx")
    print("hidenames 0/1 - hides names in combat.")
  end
end

-- [ startup ] --

local started = false
local addonFrameInit, activateMe, setSize, showBuff

addonFrameInit = function(self, event, arg1)
  if event == "ADDON_LOADED" and arg1 == "MyBiggerBuffs" then
    if biggerbuffsSaved == nil then
      biggerbuffsSaved = {
        ["Options"] = {
          ["scalefactor"] = 15,
          ["maxbuffs"] = 5,
          ["hidenames"] = 0
        }
      }
    end

    local options = biggerbuffsSaved.Options

    --version 4
    if options.maxbuffs == nil then
      options.maxbuffs = 3
    end
    --version 6
    if options.hidenames == nil then
      options.hidenames = 0
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

  hooksecurefunc(
    "CompactUnitFrame_SetMaxBuffs",
    function(frame, numbuffs)
      if InCombatLockdown() == true then
        return
      end
      -- insert missing frames (for >3 buffs)
      local maxbuffs = biggerbuffsSaved.Options.maxbuffs
      local child
      while table.getn(frame.buffFrames) < maxbuffs do
        child =
          CreateFrame(
          "Button",
          frame:GetName() .. "Buff" .. (table.getn(frame.buffFrames) + 1),
          frame,
          "CompactBuffTemplate"
        )
      end
      frame.maxBuffs = maxbuffs
    end
  )

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

      local frameNum = 1
      local classBuffIdx = 1
      local additionalBuffIdx = 1
      local _, _, clazz = UnitClass(frame.displayedUnit)
      while (frameNum <= frame.maxBuffs) do
        local buffFrame = frame.buffFrames[frameNum]
        if buffFrame:IsShown() then
          frameNum = frameNum + 1
        else
          if CDS[clazz] == nil then
            return
          end
          while (classBuffIdx <= #CDS[clazz]) do
            --print("while " .. tostring(CDS[clazz][classBuffIdx]))
            local buffName, icon, _, _, duration, expirationTime, unitCaster =
              WA_GetUnitBuff(frame.displayedUnit, CDS[clazz][classBuffIdx])
            classBuffIdx = classBuffIdx + 1
            if buffName ~= nil then
              --print("found " .. buffName .. " - " .. expirationTime .. " " .. duration)
              local fromSelf = unitCaster == "player" and frame.displayedUnit ~= "player"
              if not fromSelf then
                showBuff(buffFrame, icon, nil, expirationTime, duration)
                frameNum = frameNum + 1
                break
              end
            end
          end

          while (additionalBuffIdx <= #additionalBuffs) do
            local buffName = additionalBuffs[additionalBuffIdx]
            local _, icon, _, _, duration, expirationTime, unitCaster = WA_GetUnitBuff(frame.displayedUnit, buffName)
            additionalBuffIdx = additionalBuffIdx + 1
            if buffName ~= nil and unitCaster ~= "player" then
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
  print("show " .. tostring(icon) .. " " .. tostring(buffFrame))
  buffFrame:Show()
  --end paste
end

local frame = CreateFrame("FRAME")
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("READY_CHECK")
frame:RegisterEvent("PLAYER_REGEN_ENABLED")
frame:RegisterEvent("PLAYER_REGEN_DISABLED")
frame:SetScript("OnEvent", addonFrameInit)

BiggerBuffs = BiggerBuffs or {}

-- import utils
local Utl = BiggerBuffs_Utils
local strsplit = Utl.strsplit
local loopAllMembers = Utl.loopAllMembers

-- import cooldowns
local MY_ADDITIONAL_BUFFS = BiggerBuffs_CooldownsData.MY_ADDITIONAL_BUFFS
local BANNED_BUFFS = BiggerBuffs_CooldownsData.BANNED_BUFFS
local MY_ADDITIONAL_BUFFS_IDX = {}
for it = 1, #MY_ADDITIONAL_BUFFS do
  MY_ADDITIONAL_BUFFS_IDX[MY_ADDITIONAL_BUFFS[it]] = true
end

-- locals
local activateMe, started = false, createBuffFrames

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

local frame = CreateFrame("FRAME")
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("READY_CHECK")
frame:RegisterEvent("PLAYER_REGEN_ENABLED")
frame:RegisterEvent("PLAYER_REGEN_DISABLED")
frame:SetScript(
  "OnEvent",
  function(self, event, arg1)
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
)

activateMe = function()
  if started == true then
    return
  end
  started = true

  hooksecurefunc("CompactUnitFrame_UpdateAll", createBuffFrames)

  local prevhook = _G.CompactUnitFrame_UtilShouldDisplayBuff
  _G.CompactUnitFrame_UtilShouldDisplayBuff = function(...)
    local buffName, _, _, _, _, _, source = ...
    -- if buffName == "Devotion Aura" then
    --   print(Utl.vdump({...}))
    -- end
    -- local buffName, _, _, _, _, _, source, _, _, spellId = UnitAura(...)
    if source == "player" then
      if BANNED_BUFFS[buffName] ~= nil then
        return false
      end
      if MY_ADDITIONAL_BUFFS_IDX[buffName] ~= nil then
        return true
      end
    end
    return prevhook(...)
  end
end

createBuffFrames = function(frame)
  if InCombatLockdown() == true then
    return
  end

  -- insert and reposition missing frames (for >3 buffs)
  local maxbuffs = biggerbuffsSaved.Options.maxbuffs
  local rowsize = biggerbuffsSaved.Options.rowsize or 3

  local frameName = frame:GetName() .. "Buff"
  for i = 4, maxbuffs do
    local child = _G[frameName .. i] or CreateFrame("Button", frameName .. i, frame, "CompactBuffTemplate")
    child:ClearAllPoints()
    if math.fmod(i - 1, rowsize) == 0 then -- (i-1) % 3 == 0
      child:SetPoint("BOTTOMRIGHT", _G[frameName .. i - rowsize], "TOPRIGHT")
    else
      child:SetPoint("BOTTOMRIGHT", _G[frameName .. i - 1], "BOTTOMLEFT")
    end
  end
  frame.maxBuffs = maxbuffs

  -- update size
  local options = DefaultCompactUnitFrameSetupOptions
  local scale = min(options.height / 36, options.width / 72)
  local buffSize = biggerbuffsSaved.Options.scalefactor * scale
  for i = 1, maxbuffs do
    local child = _G[frameName .. i]
    if child then
      child:SetSize(buffSize, buffSize)
    end
  end
end

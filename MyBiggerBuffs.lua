BiggerBuffs = BiggerBuffs or {}

-- blizz ui
local hooksecurefunc = hooksecurefunc
local CreateFrame = CreateFrame
local SlashCmdList = SlashCmdList
local InCombatLockdown = InCombatLockdown

-- import local
local Utl = BiggerBuffs_Utils
local Saved = BiggerBuffs.Saved

-- locals
local started = false

-- [ slash commands ] --

SLASH_BIGGERBUFFS1 = "/bigger"
function SlashCmdList.BIGGERBUFFS(msg)
  local splitted = Utl.strsplit(msg)
  local command = splitted[0]
  local option = splitted[1]

  if command == "scale" and tonumber(option) ~= nil then
    Saved.setOption("scalefactor", tonumber(option))
    print("Updated.")
    print("In order to get a display update, switch between raid profiles.")
  elseif command == "maxbuffs" and tonumber(option) ~= nil then
    Saved.setOption("maxbuffs", tonumber(option))
    print("Updated.")
    print("In order to get a display update, switch between raid profiles.")
  elseif command == "hidenames" and tonumber(option) ~= nil then
    Saved.setOption("hidenames", tonumber(option))
  elseif command == "rowsize" and tonumber(option) ~= nil and tonumber(option) >= 3 then
    Saved.setOption("rowsize", tonumber(option))
    print("Rowsize updated.")
    print("In order to get a display update, switch between raid profiles.")
  else
    BiggerBuffs.ShowUI()
  end
end

-- [ startup ] --

local function createBuffFrames(frame)
  if InCombatLockdown() == true then
    return
  end

  if frame:IsForbidden() then
    return
  end

  local name = frame:GetName()
  if not name or not name:match('^Compact') then
    return
  end

  -- insert and reposition missing frames (for >3 buffs)
  local maxbuffs = biggerbuffsSaved.Options.maxbuffs
  local rowsize = biggerbuffsSaved.Options.rowsize or 3
  local fname = frame:GetName()
  if not fname then
    return
  end
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

  -- this taints the frames
  if maxbuffs ~= 3 then
    frame.maxBuffs = maxbuffs
  end

  -- -- update size
  local scale = 1.25
  local buffSize = Saved.getOption("scalefactor") * scale
  for i = 1, maxbuffs do
    local child = _G[frameName .. i]
    if child then
      child:SetSize(buffSize, buffSize)
    end
  end
end

local function checkFrame(frame)
  if not issecurevariable(frame, "action") and not InCombatLockdown() then
    frame.action = nil
    frame:SetAttribute("action");
  end
end

local function activateMe()
  if started == true then
    return
  end
  started = true

  for _, frame in ipairs(ActionBarButtonEventsFrame.frames) do
    hooksecurefunc(frame, "UpdateAction", checkFrame)
  end
  hooksecurefunc("CompactUnitFrame_UpdateAll", createBuffFrames)

  local prevhook = _G.AuraUtil.ShouldDisplayBuff
  _G.AuraUtil.ShouldDisplayBuff = function(...)
    local bannedBuffsIdx = Saved.root().bannedBuffsIdx
    local additionalBuffsIdx = Saved.root().additionalBuffsIdx

    local source, buffId = ...
    if source == "player" then
      if bannedBuffsIdx[buffId] ~= nil then
        return false
      end
      if additionalBuffsIdx[buffId] ~= nil then
        return true
      end
    end
    return prevhook(...)
  end
end

local frame = CreateFrame("FRAME")
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("READY_CHECK")
frame:RegisterEvent("PLAYER_REGEN_ENABLED")
frame:RegisterEvent("PLAYER_REGEN_DISABLED")
frame:SetScript(
  "OnEvent",
  function(self, event, arg1)
    if event == "ADDON_LOADED" and arg1 == "MyBiggerBuffs" then
      Saved.init()
      activateMe()
    end
  end
)

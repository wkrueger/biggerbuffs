local UnitAura = UnitAura
-- Unit Aura functions that return info about the first Aura matching the spellName or spellID given on the unit.
local WA_GetUnitAura = function(unit, spell, filter)
  for i = 1, 40 do
    local name, _, _, _, _, _, _, _, _, spellId = UnitAura(unit, i, filter)
    if not name then
      return
    end
    if spell == spellId or spell == name then
      return UnitAura(unit, i, filter)
    end
  end
end

local WA_GetUnitBuff = function(unit, spell, filter)
  return WA_GetUnitAura(unit, spell, filter)
end

local WA_GetUnitDebuff = function(unit, spell, filter)
  filter = filter and filter .. "|HARMFUL" or "HARMFUL"
  return WA_GetUnitAura(unit, spell, filter)
end

-- Function to assist iterating group members whether in a party or raid.
local WA_IterateGroupMembers = function(reversed, forceParty)
  local unit = (not forceParty and IsInRaid()) and "raid" or "party"
  local numGroupMembers =
    (forceParty and GetNumSubgroupMembers() or GetNumGroupMembers()) - (unit == "party" and 1 or 0)
  local i = reversed and numGroupMembers or (unit == "party" and 0 or 1)
  return function()
    local ret
    if i == 0 and unit == "party" then
      ret = "player"
    elseif i <= numGroupMembers and i > 0 then
      ret = unit .. i
    end
    i = i + (reversed and -1 or 1)
    return ret
  end
end

-- Wrapping a unit's name in its class colour is very common in custom Auras
local WA_ClassColorName = function(unit)
  local _, class = UnitClass(unit)
  if not class then
    return
  end
  return RAID_CLASS_COLORS[class]:WrapTextInColorCode(UnitName(unit))
end

--split string (stack overflow)
local function strsplit(inputstr, sep)
  if sep == nil then
    sep = "%s"
  end
  local t = {}
  local i = 0
  for str in string.gmatch(inputstr, "([^" .. sep .. "]+)") do
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
      target = select(6, GetPlayerInfoByGUID(target))
    else
      return
    end
  end

  --Lastly, default frames
  if CompactRaidFrameContainer.groupMode == "flush" then
    for _, frame in pairs(CompactRaidFrameContainer.flowFrames) do
      if frame.unit and frame:IsVisible() and UnitIsUnit(frame.unit, target) then
        return frame
      end
    end
  else
    for i = 1, 8 do
      for j = 1, 5 do
        local frame = _G["CompactRaidGroup" .. i .. "Member" .. j]
        if frame and frame:IsVisible() and frame.unit and UnitIsUnit(frame.unit, target) then
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
  local it = 1
  if not UnitInRaid("player") then
    return
  end
  local nplayers = GetNumGroupMembers()
  while it <= nplayers do
    local playerName = GetRaidRosterInfo(it)
    if playerName == nil then
      return
    end
    local frameName = GetFrame(playerName)
    if frameName ~= nil then
      callback(frameName)
    end
    it = it + 1
  end
end

local function vdump(o)
  if type(o) == "table" then
    local s = "{ "
    for k, v in pairs(o) do
      if type(k) ~= "number" then
        k = '"' .. k .. '"'
      end
      s = s .. "[" .. k .. "] = " .. vdump(v) .. ","
    end
    return s .. "} "
  else
    return tostring(o)
  end
end

_G.BiggerBuffs_Utils = {
  WA_GetUnitAura = WA_GetUnitAura,
  WA_GetUnitBuff = WA_GetUnitBuff,
  WA_GetUnitDebuff = WA_GetUnitDebuff,
  WA_IterateGroupMembers = WA_IterateGroupMembers,
  WA_ClassColorName = WA_ClassColorName,
  strsplit = strsplit,
  GetFrame = GetFrame,
  loopAllMembers = loopAllMembers,
  vdump = vdump
}

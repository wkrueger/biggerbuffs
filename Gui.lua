BiggerBuffs = BiggerBuffs or {}
local Saved = BiggerBuffs.Saved

-- imports

local LibStub = LibStub
local AceGUI = LibStub("AceGUI-3.0")

local function trueKeys(obj)
  local out = {}
  local it = 1
  for k, v in pairs(obj) do
    if v then
      out[it] = k
      it = it + 1
    end
  end
  return out
end

local function strSplit(str, sep)
  if sep == nil then
    sep = "%s"
  end

  local res = {}
  local func = function(w)
    table.insert(res, w)
  end

  string.gsub(str, "[^" .. sep .. "]+", func)
  return res
end

local function map(arr, fn)
  local out = {}
  for k, v in pairs(arr) do
    out[k] = fn(v)
  end
  return out
end

local function trim(s)
  -- from PiL2 20.4
  return (s:gsub("^%s*(.-)%s*$", "%1"))
end

local shown = false

local function ShowUI()
  local frame = AceGUI:Create("Frame")
  frame:SetTitle("Hello Bigger Buffs")
  frame:SetLayout("Flow")

  local _scale = AceGUI:Create("EditBox")
  _scale:SetLabel("Icon scale")
  _scale:SetWidth(200)
  _scale:SetText(Saved.getOption("scalefactor"))
  frame:AddChild(_scale)

  local _maxbuffs = AceGUI:Create("EditBox")
  _maxbuffs:SetLabel("Max Buffs")
  _maxbuffs:SetWidth(200)
  _maxbuffs:SetText(Saved.getOption("maxbuffs"))
  frame:AddChild(_maxbuffs)

  local _rowsize = AceGUI:Create("EditBox")
  _rowsize:SetLabel("Row Size")
  _rowsize:SetWidth(200)
  _rowsize:SetText(Saved.getOption("rowsize"))
  frame:AddChild(_rowsize)

  local _additionalBuffs = AceGUI:Create("MultiLineEditBox")
  _additionalBuffs:SetLabel("Additional Buffs")
  _additionalBuffs:SetWidth(300)
  _additionalBuffs:SetHeight(200)
  local buffsTxt = table.concat(Saved.root().additionalBuffs, "\n")
  _additionalBuffs:SetText(buffsTxt)
  frame:AddChild(_additionalBuffs)

  local _bannedBuffs = AceGUI:Create("MultiLineEditBox")
  _bannedBuffs:SetLabel("Banned Buffs")
  _bannedBuffs:SetWidth(300)
  _bannedBuffs:SetHeight(200)
  _bannedBuffs:SetText("")
  local bannedTxt = table.concat(trueKeys(Saved.root().bannedBuffs), "\n")
  _bannedBuffs:SetText(bannedTxt)
  frame:AddChild(_bannedBuffs)

  frame:SetCallback(
    "OnClose",
    function(wg)
      Saved.setOption("scalefactor", tonumber(_scale:GetText()))
      Saved.setOption("maxbuffs", tonumber(_maxbuffs:GetText()))
      Saved.setOption("rowsize", tonumber(_rowsize:GetText()))
      Saved.setAdditionalBuffs(strSplit(_additionalBuffs, "\n"))
      Saved.setBannedBuffs(strSplit(_bannedBuffs, "\n"))
    end
  )
end

BiggerBuffs.ShowUI = ShowUI

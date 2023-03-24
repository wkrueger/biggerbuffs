BiggerBuffs = BiggerBuffs or {}
local Saved = BiggerBuffs.Saved

-- imports

local LibStub = LibStub
local AceGUI = LibStub("AceGUI-3.0")


local function strSplit(inputstr)
  local t = {}
  for str in string.gmatch(inputstr, "([^" .. "\n" .. "]+)") do
    table.insert(t, str)
  end
  return t
end

local function map(arr, fn)
  local out = {}
  for k, v in pairs(arr) do
    local val = fn(v)
    if val:len() > 0 then
      out[k] = val
    end
  end
  return out
end

local function trim(s)
  -- from PiL2 20.4
  return (s:gsub("^%s*(.-)%s*$", "%1"))
end

local function ShowUI()
  local frame = AceGUI:Create("Frame")
  frame:SetTitle("Bigger Buffs")
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

  local _message = AceGUI:Create("Label")
  _message:SetFullWidth(true)
  _message:SetText("Some settings are only reflected after switching between two raid profiles.")
  frame:AddChild(_message)

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
  local bannedTxt = table.concat(Saved.root().bannedBuffs, "\n")
  _bannedBuffs:SetText(bannedTxt)
  frame:AddChild(_bannedBuffs)

  local _message = AceGUI:Create("Label")
  _message:SetFullWidth(true)
  _message:SetText("Only the first word on each line is taken into account.")
  frame:AddChild(_message)

  frame:SetCallback(
    "OnClose",
    function(wg)
      Saved.setOption("scalefactor", tonumber(_scale:GetText()))
      Saved.setOption("maxbuffs", tonumber(_maxbuffs:GetText()))
      Saved.setOption("rowsize", tonumber(_rowsize:GetText()))
      Saved.setAdditionalBuffs(
        map(
          strSplit(_additionalBuffs:GetText()),
          function(str)
            return trim(str)
          end
        )
      )
      Saved.setBannedBuffs(
        map(
          strSplit(_bannedBuffs:GetText()),
          function(str)
            return trim(str)
          end
        )
      )
    end
  )
end

BiggerBuffs.ShowUI = ShowUI

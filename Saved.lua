BiggerBuffs = BiggerBuffs or {}
local Utils = _G.BiggerBuffs_Utils

local function init()
  if biggerbuffsSaved == nil then
    biggerbuffsSaved = {
      ["Options"] = {
        ["scalefactor"] = 15,
        ["maxbuffs"] = 5,
        ["hidenames"] = 0,
        ["rowsize"] = 3
      },
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

  if biggerbuffsSaved.additionalBuffs == nil or biggerbuffsSaved.Version == nil then
    BiggerBuffs.Saved.setAdditionalBuffs(
      {
        "203553 (Focused Growth)",
        "200390 (Cultivation)",
        "207386 (Spring Blossoms)",
        "216327 (Light's Grace)",
      }
    )
  end

  if biggerbuffsSaved.bannedBuffs == nil or
      biggerbuffsSaved.Version == nil or biggerbuffsSaved.bannedBuffsIdx == nil then
    BiggerBuffs.Saved.setBannedBuffs({
      "465 (Devotion Aura)"
    })
  end

  biggerbuffsSaved.Version = 92001


end

local function mapAuraNameToId(auraName)
  local split = Utils.strsplit(auraName, ' ')
  local num = tonumber(split[0])
  return num
end

BiggerBuffs.Saved = {
  ["init"] = init,
  ["setOption"] = function(k, v)
    biggerbuffsSaved.Options[k] = v
  end,
  ["getOption"] = function(k)
    return biggerbuffsSaved.Options[k]
  end,
  ["root"] = function()
    return biggerbuffsSaved
  end,
  ["setAdditionalBuffs"] = function(arr)
    local indexed = {}
    for it = 1, #arr do
      local found = mapAuraNameToId(arr[it])
      if found ~= nil then
        indexed[found] = true
      end
    end
    biggerbuffsSaved.additionalBuffs = arr
    biggerbuffsSaved.additionalBuffsIdx = indexed
  end,
  ["setBannedBuffs"] = function(list)
    local indexed = {}
    for it = 1, #list do
      local found = mapAuraNameToId(list[it])
      if found ~= nil then
        indexed[found] = true
      end
    end
    biggerbuffsSaved.bannedBuffs = list
    biggerbuffsSaved.bannedBuffsIdx = indexed
  end
}

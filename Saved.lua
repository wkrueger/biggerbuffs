BiggerBuffs = BiggerBuffs or {}

local function init()
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

  if biggerbuffsSaved.additionalBuffs == nil then
    BiggerBuffs.Saved.setAdditionalBuffs(
      {
        "Focused Growth",
        "Cultivation",
        "Spring Blossoms",
        "Grove Tending",
        "Light's Grace",
        "Extend Life"
      }
    )
  end

  if biggerbuffsSaved.bannedBuffs == nil then
    biggerbuffsSaved.bannedBuffs = {
      ["Devotion Aura"] = true -- Devotion Aura
    }
  end
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
    biggerbuffsSaved.additionalBuffs = arr
    local additionalBuffsIdx = {}
    for it = 1, #arr do
      additionalBuffsIdx[arr[it]] = true
    end
    biggerbuffsSaved.additionalBuffsIdx = additionalBuffsIdx
  end,
  setBannedBuffs = function(list)
    local keys = {}
    for _, v in pairs(list) do
      keys[v] = true
    end
    biggerbuffsSaved.bannedBuffs = keys
  end
}

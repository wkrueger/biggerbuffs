-- additional buffs list (still quite not up-to-date with 8.x)

local MY_ADDITIONAL_BUFFS = {
  "Blessed Portents", -- azerite
  "Concentrated Mending" -- azerite
}

local CDS = {
  [6] = {
    -- dk
    "Icebound Fortitude",
    "Anti-Magic Shell",
    "Vampiric Blood",
    "Corpse Shield"
  },
  [11] = {
    --dr00d
    "Barkskin",
    "Survival Instincts"
  },
  [3] = {
    -- hunter
    "Aspect of the turtle"
  },
  [8] = {
    --mage
    "Ice Block",
    "Evanesce",
    "Greater Invisibility",
    "Alter Time"
  },
  [10] = {
    --monk
    "Zen Meditation",
    "Diffuse Magic",
    "Dampen Harm",
    "Touch of Karma"
  },
  [2] = {
    --paladin
    "Divine Shield",
    "Divine Protection",
    "Ardent Defender",
    "Aegis of Light",
    "Eye for an Eye",
    "Shield of Vengeance",
    "Guardian of Ancient Kings",
    "Guardian of the fortress"
  },
  [5] = {
    --priest
    "Dispersion"
  },
  [4] = {
    --rogue
    "Evasion",
    "Feint",
    "Cloak of Shadows",
    "Readiness",
    "Riposte"
  },
  [7] = {
    --shaman
    "Astral Shift",
    "Shamanistic Rage"
  },
  [9] = {
    --lock
    "Unending Resolve",
    "Dark Pact"
  },
  [1] = {
    --warrior
    "Shield Wall",
    "Spell Reflection",
    "Last Stand",
    "Die By The Sword"
  },
  [12] = {
    --dh
    "Blur"
  }
}

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
  "Darkness"
}

for key1, val1 in pairs(CDS) do
  for it = 1, #EXTERNALS do
    tinsert(val1, EXTERNALS[it])
  end
end

BiggerBuffs_CooldownsData = {
  MY_ADDITIONAL_BUFFS = MY_ADDITIONAL_BUFFS,
  CDS = CDS,
  EXTERNALS = EXTERNALS
}

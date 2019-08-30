-- additional buffs list (still quite not up-to-date with 8.x)

local MY_ADDITIONAL_BUFFS = {
  "Cultivation",
  "Spring Blossoms",
  "Grove Tending",
  "Light's Grace"
}

local BANNED_BUFFS = {
  [210320] = true, -- Devotion Aura
  [303698] = true -- Luminous Jellyweed
}

BiggerBuffs_CooldownsData = {
  MY_ADDITIONAL_BUFFS = MY_ADDITIONAL_BUFFS,
  BANNED_BUFFS = BANNED_BUFFS
}

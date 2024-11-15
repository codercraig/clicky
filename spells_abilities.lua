-- spells_abilities.lua

local spells_abilities = {}

spells_abilities.WHM = {
    spells = {
        "Cure", "Cure II", "Cure III", "Cure IV", "Cure V", "Curaga", "Curaga II", "Curaga III",
        "Raise", "Raise II", "Reraise", "Reraise II", "Poisona", "Paralyna", "Blindna", "Silena",
        "Stona", "Viruna", "Cursna", "Dia", "Dia II", "Banish", "Banish II", "Banish III", 
        "Banishga", "Banishga II", "Diaga", "Holy", "Holy II", "Protect", "Protect II", "Protect III", 
        "Protect IV", "Shell", "Shell II", "Shell III", "Shell IV", "Regen", "Regen II", "Regen III",
        "Regen IV", "Auspice", "Erase", "Haste", "Barstonra", "Barwatera", "Baraera", "Barfira",
        "Barblizzara", "Barthundra", "Barstone", "Barwater", "Baraero", "Barfire", "Barblizzard", 
        "Barthunder", "Barpoison", "Barparalyze", "Barsleep", "Barblind", "Barsilence", "Barpetrify",
        "Barvirus", "Boost", "Aquaveil", "Stoneskin", "Blink", "Deodorize", "Sneak", 
        "Invisible", "Reraise", "Teleport-Mea", "Teleport-Dem", "Teleport-Holla", 
        "Teleport-Altep", "Teleport-Yhoat", "Teleport-Vahzl",
        "Protectra", "Protectra II", "Protectra III", "Protectra IV", "Shellra", "Shellra II", 
        "Shellra III", "Shellra IV", "Reraise III", "Enlight"
    },
    abilities = {
        "Benediction",
        "Divine Seal",
        "Afflatus Solace",
        "Afflatus Misery",
        "Devotion",
        "Martyr"
    }
}

spells_abilities.BLM = {
    spells = {
        "Stone", "Water", "Aero", "Fire", "Blizzard", "Thunder", "Stone II", "Water II",
        "Aero II", "Fire II", "Blizzard II", "Thunder II", "Stone III", "Water III", "Aero III",
        "Fire III", "Blizzard III", "Thunder III", "Stonega", "Waterga", "Aeroga", "Firaga",
        "Blizzaga", "Thundaga", "Stonega II", "Waterga II", "Aeroga II", "Firaga II",
        "Blizzaga II", "Thundaga II", "Poison", "Poison II", "Poisonga", "Bio", "Bio II",
        "Drain", "Aspir", "Warp", "Warp II", "Escape", "Tractor", "Sleep", "Sleep II",
        "Bind", "Break", "Dispel", "Stun"
    },
    abilities = {
        "Manafont",
        "Elemental Seal",
        "Tranquil Heart"
    }
}

return spells_abilities

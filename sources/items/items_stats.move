module staking_odyssey::items_stats;

use staking_odyssey::rarity::{Self, Rarity};

public struct WeaponStats has copy, drop, store {
    attack: u64,
    crit_chance: u64, 
}

public struct ArmorStats has copy, drop, store {
    defense: u64,
    block_chance: u64,
}

public fun get_sword_attack(sword: &WeaponStats): u64 {
    sword.attack
}
public fun get_sword_crit_chance(sword: &WeaponStats): u64 {
    sword.crit_chance
}

public fun get_armor_defense(armor: &ArmorStats): u64 {
    armor.defense
}

public fun get_armor_block_chance(armor: &ArmorStats): u64 {
    armor.block_chance
}

public fun get_weapon_stats(rarity: Rarity, level: u8): WeaponStats {
    if (rarity::is_common(rarity)) {
        let stats = vector[
            WeaponStats { attack: 100, crit_chance: 1000 },
            WeaponStats { attack: 150, crit_chance: 1200 },
            WeaponStats { attack: 200, crit_chance: 1400 },
            WeaponStats { attack: 250, crit_chance: 1600 },
            WeaponStats { attack: 300, crit_chance: 2000 },
        ];
        *vector::borrow(&stats, (level - 1) as u64)
    } else if (rarity::is_rare(rarity)) {
        let stats = vector[
            WeaponStats { attack: 200, crit_chance: 1500 },
            WeaponStats { attack: 300, crit_chance: 2000 },
            WeaponStats { attack: 400, crit_chance: 2500 },
            WeaponStats { attack: 500, crit_chance: 3000 },
            WeaponStats { attack: 600, crit_chance: 3500 },
        ];
        *vector::borrow(&stats, (level - 1) as u64)
    } else { 
        let stats = vector[
            WeaponStats { attack: 400, crit_chance: 2500 },
            WeaponStats { attack: 600, crit_chance: 3000 },
            WeaponStats { attack: 800, crit_chance: 3500 },
            WeaponStats { attack: 1000, crit_chance: 4000 },
            WeaponStats { attack: 1200, crit_chance: 5000 },
        ];
        *vector::borrow(&stats, (level - 1) as u64)
    }
}

public fun get_armor_stats(rarity: Rarity, level: u8): ArmorStats {
    if (rarity::is_common(rarity)) {
        let stats = vector[
            ArmorStats { defense: 30, block_chance: 800 },
            ArmorStats { defense: 45, block_chance: 1000 },
            ArmorStats { defense: 60, block_chance: 1200 },
            ArmorStats { defense: 75, block_chance: 1400 },
            ArmorStats { defense: 90, block_chance: 1600 },
        ];
        *vector::borrow(&stats, (level - 1) as u64)
    } else if (rarity::is_rare(rarity)) {
        let stats = vector[
            ArmorStats { defense: 60, block_chance: 1200 },
            ArmorStats { defense: 90, block_chance: 1600 },
            ArmorStats { defense: 120, block_chance: 2000 },
            ArmorStats { defense: 150, block_chance: 2400 },
            ArmorStats { defense: 180, block_chance: 2800 },
        ];
        *vector::borrow(&stats, (level - 1) as u64)
    } else { // LEGENDARY
        let stats = vector[
            ArmorStats { defense: 100, block_chance: 1600 },
            ArmorStats { defense: 150, block_chance: 2000 },
            ArmorStats { defense: 200, block_chance: 2400 },
            ArmorStats { defense: 250, block_chance: 2800 },
            ArmorStats { defense: 300, block_chance: 3200 },
        ];
        *vector::borrow(&stats, (level - 1) as u64)
    }
}
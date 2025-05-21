module staking_odyssey::sword;

use std::string;
use staking_odyssey::rarity::{Self, Rarity};
use staking_odyssey::items_stats::{Self, WeaponStats};


public struct Sword has key,store {
    id: UID,
    level: u64,
    rarity: Rarity,
    rarity_text: string::String,
    stats: WeaponStats,
}

public(package) fun new(ctx: &mut TxContext): Sword {
    Sword {
        id: object::new(ctx),
        level: 1,
        rarity: rarity::common(),
        rarity_text: string::utf8(b"common"),
        stats: items_stats::get_weapon_stats(rarity::common(), 1),
    }
}

// === GETTERS ===
public fun get_rarity(sword: &Sword): string::String {
    rarity::get_rarity_text(&sword.rarity)
}

public fun get_level(sword: &Sword): u64 {
    sword.level
}

public fun get_stats(sword: &Sword): WeaponStats {
    sword.stats
}

#[test]
fun test_sword_create() {
    use sui::test_scenario;

    // Create a dummy TxContext for testing
    let mut ctx = tx_context::dummy();
    let admin = @0xCAFE;
    let final_owner = @0xBEEF;
    let mut scenario = test_scenario::begin(admin);

    let sword = Sword {
        id: object::new(&mut ctx),
        level: 1,
        rarity: rarity::common(),
        rarity_text: string::utf8(b"common"),
        stats: items_stats::get_weapon_stats(rarity::common(), 1),
    };

    assert!(sword.level == 1 && sword.rarity == rarity::common() && sword.rarity_text == string::utf8(b"common") && sword.stats == items_stats::get_weapon_stats(rarity::common(), 1), 1);

    transfer::public_transfer(sword, admin);
    scenario.next_tx(admin);

    {
        // Extract the sword owned by the initial owner
        let sword = scenario.take_from_sender<Sword>();
        // Transfer the sword to the final owner
        transfer::public_transfer(sword, final_owner);
    };

    scenario.end();
}

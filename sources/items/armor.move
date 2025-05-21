module staking_odyssey::armor;

use std::string;
use staking_odyssey::rarity::{Self, Rarity};
use staking_odyssey::items_stats::{Self, ArmorStats};

public struct Armor has key,store {
    id: UID,
    level: u64,
    rarity: Rarity,
    rarity_text: string::String,
    stats: ArmorStats,
}

public(package) fun new(ctx: &mut TxContext): Armor {
    Armor {
        id: object::new(ctx),
        level: 1,
        rarity: rarity::common(),
        rarity_text: string::utf8(b"common"),
        stats: items_stats::get_armor_stats(rarity::common(), 1),
    }
}

public fun update_armor_rarity(armor: &mut Armor, armor_rarity: vector<u8>) {
    let exp = 100; // TODO: get exp base on task
    let lvl = 4;

    if(exp >= 100 && lvl ==4 ) {
        armor.rarity = rarity::legendary();
        armor.rarity_text = rarity::get_rarity_text( &rarity::legendary());
    }
}

// === GETTERS ===
public fun get_rarity(armor: &Armor): string::String {
    rarity::get_rarity_text(&armor.rarity)
}

public fun get_level(armor: &Armor): u64 {
    armor.level
}

public fun get_stats(armor: &Armor): ArmorStats {
    armor.stats
}

#[test]
fun test_armor_create() {
    use sui::test_scenario;

    let mut ctx = tx_context::dummy();
    let admin = @0xCAFE;
    let final_owner = @0xBEEF;
    let mut scenario = test_scenario::begin(admin);

    let armor = Armor {
        id: object::new(&mut ctx),
        level: 1,
        rarity: rarity::common(),
        rarity_text: string::utf8(b"common"),
        stats: items_stats::get_armor_stats(rarity::common(), 1),
    };

    assert!(armor.level == 1 && armor.rarity == rarity::common() && armor.rarity_text == string::utf8(b"common") && armor.stats == items_stats::get_armor_stats(rarity::common(), 1), 1);

    transfer::public_transfer(armor, admin);
    scenario.next_tx(admin);

    {
        let armor = scenario.take_from_sender<Armor>();
        transfer::public_transfer(armor, final_owner);
    };

    scenario.end();
}

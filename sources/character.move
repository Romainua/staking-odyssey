module staking_odyssey::character;

use std::string;
use staking_odyssey::sword::{Self, Sword};
use staking_odyssey::armor::{Self, Armor};
use staking_odyssey::items_stats;

/// Represents a player's character in the Staking Odyssey game.
public struct Character has key, store {
    /// Unique identifier for the character object.
    id: UID,
    /// Address of the character's owner.
    owner: address,
    /// Name of the character.
    name: string::String,
    /// Current level of the character.
    level: u64,
    /// Current experience points of the character.
    experience: u64,
    /// Maximum health of the character.
    max_health: u64,
    /// Current health of the character.
    health: u64,
    /// Equipped sword, if any.
    sword: Option<Sword>,
    /// Level of the equipped sword. Copied for quick access.
    sword_level: u64,
    /// Rarity of the equipped sword (as text). Copied for quick access.
    sword_rarity: string::String,
    /// Equipped armor, if any.
    armor: Option<Armor>,
    /// Level of the equipped armor. Copied for quick access.
    armor_level: u64,
    /// Rarity of the equipped armor (as text). Copied for quick access.
    armor_rarity: string::String,
    /// Overall strength of the character, derived from level and equipment.
    strength: u64,
    /// Flag indicating if the character is currently in an active battle.
    is_in_battle: bool,
}

// === CONSTANTS ===
/// Maximum health a character can have.
const MAX_HEALTH: u64 = 1000;
/// Maximum level a character can reach.
const MAX_LEVEL: u64 = 100;
/// Base experience points needed for level-up calculations.
const BASE_EXP_FOR_LEVEL: u64 = 1000;
/// Base factor for level-up experience calculation (percentage base).
const LEVEL_FACTOR_BASE: u64 = 100;
/// Multiplier for level-dependent part of experience calculation.
const LEVEL_FACTOR_MULTIPLIER: u64 = 10;
/// Base strength gained per character level.
const BASE_STRENGTH_LEVEL_FACTOR: u64 = 10;
/// Default rarity text for items when unequipped or for dummy items.
const DEFAULT_ITEM_RARITY_TEXT: vector<u8> = b"common";
/// Default level for items equipped by a dummy character.
const DUMMY_ITEM_DEFAULT_LEVEL: u64 = 1;
/// Name for dummy characters.
const DUMMY_CHARACTER_NAME: vector<u8> = b"Dummy Staker";


// === Errors ===
const EAlreadyEquipped: u64 = 0;
const ENotEquipped: u64 = 1;

/// Creates a new character object.
/// This is an internal function and does not transfer the character.
public(package) fun new(name: vector<u8>, ctx: &mut TxContext): Character {
    Character {
        id: object::new(ctx),
        owner: ctx.sender(),
        name: string::utf8(name),
        level: 1,
        experience: 0,
        max_health: MAX_HEALTH,
        health: MAX_HEALTH,
        sword: option::none(),
        sword_level: 0,
        sword_rarity: DEFAULT_ITEM_RARITY_TEXT.to_string(),
        armor: option::none(),
        armor_level: 0,
        armor_rarity: DEFAULT_ITEM_RARITY_TEXT.to_string(),
        strength: BASE_STRENGTH_LEVEL_FACTOR * 1, // Initial strength
        is_in_battle: false,
    }
}

public fun equip_sword(character: &mut Character, sword: Sword) {
    assert!(character.sword.is_none(), EAlreadyEquipped);
    let sword_rarity = sword::get_rarity(&sword);
    let sword_level = sword::get_level(&sword);
    character.sword_rarity = sword_rarity;
    character.sword_level = sword_level;

    character.sword.fill(sword);
    
    update_character_strength(character);
}

public fun equip_armor(character: &mut Character, armor: Armor) {
    assert!(character.armor.is_none(), EAlreadyEquipped);
    let armor_rarity = armor::get_rarity(&armor);
    let armor_level = armor::get_level(&armor);
    character.armor_rarity = armor_rarity;
    character.armor_level = armor_level;

    character.armor.fill(armor);
    
    update_character_strength(character);
}

/// Unequips the character's sword and transfers it to the owner.
/// Resets sword-related stats on the character to default.
#[allow(lint(self_transfer))]
public fun unequip_sword(character: &mut Character, ctx: &mut TxContext) {
    assert!(option::is_some(&character.sword), ENotEquipped); // Use a more specific error like ENoSwordToUnequip
    let sword = option::extract(&mut character.sword);
    transfer::public_transfer(sword, ctx.sender());
    character.sword_rarity = DEFAULT_ITEM_RARITY_TEXT.to_string();
    character.sword_level = 0;

    update_character_strength(character);
}

/// Unequips the character's armor and transfers it to the owner.
/// Resets armor-related stats on the character to default.
#[allow(lint(self_transfer))]
public fun unequip_armor(character: &mut Character, ctx: &mut TxContext){
    assert!(option::is_some(&character.armor), ENotEquipped); // Use ENoArmorToUnequip
    let armor = option::extract(&mut character.armor);
    transfer::public_transfer(armor, ctx.sender());
    character.armor_rarity = DEFAULT_ITEM_RARITY_TEXT.to_string();
    character.armor_level = 0;

    update_character_strength(character);
}

// === GETTERS ===
public fun get_sword(character: &Character): &Option<Sword> {
    &character.sword
}

public fun get_armor(character: &Character): &Option<Armor> {
    &character.armor
}

public fun get_name(character: &Character): string::String {
    character.name
}

public fun get_health(character: &Character): u64 {
    character.health
}

public fun get_strength(character: &Character): u64 {
    character.strength
}

public fun get_is_in_battle(character: &Character): bool {
    character.is_in_battle
}

public fun get_level(character: &Character): u64 {
    character.level
}

// === INTERNAL FUNCTIONS ===
public(package) fun set_is_in_battle(character: &mut Character, is_in_battle: bool) {
    character.is_in_battle = is_in_battle;
}

fun update_character_strength(character: &mut Character) {
    let mut strength = character.level * BASE_STRENGTH_LEVEL_FACTOR;
    
    if (option::is_some(&character.sword)) {
        let sword_ref = option::borrow(&character.sword);
        let sword_stats = sword::get_stats(sword_ref);
        let sword_attack = items_stats::get_sword_attack(&sword_stats);
        
        strength = strength + sword_attack;
    };
    
    if (option::is_some(&character.armor)) {
        let armor_ref = option::borrow(&character.armor);
        let armor_stats = armor::get_stats(armor_ref);
        let armor_defense = items_stats::get_armor_defense(&armor_stats);
        
        strength = strength + armor_defense;
    };
    
    character.strength = strength;
}

public(package) fun add_exp(character: &mut Character, exp: u64) {
    character.experience = character.experience + exp;
    
    let old_level = character.level;
    
    loop {
        if (character.level >= MAX_LEVEL) {
            break
        };

        let current_level = character.level;
        
        let level_factor = LEVEL_FACTOR_BASE + (LEVEL_FACTOR_MULTIPLIER * current_level);
        let exp_needed_for_next_level = (BASE_EXP_FOR_LEVEL * level_factor) / 100;
        
        if (character.experience >= exp_needed_for_next_level) {
            character.level = character.level + 1;
            character.experience = character.experience - exp_needed_for_next_level;
        } else {
            break
        }
    };
    
    if (old_level != character.level) {
        update_character_strength(character);
    }
}

/// Internal function to create a new dummy character object.
fun new_dummy_character_object(ctx: &mut TxContext): Character {
    let sword = sword::new(ctx); // Assuming sword::new() provides a basic sword
    let armor = armor::new(ctx); // Assuming armor::new() provides basic armor

    let mut dummy = Character {
        id: object::new(ctx),
        owner: ctx.sender(), // Or a system address if dummys are not player owned
        name: DUMMY_CHARACTER_NAME.to_string(),
        level: 1,
        experience: 0,
        max_health: MAX_HEALTH,
        health: MAX_HEALTH,
        sword: option::some(sword),
        sword_level: DUMMY_ITEM_DEFAULT_LEVEL,
        sword_rarity: DEFAULT_ITEM_RARITY_TEXT.to_string(), // Use const
        armor: option::some(armor),
        armor_level: DUMMY_ITEM_DEFAULT_LEVEL,
        armor_rarity: DEFAULT_ITEM_RARITY_TEXT.to_string(), // Use const
        strength: BASE_STRENGTH_LEVEL_FACTOR * 1,    // Calculate initial strength properly
        is_in_battle: false,
    };
    update_character_strength(&mut dummy); // Update strength based on dummy items
    dummy
}

/// Creates a dummy character for training or testing purposes and shares it.
/// The dummy character is equipped with basic items.
public(package) fun create_dummy_character(ctx: &mut TxContext) {
    let dummy = new_dummy_character_object(ctx);
    transfer::share_object(dummy);
}
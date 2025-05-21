module staking_odyssey::battle;

use sui::tx_context::{Self, TxContext};
use sui::object::{Self, ID, UID};
use sui::event;
use sui::random::{Self, Random};
use std::option::{Self, Option};

use staking_odyssey::character::{Self, Character};
use staking_odyssey::sword::{Self, Sword}; 
use staking_odyssey::armor::{Self, Armor}; 
use staking_odyssey::items_stats::{Self};
use sui::balance::{Self, Balance};
use sui::coin::{Self, Coin};
use sui::sui::SUI;
use std::string;
use sui::random::RandomGenerator;

public struct Battle has key {
    id: UID,
    character1: Option<CharacterSnapshot>,
    character2: Option<CharacterSnapshot>,
    creator: address,
    is_finished: bool,
    is_draw: bool,
    winner_id: Option<ID>,
    loser_id: Option<ID>,
    rounds_fought: u64,
    strength: u64,
    balance_of_sui: Balance<SUI>,
    draw_reward_claimed: bool,
}

public struct CharacterSnapshot has store, drop {
    id: ID,
    health: u64,
    strength: u64,
    attack: u64,
    defense: u64,
    crit_chance: u64,
    block_chance: u64,
    level: u64,
}

// === CONSTANTS ===
const MAX_CHANCE: u64 = 10000; // Maximum value for probability (100.00%)
const EXP_FOR_VICTORY: u64 = 1000; // Experience for victory
const EXP_FOR_DEFEAT: u64 = 500; // Experience for defeat (less than for victory)
const EXP_FOR_DRAW: u64 = 500; // Experience for draw
const MIN_BET: u64 = 1 * 10^9; // 1 SUI
const MAX_BET: u64 = 5 * 10^9; // 5 SUI

// === ERRORS ===
const EBattleWithSelf: u64 = 0;
const ENotEquipped: u64 = 1;
const ECreatorInBattle: u64 = 2;
const ENoSwordEquipped: u64 = 3;
const ENoArmorEquipped: u64 = 4;
const EBattleNotFinished: u64 = 5;
const ECharacterInBattle: u64 = 6;
const EInvalidBet: u64 = 7;
const EInsufficientStrength: u64 = 8;
const EFightingWithSelf: u64 = 9;
const ECharacterNotInBattle: u64 = 10;

// === Events ===
/// Event emitted when a battle is finished
public struct BattleOutcome has copy, drop {
    winner_id: ID,
    loser_id: ID,
    rounds_fought: u64,
}

/// Event emitted when a battle is a draw
public struct BattleDraw has copy, drop {
    rounds_fought: u64,
    result: string::String,
}

/// Event emitted when a hit is landed
public struct HitLanded has copy, drop {
    attacker_id: ID,
    defender_id: ID,
    damage_dealt: u64,
    critical_hit: bool,
    blocked: bool,
    round_number: u64,
}

public fun create_battle(
    creator_character: &mut Character,
    bet: Coin<SUI>,
    ctx: &mut TxContext
){
    let is_creator_in_battle = character::get_is_in_battle(creator_character);
    assert!(is_creator_in_battle == false, ECreatorInBattle);
    let is_sword_equipped = option::is_some(character::get_sword(creator_character));
    assert!(is_sword_equipped, ENoSwordEquipped);
    let is_armor_equipped = option::is_some(character::get_armor(creator_character));
    assert!(is_armor_equipped, ENoArmorEquipped);
    
    assert!(bet.value() > MIN_BET && bet.value() < MAX_BET, EInvalidBet);
    
    let creator_character_snapshot = new_character_snapshot(creator_character);
    let creator_character_strength = get_character_strength(creator_character);
    let balance = bet.into_balance();

    
    let battle = Battle {
        id: object::new(ctx),
        character1: option::some(creator_character_snapshot),
        character2: option::none(),
        creator: ctx.sender(),
        strength: creator_character_strength,
        balance_of_sui: balance,
        is_finished: false,
        is_draw: false,
        winner_id: option::none(),
        loser_id: option::none(),
        rounds_fought: 0,
        draw_reward_claimed: false,
    };

    character::set_is_in_battle(creator_character, true);

    transfer::share_object(battle);
}

public fun join_battle(
    battle: &mut Battle,
    character: &mut Character,
    bet: Coin<SUI>,
) { 
    let is_character_in_battle = character::get_is_in_battle(character);
    assert!(is_character_in_battle == false, ECharacterInBattle);
    let is_sword_equipped = option::is_some(character::get_sword(character));
    assert!(is_sword_equipped, ENoSwordEquipped);
    let is_armor_equipped = option::is_some(character::get_armor(character));
    assert!(is_armor_equipped, ENoArmorEquipped);
    let character_id = object::id(character);
    assert!(character_id != option::borrow(&battle.character1).id && character_id != option::borrow(&battle.character2).id, EFightingWithSelf);

    let strength_of_character = get_character_strength(character);
    // TODO: add config for this
    // Strength of character can be up to 5 points higher or lower than the strength of the battle
    assert!(strength_of_character <= battle.strength+5 && strength_of_character >= battle.strength-5, EInsufficientStrength);

    let bet_balance = bet.into_balance();
    assert!(bet_balance.value() == battle.balance_of_sui.value(), EInvalidBet);
    
    battle.balance_of_sui.join(bet_balance);

    let character_snapshot = new_character_snapshot(character);

    character::set_is_in_battle(character, true);

    battle.character2 = option::some(character_snapshot);
}

public fun start_battle(
    battle: &mut Battle,
    random_obj: &Random,
    ctx: &mut TxContext
) {
    // TODO check if player1 and player2 are in battle
    // ONLY one of the players can start the battle
    let player1 = option::borrow(&battle.character1);
    let player2 = option::borrow(&battle.character2);

    let (is_draw, is_finished, winner_id, loser_id, rounds_fought) = fight(player1, player2, random_obj, ctx);

    battle.is_draw = is_draw;
    battle.is_finished = is_finished;
    battle.winner_id = winner_id;
    battle.loser_id = loser_id;
    battle.rounds_fought = rounds_fought;
    
}

fun send_reward(balance: &mut Balance<SUI>, amount: u64, recipient: address, ctx: &mut TxContext) {
    let coin = balance.split(amount).into_coin(ctx);
    transfer::public_transfer(coin, recipient);
}

public fun claim_battle_rewards(
    battle: &mut Battle,
    character: &mut Character,
    ctx: &mut TxContext
) {
    assert!(battle.is_finished == true, EBattleNotFinished);
    let player1 = option::borrow(&battle.character1);
    let player2 = option::borrow(&battle.character2);

    assert!(player1.id == object::id(character) || player2.id == object::id(character), ECharacterNotInBattle);

    let is_winner = option::is_some(&battle.winner_id) && object::id(character) == *option::borrow(&battle.winner_id);
    let recipient = ctx.sender();
    let reward_amount = battle.balance_of_sui.value();

    if (is_winner) {
        send_reward(&mut battle.balance_of_sui, reward_amount, recipient, ctx);
        character::add_exp(character, EXP_FOR_VICTORY);
    } else if (battle.is_draw) {
        character::add_exp(character, EXP_FOR_DRAW);
        
        if (!battle.draw_reward_claimed) {
            send_reward(&mut battle.balance_of_sui, reward_amount/2, recipient, ctx);
            battle.draw_reward_claimed = true;
        } else {
            send_reward(&mut battle.balance_of_sui, reward_amount, recipient, ctx);
        }
    } else {
        character::add_exp(character, EXP_FOR_DEFEAT);
    };
    
    if (player1.id == object::id(character)) {
        battle.character1 = option::none();
    } else {
        battle.character2 = option::none();
    };

    character::set_is_in_battle(character, false);
}

// === Helper functions (internal) ===
/// Retrieves the attack stat of a character based on their equipped sword.
/// Asserts that a sword is equipped.
fun get_character_attack(character: &Character): u64 {
    let sword_option = character::get_sword(character);
    assert!(option::is_some(sword_option), ENoSwordEquipped); // Changed error to be more specific

    let sword_ref = option::borrow(sword_option);
    let stats = sword::get_stats(sword_ref);
    items_stats::get_sword_attack(&stats)
}

fun get_character_defense(character: &Character): u64 {
    let armor = character::get_armor(character);
    assert!(option::is_some(armor), ENotEquipped);


    let armor_ref = option::borrow(armor);
    let stats = armor::get_stats(armor_ref);
    items_stats::get_armor_defense(&stats)
}

fun get_character_crit_chance(character: &Character): u64 {
    let sword = character::get_sword(character);
    assert!(option::is_some(sword), ENotEquipped);

    let sword_ref = option::borrow(sword);
    let stats = sword::get_stats(sword_ref);
    items_stats::get_sword_crit_chance(&stats)
}

fun get_character_block_chance(character: &Character): u64 {
    let armor = character::get_armor(character);
    assert!(option::is_some(armor), ENotEquipped);

    let armor_ref = option::borrow(armor);
    let stats = armor::get_stats(armor_ref);
    items_stats::get_armor_block_chance(&stats)
}

fun get_character_health(character: &Character): u64 {
    character::get_health(character)
}

fun get_character_strength(character: &Character): u64 {
    character::get_strength(character)
}

public(package) fun new_character_snapshot(character: &Character): CharacterSnapshot {
    let snapshot_character_strength = get_character_strength(character);
    let snapshot_character_attack = get_character_attack(character);
    let snapshot_character_defense = get_character_defense(character);
    let snapshot_character_crit_chance = get_character_crit_chance(character);
    let snapshot_character_block_chance = get_character_block_chance(character);
    let snapshot_character_health = get_character_health(character);
    let snapshot_character_level = character::get_level(character);

    CharacterSnapshot {
        id: object::id(character),
        health: snapshot_character_health,
        strength: snapshot_character_strength,
        attack: snapshot_character_attack,
        defense: snapshot_character_defense,
        crit_chance: snapshot_character_crit_chance,
        block_chance: snapshot_character_block_chance,
        level: snapshot_character_level,
    }
}

fun calculate_attack_damage(
    attacker: &CharacterSnapshot,
    defender: &CharacterSnapshot,
    generator: &mut RandomGenerator
): (u64, bool, bool) {
    let base_attack = attacker.attack;
    let defense = defender.defense;
    
    // Check for critical hit
    let crit_chance = attacker.crit_chance;
    let rolled_crit = random::generate_u64_in_range(generator, 0, MAX_CHANCE);
    let is_crit = rolled_crit < crit_chance;
    
    // Check for blocking
    let block_chance = defender.block_chance;
    let rolled_block = random::generate_u64_in_range(generator, 0, MAX_CHANCE);
    let is_blocked = rolled_block < block_chance;
    
    // Calculate damage
    let mut damage = if (base_attack > defense) { base_attack - defense } else { 1 }; // Minimum damage is always 1
    
    // Add level bonus: 1% additional damage per level
    let level_bonus = (damage * attacker.level) / 100;
    damage = damage + level_bonus;
    
    let damage = if (is_crit) {
        damage * 2 // Critical hit doubles damage
    } else {
        damage
    };
    
    // Add random variation of ±10% to the damage
    let min_damage = (damage * 90) / 100; // 90% of damage
    let max_damage = (damage * 110) / 100; // 110% of damage
    // Make sure we don't get zero range when damage is very small
    let damage = if (min_damage == max_damage) {
        min_damage
    } else {
        random::generate_u64_in_range(generator, min_damage, max_damage + 1)
    };
    
    let damage = if (is_blocked) {
        0 // Blocking reduces damage by 0
    } else {
        damage
    };
    
    (damage, is_crit, is_blocked)
}

public(package) fun fight(
    player1: &CharacterSnapshot,
    player2: &CharacterSnapshot,
    random_obj: &Random,
    ctx: &mut TxContext
): (bool, bool, Option<ID>, Option<ID>, u64) {
    let p1_id = player1.id;
    let p2_id = player2.id;

    assert!(p1_id != p2_id, EBattleWithSelf);

    let mut is_draw = false;
    let mut is_finished = false;
    let mut winner_id = option::none();
    let mut loser_id = option::none();
    let mut rounds_fought = 0;

    // Create temporary copies of health
    let mut p1_temp_health = player1.health;
    let mut p2_temp_health = player2.health;

    let mut generator = random_obj.new_generator(ctx);
    let mut rounds = 0;

    loop {
        rounds = rounds + 1;

        // Check if maximum number of rounds reached or if someone is already defeated
        if (p1_temp_health == 0 || p2_temp_health == 0) {
            break
        };

        // Player 1's turn
        let (damage_to_p2, p1_crit, p2_blocked) = calculate_attack_damage(player1, player2, &mut generator);
        
        // Reduce temporary health instead of actual health
        if (p2_temp_health > damage_to_p2) {
            p2_temp_health = p2_temp_health - damage_to_p2;
        } else {
            p2_temp_health = 0;
        };

        event::emit(HitLanded {
            attacker_id: p1_id,
            defender_id: p2_id,
            damage_dealt: damage_to_p2,
            critical_hit: p1_crit,
            blocked: p2_blocked,
            round_number: rounds
        });

        if (p2_temp_health == 0) {
            break // Player 2 is defeated
        };

        // Player 2's turn
        let (damage_to_p1, p2_crit, p1_blocked) = calculate_attack_damage(player2, player1, &mut generator);
        
        // Reduce temporary health instead of actual health
        if (p1_temp_health > damage_to_p1) {
            p1_temp_health = p1_temp_health - damage_to_p1;
        } else {
            p1_temp_health = 0;
        };

        event::emit(HitLanded {
            attacker_id: p2_id,
            defender_id: p1_id,
            damage_dealt: damage_to_p1,
            critical_hit: p2_crit,
            blocked: p1_blocked,
            round_number: rounds
        });

        if (p1_temp_health == 0) {
            break // Player 1 is defeated
        };
    };

    // Determine winner and loser
    if (p1_temp_health > p2_temp_health) {
        event::emit(BattleOutcome {
            winner_id: p1_id,
            loser_id: p2_id,
            rounds_fought: rounds
        });
        is_finished = true;
        winner_id = option::some(p1_id);
        loser_id = option::some(p2_id);
        rounds_fought = rounds;
    } else if (p2_temp_health > p1_temp_health) {
        event::emit(BattleOutcome {
            winner_id: p2_id,
            loser_id: p1_id,
            rounds_fought: rounds
        });
        is_finished = true;
    } else {
        event::emit(BattleDraw {
            result: string::utf8(b"draw"),
            rounds_fought: rounds
        });
        is_draw = true;
        is_finished = true;
        winner_id = option::none();
        loser_id = option::none();
        rounds_fought = rounds;
    };

    (is_draw, is_finished, winner_id, loser_id, rounds_fought)

}
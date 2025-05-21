module staking_odyssey::game;

use std::string;
use staking_odyssey::character::{Self, Character};
use staking_odyssey::sword::{Self, Sword};
use staking_odyssey::armor::{Self, Armor};
use staking_odyssey::staking_registry;
use staking_odyssey::battle;
use sui::random::{Self, Random};
use sui::event;
use sui::package;
use sui::display;

/// One-Time-Witness for the module.
public struct GAME has drop {}

// === Events ===
public struct CharacterMinted has copy, drop {
    // The Object ID of the Character
    object_id: ID,
    // The creator of the Character
    creator: address,
    // The name of the Character
    name: string::String,
}

/// Event emitted when a sword is minted.
public struct SwordMinted has copy, drop {
    // The Object ID of the Sword
    object_id: ID,
    // The creator of the Sword
    creator: address,
}

/// Event emitted when a armor is minted.
public struct ArmorMinted has copy, drop {
    // The Object ID of the Armor
    object_id: ID,
    // The creator of the Armor
    creator: address,
}

/// Event emitted when a training battle is completed.
public struct TrainingBattleCompleted has copy, drop {
    player_id: ID,
    dummy_id: ID,
}

// === Errors ===
const EInvalidName: u64 = 0;

// === Constants ===
const MAX_NAME_LENGTH: u64 = 14;

fun init(otw: GAME, ctx: &mut TxContext) {
    let keys = vector[
        b"name".to_string(),
        b"link".to_string(),
        b"image_url".to_string(),
        b"description".to_string(),
        b"project_url".to_string(),
        b"creator".to_string(),
    ];

    let character_values = vector[
        // For `name` one can use the `Hero.name` property
        b"{name}".to_string(),
        // For `link` one can build a URL using an `id` property
        b"https://staking-odyssey.n1stake.com/character/{id}".to_string(),
        // For `image_url` use an IPFS template + `image_url` property.
        b"https://ikmbfdctjnfostmxibgs.supabase.co/storage/v1/object/public/images/equipped/{armor_rarity}-armor{armor_level}-{sword_rarity}-sword{sword_level}.png".to_string(),
        // Description is static for all `Hero` objects.
        b"Fight for the glory of the Sui ecosystem with this character!".to_string(),
        // Project URL is usually static
        b"https://staking-odyssey.n1stake.com".to_string(),
        // Creator field can be any
        b"n1stake".to_string(),
    ];
    let sword_values = vector[
        // For `name` one can use the `Hero.name` property
        b"{name}".to_string(),
        // For `link` one can build a URL using an `id` property
        b"https://staking-odyssey.n1stake.com/sword/{id}".to_string(),
        // For `image_url` use an IPFS template + `image_url` property.
        b"https://ikmbfdctjnfostmxibgs.supabase.co/storage/v1/object/public/images/sword/{rarity_text}/lvl_{level}.png".to_string(),
        // Description is static for all `Hero` objects.
        b"Fight for the glory of the Sui ecosystem with this sword!".to_string(),
        // Project URL is usually static
        b"https://staking-odyssey.n1stake.com".to_string(),
        // Creator field can be any
        b"n1stake".to_string(),
    ];
    let armor_values = vector[
        // For `name` one can use the `Hero.name` property
        b"{name}".to_string(),
        // For `link` one can build a URL using an `id` property
        b"https://staking-odyssey.n1stake.com/armor/{id}".to_string(),
        // For `image_url` use an IPFS template + `image_url` property.
        b"https://ikmbfdctjnfostmxibgs.supabase.co/storage/v1/object/public/images/armor/{rarity_text}/lvl_{level}.png".to_string(),
        // Description is static for all `Hero` objects.
        b"Fight for the glory of the Sui ecosystem with this armor!".to_string(),
        // Project URL is usually static
        b"https://staking-odyssey.n1stake.com".to_string(),
        // Creator field can be any
        b"n1stake".to_string(),
    ];

    // Claim the `Publisher` for the package!
    let publisher = package::claim(otw, ctx);

    // Get a new `Display` object for the `Hero` type.
    let mut character_display = display::new_with_fields<Character>(
        &publisher, keys, character_values, ctx
    );
    let mut sword_display = display::new_with_fields<Sword>(
        &publisher, keys, sword_values, ctx
    );
    let mut armor_display = display::new_with_fields<Armor>(
        &publisher, keys, armor_values, ctx
    );

    // Commit first version of `Display` to apply changes.
    character_display.update_version();
    sword_display.update_version();
    armor_display.update_version();

    transfer::public_transfer(publisher, ctx.sender());
    transfer::public_transfer(character_display, ctx.sender());
    transfer::public_transfer(sword_display, ctx.sender());
    transfer::public_transfer(armor_display, ctx.sender());

    staking_registry::initialize_registry(ctx);
    character::create_dummy_character(ctx);
}

/// Mints a new character and transfers it to the transaction sender.
/// Emits a `CharacterMinted` event.
///
/// Arguments:
/// - `name`: The desired name for the character as a vector of bytes (UTF-8 encoded).
/// - `ctx`: Mutable reference to the transaction context.
public fun mint_character(name: vector<u8>, ctx: &mut TxContext) {
    assert!(vector::length(&name) <= MAX_NAME_LENGTH, EInvalidName); // Assuming constants are in character module
    let sender = ctx.sender();
    let character_obj = character::new(name, ctx); // Use internal creator
    let character_id = object::id(&character_obj);
    transfer::public_transfer(character_obj, sender);


    event::emit(CharacterMinted {
        object_id: character_id,
        creator: ctx.sender(),
        name: string::utf8(name),
    });
}

/// Mints a new sword and transfers it to the transaction sender.
/// Emits a `SwordMinted` event.
///
/// Arguments:
/// - `ctx`: Mutable reference to the transaction context.
#[allow(lint(self_transfer))]
public fun mint_sword(ctx: &mut TxContext) {
    let sender = ctx.sender();
    let sword_obj = sword::new(ctx); // Assuming sword::new returns the object
    let sword_id = object::id(&sword_obj);

    transfer::public_transfer(sword_obj, sender);

    event::emit(SwordMinted {
        object_id: sword_id,
        creator: ctx.sender(),
    });
}

/// Mints a new armor and transfers it to the transaction sender.
/// Emits an `ArmorMinted` event.
///
/// Arguments:
/// - `ctx`: Mutable reference to the transaction context.
#[allow(lint(self_transfer))]
public fun mint_armor(ctx: &mut TxContext) {
    let sender = ctx.sender();
    let armor_obj = armor::new(ctx); // Assuming armor::new returns the object
    let armor_id = object::id(&armor_obj);

    transfer::public_transfer(armor_obj, sender);

    event::emit(ArmorMinted {
        object_id: armor_id,
        creator: ctx.sender(),
    });
}

/// Initiates a training battle between a player's character and a dummy character.
/// Emits a `TrainingBattleCompleted` event. This function assumes the dummy character
/// is a shared object that can be passed by reference.
///
/// Arguments:
/// - `player_character`: Reference to the player's `Character` object.
/// - `dummy_character`: Reference to the dummy `Character` object.
/// - `random_obj`: Reference to a `Random` object for battle randomness.
/// - `ctx`: Mutable reference to the transaction context.
#[allow(lint(public_random))]
public fun training_battle(
    player_character: &Character, // Should be &mut if EXP is gained directly
    dummy_character: &Character,  // Dummy usually doesn't change
    random_obj: &Random,
    ctx: &mut TxContext,
) {
    // Note: battle::fight might modify characters if they gain EXP directly.
    // If player_character needs to be modified (e.g. gain EXP from training), it should be &mut.
    // For now, assuming fight takes snapshots or handles EXP via events/separate calls.
    let player_character_snapshot = battle::new_character_snapshot(player_character);
    let dummy_character_snapshot = battle::new_character_snapshot(dummy_character);

    // battle::fight does not return values in the provided snippet,
    // it seems to directly emit events or modify state.
    // If it's meant to update the battle object, it would need one.
    // This function seems to be a simplified battle trigger.
    battle::fight(&player_character_snapshot, &dummy_character_snapshot, random_obj, ctx);

    event::emit(TrainingBattleCompleted {
        player_id: object::id(player_character),
        dummy_id: object::id(dummy_character),
    });
}

#[test]
fun test_module_init() {
		use sui::test_scenario;

		let admin = @0xAD;
		let mut scenario = test_scenario::begin(admin);
		{
			init(GAME {}, scenario.ctx());
		};

		scenario.end();
}

#[test]
fun test_mint_character() {
    use sui::test_scenario;

    let owner = @0xCAFE;
    let name = b"Hero";

    let mut scenario = test_scenario::begin(owner);
    {
        init(GAME {}, scenario.ctx());
    };
    
    scenario.next_tx(owner);
    {
        mint_character(name, scenario.ctx());
    };
    
    scenario.next_tx(owner);
    {
        let character = scenario.take_from_sender<Character>();
        assert!(character::get_name(&character) == string::utf8(name), 0);
        scenario.return_to_sender(character);
    };
    
    scenario.end();
}

#[test]
fun test_mint_sword() {
    use sui::test_scenario;

    let owner = @0xCAFE;

    let mut scenario = test_scenario::begin(owner);
    {
        init(GAME {}, scenario.ctx());
    };
    
    scenario.next_tx(owner);
    {
        mint_sword(scenario.ctx());
    };
    
    scenario.next_tx(owner);
    {
        let sword = scenario.take_from_sender<Sword>();
        scenario.return_to_sender(sword);
    };
    
    scenario.end();
}

#[test]
fun test_mint_armor() {
    use sui::test_scenario;

    let owner = @0xCAFE;

    let mut scenario = test_scenario::begin(owner);
    {
        init(GAME {}, scenario.ctx());
    };
    
    scenario.next_tx(owner);
    {
        mint_armor(scenario.ctx());
    };
    
    scenario.next_tx(owner);
    {
        let armor = scenario.take_from_sender<Armor>();
        scenario.return_to_sender(armor);
    };
    
    scenario.end();
}

#[test]
fun test_training_battle() {
    use sui::test_scenario;

    let owner = @0xCAFE;
    let name = b"Warrior";

    let mut scenario = test_scenario::begin(owner);
    {
        init(GAME {}, scenario.ctx());
    };
    
    scenario.next_tx(owner);
    {
        mint_character(name, scenario.ctx());
    };
    
    scenario.next_tx(owner);
    {
        character::create_dummy_character(scenario.ctx());   
    };
    
    scenario.end();
}
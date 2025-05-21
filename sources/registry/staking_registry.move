module staking_odyssey::staking_registry;

use sui::vec_map::{Self, VecMap};
use sui::event;

// === Errors ===
const EStakeAlreadyClaimed: u64 = 0;
const EStakeNotFound: u64 = 1;
const ENotAdmin: u64 = 2;

/// Global registry that tracks bindings between StakedSui and characters
public struct StakingRegistry has key {
    id: UID,
    /// Mapping table from StakedSui object ID to character ID
    stakes: VecMap<ID, Stake>,
    /// Admin who has the right to maintain the registry
    admin: address
}

public struct Stake has store, drop {
    staked_sui_id: ID,
    claimed_xp: u64,
    claimed_epoch: u64,
}

// === Events ===
/// Event for removing stake from registry
public struct StakeRemoved has copy, drop {
    staked_sui_id: ID,
}

/// Create a new staking registry. Can only be called once during initialization.
public(package) fun new(ctx: &mut TxContext): StakingRegistry {
    StakingRegistry {
        id: object::new(ctx),
        stakes: vec_map::empty(),
        admin: ctx.sender()
    }
}

/// Initialize and publish the staking registry as a shared object
public(package) fun initialize_registry(ctx: &mut TxContext) {
    let registry = new(ctx);
    transfer::share_object(registry);
}

/// Register a binding between StakedSui and a character
public(package) fun register_stake(
    registry: &mut StakingRegistry,
    staked_sui_id: &ID, 
    claimed_xp: u64,
    claimed_epoch: u64
) {
    // Check if the stake is already bound to any character
    assert!(!vec_map::contains(&registry.stakes, staked_sui_id), EStakeAlreadyClaimed);
    
    let stake = Stake {
        staked_sui_id: *staked_sui_id,
        claimed_xp: claimed_xp,
        claimed_epoch: claimed_epoch
    };
    vec_map::insert(&mut registry.stakes, *staked_sui_id, stake);
}

/// Updates the claimed XP and epoch for an existing stake in the registry.
/// Only callable by functions within this package.
/// Asserts that the stake exists.
///
/// Arguments:
/// - `registry`: Mutable reference to the `StakingRegistry`.
/// - `staked_sui_id`: ID of the `StakedSui` object whose stake info is to be updated.
/// - `xp`: The new total claimed XP for this stake.
/// - `claimed_epoch`: The new last claimed epoch for this stake.
public(package) fun update_stake_info(registry: &mut StakingRegistry, staked_sui_id: &ID, xp: u64, claimed_epoch: u64) {
    assert!(vec_map::contains(&registry.stakes, staked_sui_id), EStakeNotFound);
    let stake = vec_map::get_mut(&mut registry.stakes, staked_sui_id);
    stake.claimed_xp = xp;
    stake.claimed_epoch = claimed_epoch;
}

/// Check if StakedSui is bound to any character in the registry.
public fun is_stake_on_registry(registry: &StakingRegistry, staked_sui_id: &ID): bool {
    vec_map::contains(&registry.stakes, staked_sui_id)
}

/// Retrieves a reference to the `Stake` information for a given `StakedSui` ID.
/// Asserts that the stake exists.
///
/// Arguments:
/// - `registry`: Reference to the `StakingRegistry`.
/// - `staked_sui_id`: ID of the `StakedSui` object.
///
/// Returns: A reference to the `Stake` struct.
public fun get_stake(registry: &StakingRegistry, staked_sui_id: &ID): &Stake {
    assert!(vec_map::contains(&registry.stakes, staked_sui_id), EStakeNotFound); // Added assertion for safety
    vec_map::get(&registry.stakes, staked_sui_id)
}

/// Retrieves the claimed XP from a `Stake` struct.
///
/// Arguments:
/// - `stake`: Reference to the `Stake` struct.
///
/// Returns: The claimed XP amount.
public fun get_xp(stake: &Stake): u64 {
    stake.claimed_xp
}

/// Clear a specific stake from the registry
public fun remove_stake(
    registry: &mut StakingRegistry, 
    stake_id: ID,
    ctx: &TxContext
) {
    assert!(ctx.sender() == registry.admin, ENotAdmin);
    
    if (vec_map::contains(&registry.stakes, &stake_id)) {
        let (_, stake) = vec_map::remove(&mut registry.stakes, &stake_id);
        event::emit(StakeRemoved { staked_sui_id: stake.staked_sui_id });
    };
}

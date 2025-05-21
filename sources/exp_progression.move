module staking_odyssey::exp_progression;

use sys::staking_pool::{StakedSui};
use staking_odyssey::character::{Self, Character};
use staking_odyssey::staking_registry::{Self, StakingRegistry};
use staking_odyssey::utils::{Self};

public fun claim_staking_task_exp(
    stakedObject: &StakedSui,
    character: &mut Character, 
    registry: &mut StakingRegistry,
    ctx: &mut TxContext
) {
    let staked_amount = stakedObject.amount();
    let stake_activation_epoch = stakedObject.stake_activation_epoch();
    let staked_object_id = object::id(stakedObject);
    let current_epoch = ctx.epoch();
    
    if (staking_registry::is_stake_on_registry(registry, &staked_object_id)) {
        let stake = staking_registry::get_stake(registry, &staked_object_id);
        let current_total_potential_xp = utils::calculate_sui_stake_xp(staked_amount, stake_activation_epoch, ctx);
        let claimed_xp = staking_registry::get_xp(stake);

        let exp_to_add = if (current_total_potential_xp > claimed_xp) {
            current_total_potential_xp - claimed_xp
        } else {
            0u64
        };
        
        character::add_exp(character, exp_to_add);
        staking_registry::update_stake_info(registry, &staked_object_id, current_total_potential_xp, current_epoch);
    } else {
        // register new stake
        let exp_to_add = utils::calculate_sui_stake_xp(staked_amount, stake_activation_epoch, ctx);

        staking_registry::register_stake(registry, &staked_object_id, exp_to_add, current_epoch);
        character::add_exp(character, exp_to_add);
    };

}

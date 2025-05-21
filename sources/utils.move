module staking_odyssey::utils;

const A0_mist: u64 = 10 * 10^9;   // 10 SUI in MIST
const VCOEF: u64 = 200;           // 0.20 per log2 step  (in 100th of percent)
const BASE_VOLUME: u64 = 1_000;   // base multiplier (100%)
const EXP_SCALING: u64 = 1_000_000_000;     // scaling factor (10^9)

public fun log2_floor(x: u64): u64 {
    let mut n = x;
    let mut res: u64 = 0;
        while (n > 1) {
            n = n >> 1;
            res = res + 1;
        };
        res
}

public fun calculate_sui_stake_xp(amount: u64, claimed_epoch: u64, ctx: &mut TxContext): u64 {
    let current_epoch = ctx.epoch();
    let epoch_delta = current_epoch - claimed_epoch;
    let volume_steps = log2_floor(amount / A0_mist);
    let volume = BASE_VOLUME + VCOEF * volume_steps; 
    let base_exp = (amount * epoch_delta) / EXP_SCALING;
    let exp = (base_exp * volume) / BASE_VOLUME;
    exp
}
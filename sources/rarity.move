module staking_odyssey::rarity;

use std::string;

public enum Rarity has store, copy, drop {
    Common,
    Rare,
    Legendary
}


public fun common(): Rarity {
    Rarity::Common
}

public fun rare(): Rarity {
    Rarity::Rare
}

public fun legendary(): Rarity {
    Rarity::Legendary
}

public fun is_common(r: Rarity): bool { r == Rarity::Common }
public fun is_rare(r: Rarity): bool { r == Rarity::Rare }
public fun is_legendary(r: Rarity): bool { r == Rarity::Legendary }

public fun get_rarity_bonus(rarity: Rarity): u64 {
    match (rarity) {
        Rarity::Common => 0,
        Rarity::Rare => 50,
        Rarity::Legendary => 100,
    }
}

public fun get_rarity_text(rarity: &Rarity): string::String {
    match (rarity) {
        Rarity::Common => string::utf8(b"common"),
        Rarity::Rare => string::utf8(b"rare"),
        Rarity::Legendary => string::utf8(b"legendary"),
    }
}

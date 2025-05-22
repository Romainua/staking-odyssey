# Staking Odyssey

## 🎮 About The Game

Staking Odyssey transforms SUI staking into an engaging competitive game where your staking power directly fuels your in-game characters and progress. It's designed to make staking more interactive and rewarding, allowing players to visually see their staking efforts translate into game achievements and a recognized "Staker Level" within the SUI ecosystem.

## ✨ Key Features

- **Stake-to-Power Up:** The more SUI you stake, the stronger your game characters become. This directly influences their stats and abilities.
- **Character Progression:**
  - Characters have a name, level, experience points (XP), health, and strength.
  - Gain XP through staking and in-game actions to level up your character (max level: 100).
  - Leveling up increases base character strength.
- **Equipment System:**
  - Equip your characters with `Swords` and `Armor`.
  - Items have their own levels and rarities, contributing to the character's overall strength.
- **Strategic Gameplay:** (To be elaborated - likely involves using character strength and equipment in battles).
- **SUI Staker Certificate:** Earn a unique digital certificate (potentially an NFT) that represents your Staker Level, character progression, and achievements.
- **Competitive Element:** (To be elaborated - how players compete, e.g., "Engage in battles where character strength and strategy determine the winner").

## 📖 How to Play (Gameplay Loop)

1.  **Stake SUI:** Connect your SUI wallet. Your SUI stake is fundamental to powering up your presence in Staking Odyssey buy not required.
2.  **Get Your Character:** New characters are created with a name, starting at Level 1.
3.  **Equip & Enhance:** Mint `Swords` and `Armor`. Equip them to boost your character's `strength` and be able for battle.
4.  **Battle/Compete:** (Detail the core game loop - e.g., "Challenge other players or dummy character. Character level and equipment, plays a key role.").
5.  **Earn XP & Level Up:**
    - Staking SUI and participating in game activities (like battles) grants XP.
    - Accumulate enough XP (based on `BASE_EXP_FOR_LEVEL` and level-based multipliers) to level up your character.
6.  **Improve Your Staker Standing:** Higher character levels and game achievements contribute to your overall "Staker Level" potentially unlocking benefits across the SUI ecosystem.

## 🛠️ Technical Overview

- **Core Modules:**
  - `staking_odyssey::game`: Manages the main game state, character and items mint, and high-level game interactions.
  - `staking_odyssey::character`: Defines the `Character` struct (with attributes like `id`, `owner`, `name`, `level`, `experience`, `health`, `strength`, `sword`, `armor`, `is_in_battle`), item equipping/unequipping logic, XP gain, and level-up mechanics.
  - `staking_odyssey::battle`: (Presumably) Handles the combat or competition mechanics between characters.
  - `staking_odyssey::exp_progression`: Defines constants and logic related to XP requirements for leveling up (e.g., `BASE_EXP_FOR_LEVEL`, `LEVEL_FACTOR_BASE`).
  - `staking_odyssey::items_stats`: (Presumably) Defines how item stats (like sword attack, armor defense) are calculated or retrieved.
  - `staking_odyssey::sword`: Defines the `Sword` item, its attributes (level, rarity, stats), and related functions.
  - `staking_odyssey::armor`: Defines the `Armor` item, its attributes (level, rarity, stats), and related functions.
  - `staking_odyssey::rarity`: Defines different rarity tiers for characters or items (common, rare, legendary).
  - `staking_odyssey::utils`: Utility functions for the package.
- **Key Character Attributes:** `name`, `level`, `experience`, `health`, `strength` (derived from level and equipment stats like sword & armor).

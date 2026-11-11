# MyAutoRoller

**MyAutoRoller** is a smart, lightweight World of Warcraft addon that automates loot rolls (Need, Greed, Disenchant, Pass, or Upgrade) by item quality, Pawn-style stat weights, multi-spec profiles, class gear rules, and profession recipes, complete with a Live Loot Roll Tracker and Pawn-style upgrade arrows.

---

## Features

- **Quality Roll Matrix**: Configure automatic roll actions (`Manual`, `Upgrade`, `Pass`, `Greed`, `Need`, `Disenchant`) independently for each item quality tier (Poor through Legendary).
- **Pawn-Style Stat Weight Scoring & Multi-Spec Profiles**:
  - Evaluates gear drops against currently equipped items using customizable stat weights (`sum(stat * weight)`), socket values, and weapon speed filters.
  - Supports multiple named Stat Weight Profiles per character (create, copy, delete, reset, and auto-switch on Dual Spec changes).
- **Strict Class & Spec Gear Protection**:
  - Automatically restricts `Need` rolls to your class's primary armor type, usable weapon proficiencies, class/race restrictions, and relevant class stats.
- **Safety Toggles**:
  - **Skip Bind-on-Pickup (BoP)**: Leave BoP items for manual rolling.
  - **Skip Bind-on-Equip (BoE)**: Never auto-roll Need on BoE items.
  - **Pass if Not an Upgrade (Instead of Greed)**: Optionally roll Pass instead of Greed whenever an item is not an upgrade.
  - **Need on My Professions**: Automatically roll Need on unlearned recipes/patterns/plans for your character's active professions (and Greed/Pass on known or unusable recipes).
- **Green Upgrade Arrow Overlay**: Displays a Pawn-style green upgrade arrow on bags, loot windows, group loot frames, and the Live Loot Roll Tracker.
- **Live Loot Roll Tracker Window**: Real-time movable window showing active group loot rolls, player roll choices, roll numbers, and winners.
- **Standalone Movable Settings Window**: Access both **General Settings** and **Stat Weights** via `/mar` (even during combat) or through `ESC -> Options -> AddOns -> MyAutoRoller`.

---

## Slash Commands

| Command | Description |
| :--- | :--- |
| `/mar` | Open the MyAutoRoller configuration window |
| `/mar weights` | Open directly to the Stat Weights tab |
| `/mar tracker` | Toggle the Live Loot Roll Tracker window |
| `/mar profile` | List all stat weight profiles for this character |
| `/mar profile <name>` | Switch active stat weight profile |
| `/mar profile new <name>` | Create and activate a new blank profile |
| `/mar profile copy <name>` | Duplicate the current profile into a new profile |
| `/mar profile delete <name>` | Delete a stat weight profile |
| `/mar status` | Display current settings, active profile, and detected professions |

---

## Installation

1. Copy the `MyAutoRoller` folder into your World of Warcraft `Interface\AddOns` directory:
   - `World of Warcraft\_anniversary_\Interface\AddOns\MyAutoRoller`
   - `World of Warcraft\_forever_\Interface\AddOns\MyAutoRoller`
2. Restart World of Warcraft or reload your UI with `/reload`.
3. Type `/mar` to configure your roll matrix and stat weights.

---

## License

MIT

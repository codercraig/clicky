# Clicky

**Author:** Oxos  
**Version:** 1.1  
**Description:** Customizable Buttons for Final Fantasy XI with multi-click command support.

## 📖 Overview

Clicky is an addon for Final Fantasy XI that allows players to create and customize buttons for various in-game actions. The addon supports multiple windows and offers separate left-click, right-click, and middle-click command options for each button, providing great flexibility for players.

## ✨ Features

- **Customizable Buttons:** Create multiple windows with customizable buttons for spells, abilities, and items.
- **Multi-Click Support:** Each button can be configured with separate left-click, right-click, and middle-click commands.
- **Dynamic Action Types:** Supports various action types, including `Magic`, `Abilities`, `Weapon Skills`, `Ranged Attacks`, `Pet Commands`, `Equipsets`, `Items`, and `Multi-Send` for dual-boxing.
- **Flexible Targeting:** Choose from different targeting options, such as `Self`, `Target`, `Party Members`, `Sub-Targets`, and `Alliance Members`.
- **Edit Mode:** Toggle edit mode to show or hide the `+` and `x` buttons, and allow window movement.
- **Auto-Save:** Automatically saves button configurations based on the player’s main job.
- **Info Display:** Shows an info window with the current profile and character name.

## 💻 Commands

| Command | Description |
| ------- | ----------- |
| `/clicky show [window_id]` | Show a specific window. |
| `/clicky hide [window_id]` | Hide a specific window. |
| `/clicky addnew` | Add a new window. |
| `/clicky edit on` | Enable edit mode. |
| `/clicky edit off` | Disable edit mode. |
| `/clicky` | Toggle the info window displaying the addon version, current profile, and character name. |
| `/clicky save` | Manually save the current settings. |

## 🛠️ Installation

1. Download the latest release of Clicky from the GitHub repository.
2. Extract the contents to your `Ashita\addons\clicky` directory.
3. Load the addon in-game using the Ashita command:

   ```bash
   /addon load clicky
🚀 Usage
Basic Usage
Load the addon using:

bash
Copy code
/addon load clicky
Use /clicky addnew to create a new window.

Use /clicky edit on to enable edit mode.

Click on a button to edit its name and configure left-click, right-click, and middle-click commands.

Use the + button to add new buttons vertically.

Use the x button to close a window.

Use /clicky edit off to disable edit mode and hide the edit controls.

Multi-Click Commands
Left-Click: Executes the primary command (e.g., casting a spell or using an ability).
Right-Click: Executes an alternative command (e.g., using a different ability or item).
Middle-Click: Used for advanced commands, such as multi-send for dual-boxing setups.
🔍 Example Commands
plaintext
Copy code
/clicky show 1
/clicky hide 1
/clicky addnew
/clicky edit on
/clicky edit off
/clicky
/clicky save
Advanced Command Examples
plaintext
Copy code
/ma "Cure IV" <t>           # Cast Cure IV on target
/ja "Provoke" <t>           # Use Provoke on target
/ws "Savage Blade" <t>      # Execute Savage Blade weapon skill
/equipset 1                 # Equip equipment set 1
/item "Hi-Potion" <me>      # Use Hi-Potion on self
/mso /ma "Cure IV" [p1]     # Cast Cure IV on party member (dual-boxing)
🗂️ Profiles and Job-Specific Settings
Clicky automatically loads settings based on the player’s main job. Each job has its own profile, allowing for unique setups per job. Changes are saved automatically when switching jobs or can be manually saved using:

bash
Copy code
/clicky save
🐞 Known Issues
If the job ID is 0 (e.g., during login or character change), Clicky retains the previous settings to avoid issues.
Minor visual glitches may occur if windows overlap when edit mode is enabled.
📜 License
This project is licensed under the MIT License - see the LICENSE file for details.

❤️ Contributing
Contributions are welcome! If you find any issues or have suggestions, please open an issue on the GitHub repository.

Enjoy your enhanced gameplay with Clicky! If you encounter any issues, feel free to report them on the GitHub repository.

markdown
Copy code

This version uses full Markdown features, including:

- Proper headers (`#`, `##`, `###`)
- Code blocks (with triple backticks)
- Tables for commands
- Emojis for improved readability
- Section dividers and lists

This structure will look nice on GitHub and other Markdown viewers. Let me know if you need any more changes!






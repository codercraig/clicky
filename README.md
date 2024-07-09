# Clicky

**Author:** Oxos  
**Version:** 1.0  
**Description:** Customizable Buttons for Final Fantasy XI.

## Overview

Clicky is an addon for Final Fantasy XI that allows players to create and customize buttons for various in-game actions. The buttons can be arranged in multiple windows, and players can toggle edit mode to modify the layout and commands of the buttons.

## Features

- Create multiple windows with custom buttons.
- Edit button names and commands.
- Add new buttons horizontally or vertically.
- Toggle edit mode to show or hide the "+", "x" buttons, and allow window movement.
- Automatically saves the button configuration.
- Displays an info window with the current profile and character name.

## Commands

- `/clicky show [window_id]` - Show a specific window.
- `/clicky hide [window_id]` - Hide a specific window.
- `/clicky addnew` - Add a new window.
- `/clicky edit on` - Enable edit mode.
- `/clicky edit off` - Disable edit mode.
- `/clicky` - Toggle the info window displaying the addon version, current profile, and character name.
- `/clicky save` - Manually save the current settings.

## Installation

1. Download the latest release of Clicky.
2. Extract the contents to your `Ashita\addons` directory.
3. Load the addon in-game using the Ashita command: `/addon load clicky`.

## Usage

### Basic Usage

1. Load the addon using the command: `/addon load clicky`.
2. Use `/clicky addnew` to create a new window.
3. Use `/clicky edit on` to enable edit mode.
4. Right-click on a button to edit its name and command - you can add new buttons horizontally from here which will create next to the button being edited.
5. Use the "+" button to add new buttons vertically.
6. Use the "x" button to close a window.
7. Use `/clicky edit off` to disable edit mode and hide the edit controls.

### Example

```plaintext
/clicky show 1
/clicky hide 1
/clicky addnew
/clicky edit on
/clicky edit off
/clicky
/clicky save

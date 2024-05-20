Clicky
Clicky is an addon for Final Fantasy XI that provides customizable buttons to perform various in-game actions. It leverages ImGui for rendering a user interface that allows players to execute commands quickly.

Author
Author: Oxos
Version: 1.0
Description: Customizable Buttons for Final Fantasy XI.
Requirements
Ashita: This addon requires Ashita, a third-party tool for Final Fantasy XI, to function correctly.
Features
Customizable Buttons: Add buttons to perform various actions in the game.
Movable Windows: The main button window and additional action windows are movable and their positions are saved.
Conditional Display: Show specific buttons based on certain conditions (e.g., when a target is selected).
Installation
Download: Download the Clicky addon files.
Extract: Extract the files into your Ashita\addons directory.
Enable: Enable the addon in your Ashita configuration.
Usage
Commands:
/clicky show: Show the Clicky buttons.
/clicky hide: Hide the Clicky buttons.
Configuration
The addon uses a settings file to manage its configuration. The default settings are:

lua
Copy code
local default_settings = T{
    visible = T{ true, },
    opacity = T{ 1.0, },
    window_pos = { x = 350, y = 700 }, -- Default window position
    thf_window_pos = { x = 510, y = 700 } -- Default THF window position
};
Code Overview
Initialization
The addon initializes by loading the settings and setting up event handlers for rendering and command handling.
Functions
UpdateVisibility(visible)
Updates the visibility of the main window and saves the settings.

execute_commands(commands, delay)
Executes a sequence of commands with a specified delay between each command.

has_target()
Checks if the player has a target selected.

render_additional_buttons()
Renders additional action buttons for the "THF" actions. These buttons are movable.

render_buttons()
Renders the main GUI buttons and conditionally displays additional buttons based on user interaction and game state.

Event Handlers
d3d_present: Handles the rendering of buttons every frame.
update_target_cb: Updates the visibility of the "Attack Target" button based on the player's target.
command_cb: Handles /clicky commands to show or hide the buttons.
unload_cb: Saves the settings when the addon is unloaded.
Example
Here is an example of how the buttons and additional action windows are rendered:

lua
Copy code
if imgui.Begin('Clicky Buttons', true, windowFlags) then
    if imgui.Button('THF', { 150, 50 }) then
        show_thf_actions = not show_thf_actions
    end

    -- Allow the window to be moved
    local x, y = imgui.GetWindowPos()
    clicky.settings.window_pos.x = x
    clicky.settings.window_pos.y = y
    settings.save()

    imgui.End()
end

if show_thf_actions then
    render_additional_buttons()
end
Notes
The buttons for "THF" actions include "Sneak Attack", "Trick Attack", "WS", "Steal", "Mug", "Hide", and "Flee".
The "Attack Target" button appears next to the player when a target is selected.
Support
For support and further assistance, please refer to the Ashita documentation and community forums.
local imgui = require('imgui')

-- Define dark blue style
local darkBluePfStyles = {
    {ImGuiCol_Text, {1.0, 1.0, 1.0, 1.0}}, -- White text
    {ImGuiCol_TextDisabled, {0.5, 0.5, 0.5, 1.0}}, -- Grey text
    {ImGuiCol_WindowBg, {0.0, 0.0, 0.2, 1.0}}, -- Dark blue background
    {ImGuiCol_ChildBg, {0.0, 0.0, 0.2, 1.0}}, -- Dark blue background
    {ImGuiCol_PopupBg, {0.0, 0.0, 0.2, 1.0}}, -- Dark blue background
    {ImGuiCol_Border, {0.3, 0.3, 0.3, 1.0}}, -- Grey border
    {ImGuiCol_BorderShadow, {0.0, 0.0, 0.0, 0.0}}, -- No border shadow
    {ImGuiCol_FrameBg, {0.1, 0.1, 0.3, 1.0}}, -- Dark blue frame background
    {ImGuiCol_FrameBgHovered, {0.2, 0.2, 0.4, 1.0}}, -- Lighter blue when hovered
    {ImGuiCol_FrameBgActive, {0.3, 0.3, 0.5, 1.0}}, -- Even lighter blue when active
    {ImGuiCol_TitleBg, {0.0, 0.0, 0.2, 1.0}}, -- Dark blue title background
    {ImGuiCol_TitleBgActive, {0.1, 0.1, 0.3, 1.0}}, -- Lighter blue when active
    {ImGuiCol_TitleBgCollapsed, {0.0, 0.0, 0.2, 1.0}}, -- Dark blue when collapsed
    {ImGuiCol_Button, {0.1, 0.1, 0.3, 1.0}}, -- Dark blue button
    {ImGuiCol_ButtonHovered, {0.2, 0.2, 0.4, 1.0}}, -- Lighter blue button when hovered
    {ImGuiCol_ButtonActive, {0.3, 0.3, 0.5, 1.0}}, -- Even lighter blue button when active
    {ImGuiCol_Header, {0.0, 0.0, 0.2, 1.0}}, -- Dark blue header
    {ImGuiCol_HeaderHovered, {0.2, 0.2, 0.4, 1.0}}, -- Lighter blue header when hovered
    {ImGuiCol_HeaderActive, {0.3, 0.3, 0.5, 1.0}}, -- Even lighter blue header when active
    -- Add other colors as needed
}

-- Push and pop style functions
function PushStyles(styles)
    for _, s in pairs(styles) do
        imgui.PushStyleColor(s[1], s[2])
    end
end

function PopStyles(styles)
    for _ in pairs(styles) do
        imgui.PopStyleColor()
    end
end

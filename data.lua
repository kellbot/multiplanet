-- These are some style prototypes that the tutorial uses
-- You don't need to understand how these work to follow along
local styles = data.raw["gui-style"].default

styles["mpse_content_frame"] = {
    type = "frame_style",
    parent = "inside_shallow_frame_with_padding",
    vertically_stretchable = "on",
    horizontally_stretchable = "on",
}

styles["mpse_controls_flow"] = {
    type = "horizontal_flow_style",
    vertical_align = "center",
    horizontal_spacing = 20,
    bottom_margin = 8
}

styles["mpse_bottom_flow"] = {
    type = "horizontal_flow_style",
    parent = "relative_gui_bottom_flow",
    top_margin = 8
}


styles["mpse_controls_textfield"] = {
    type = "textbox_style",
    width = 50
}

styles["mpse_deep_frame"] = {
    type = "frame_style",
    parent = "slot_button_deep_frame",
    vertically_stretchable = "on",
    horizontally_stretchable = "on",
    top_margin = 16,
    left_margin = 8,
    right_margin = 8,
    bottom_margin = 4
}

require "entities/stargate"
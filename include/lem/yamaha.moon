require "karaskel"
{ :make_style, :load_config, :save_config } = require "lem.util"

import insert from table

expected_styles = {
  ["Top box bg1"]: {
    align: 7,
  },
  ["Top box bg2"]: {
    color1: ass_style_color 113, 71, 192, 0,
    align: 7,
  },
  ["Top box text"]: {
    color1: ass_style_color 34, 34, 34, 0,
    fontname: "Nirmala UI",
    fontsize: 66,
    align: 4,
    bold: true,
  }
}

-- Default configuration values
DEFAULT_CONFIG = {
  sign_x: 97
  sign_y: 155
  blur: 0.6
  height: 80
}

-- Load config from disk or use defaults
get_config = ->
  config = load_config "yamaha"

  -- Ensure all default values exist
  for k, v in pairs DEFAULT_CONFIG
    config[k] = config[k] or v

  config

setup_yamaha_sign = (subs) ->
  -- Obtain the styles from the script
  meta, styles = karaskel.collect_head subs

  -- Ensure the expected styles exist, create them if not
  ioff = 0
  for name, style in pairs expected_styles
    if not styles[name]
      aegisub.debug.out "Creating style #{name}\n"

      line = with make_style!
        .name = name
      for k, v in pairs style
        line[k] = v

      subs.append line
      ioff += 1

  -- Collect the styles again so karaskel can populate any of its own fields
  meta, styles = karaskel.collect_head subs

  style_items = {}
  for i = 1, styles.n do
    table.insert style_items, styles[i].name

  -- Load saved configuration
  config = get_config()

  dialog_config = {
    -- bg1
    { class: "label", label: "bg1 style", x: 0, y: 0, width: 1 },
    { class: "dropdown", items: style_items, name: "bg1_style", value: "Top box bg1", x: 1, y: 0, width: 2 },
    -- bg2
    { class: "label", label: "bg2 style", x: 0, y: 1, width: 1 },
    { class: "dropdown", items: style_items, name: "bg2_style", value: "Top box bg2", x: 1, y: 1, width: 2 },
    -- text
    { class: "label", label: "text style", x: 0, y: 2, width: 1 },
    { class: "dropdown", items: style_items, name: "text_style", value: "Top box text", x: 1, y: 2, width: 2 },
    -- height
    { class: "label", label: "height", x: 0, y: 3, width: 1 },
    { class: "floatedit", name: "height", x: 1, y: 3, width: 2, value: config.height, min: 0, max: 1000, step: 1 },
    -- sign_x
    { class: "label", label: "sign_x", x: 0, y: 4, width: 1 },
    { class: "floatedit", name: "sign_x", x: 1, y: 4, width: 2, value: config.sign_x, min: 0, max: 4000, step: 1 },
    -- sign_y
    { class: "label", label: "sign_y", x: 0, y: 5, width: 1 },
    { class: "floatedit", name: "sign_y", x: 1, y: 5, width: 2, value: config.sign_y, min: 0, max: 4000, step: 1 },
    -- blur
    { class: "label", label: "blur", x: 0, y: 6, width: 1 },
    { class: "floatedit", name: "blur", x: 1, y: 6, width: 2, value: config.blur, min: 0, max: 10, step: 0.1 }
  }

  btn, result = aegisub.dialog.display dialog_config, { "Ok", "Defaults", "Repop styles", "Cancel" }
  switch btn
    when "Defaults"
      config = DEFAULT_CONFIG
      save_config "yamaha", config
      nil
    when "Repop styles"
      aegisub.set_undo_point "Create Yamaha styles"
      nil
    when "Cancel"
      aegisub.cancel!
      nil
    when "Ok" then
      -- Save configuration
      config = {
        height: result.height
        sign_x: result.sign_x
        sign_y: result.sign_y
        blur: result.blur
      }
      save_config "yamaha", config

      with result
        .ioff = ioff
        .height = config.height
        .sign_x = config.sign_x
        .sign_y = config.sign_y
        .blur = config.blur

{ :setup_yamaha_sign, :get_config }

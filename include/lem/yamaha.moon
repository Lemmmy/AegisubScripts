require "karaskel"
{ :make_style } = require "lem.util"

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

setup_yamaha_sign = (subs, default_height) ->
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
    { class: "floatedit", name: "height", x: 1, y: 3, width: 2, value: default_height, min: 0, max: 1000, step: 1 }
  }

  btn, result = aegisub.dialog.display dialog_config, { "Ok", "Repop styles", "Cancel" }
  switch btn
    when "Repop styles"
      aegisub.set_undo_point "Create Yamaha styles"
      nil
    when "Cancel"
      aegisub.cancel!
      nil
    when "Ok" then
      with result
        .ioff = ioff

{ :setup_yamaha_sign }

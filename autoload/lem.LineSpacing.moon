util = require "aegisub.util"
require "karaskel"

lem = require "lem.util"
{ :make_line, :parse_pos, :remove_pos, :pos, :load_config, :save_config } = lem

export script_filename    = "lem.LineSpacing"
export script_name        = "Line spacing"
export script_description = "Adjusts the line spacing of selected lines. Lines must be manually split by \\N"
export script_author      = "Lemmmy"
export script_version     = "1.0"

script_dir = ": Lemmmy :/"

adjust_line_spacing = (subs, selection) ->
  config = load_config script_filename

  -- Display the config dialog
  dialog_config = {
    { class: "label", label: "Increase line spacing by (px)", x: 0, y: 0, width: 7 },
    { class: "floatedit", name: "amount", value: config.amount or -10, x: 0, y: 1, width: 7 }
  }

  btn, result = aegisub.dialog.display dialog_config, { "Adjust", "Cancel" }, { "ok": "Adjust", "cancel": "Cancel" }
  return if not btn

  -- Collect karaskel data for each line
  meta, styles = karaskel.collect_head subs

  new_lines = {}

  for i = 1, #selection
    line = subs[selection[i]]
    karaskel.preproc_line subs, meta, styles, line

    -- Find the base position
    x, y = parse_pos line.text
    x = x or line.x
    y = y or line.y
    new_line_height = line.height + result.amount

    -- Split the text by \N into a new subtitle line for each one
    temp_text, line_count = line.text\gsub "\\N", "\n"
    temp_text = remove_pos temp_text
    total_height = new_line_height * line_count
    top = y - total_height / 2

    i = 0
    for part in temp_text\gmatch "[^\n]+"
      new_line = util.copy line

      -- Figure out the new Y position
      new_y = top + (new_line_height * i)
      new_pos = pos x, new_y
      i += 1

      new_line.text = "{#{new_pos}}#{part}"
      table.insert new_lines, new_line

  -- Remove the original lines
  start_i = selection[1]
  for i = #selection, 1, -1
    subs.delete selection[i]

  -- Add the new lines back in
  for i = 1, #new_lines
    subs.insert start_i + i - 1, new_lines[i]

  save_config script_filename, { amount: result.amount }

  aegisub.set_undo_point script_name
  selection -- Keep the initial selection

adjust_line_spacing_validation = (subs, selection, active) -> #selection > 0

aegisub.register_macro script_dir .. script_name, script_description, adjust_line_spacing, adjust_line_spacing_validation

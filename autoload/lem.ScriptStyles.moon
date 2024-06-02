util = require "aegisub.util"
require "karaskel"

lem = require "lem.util"
{ :make_line } = lem

export script_name        = "Script styles"
export script_description = "Convert line prefixes to styles"
export script_author      = "Lemmmy"
export script_version     = "1.0"

script_dir = ": Lemmmy :/"

def_text = "KUROSAWA,Kurosawa"

-- Looks for an existing "ScriptStyles" line in the script
find_existing_data_line = (subs) ->
  for i = 1, #subs
    line = subs[i]

    if line.class == "dialogue" and line.comment and line.effect == script_name
      return i, line

  return nil, nil

script_styles = (subs, selection) ->
  -- Look for existing configuration in the script
  existing_data_line_i, existing_data_line = find_existing_data_line subs
  existing_data = if existing_data_line then
    existing_data_line.text\gsub "\\N", "\n"
  else
    def_text

  -- Display the config dialog
  dialog_config = {
    { class: "label", label: "Comma-separated. First column - prefix; second column - style", x: 0, y: 0, width: 7 },
    { class: "textbox", name: "data", text: existing_data, x: 0, y: 1, width: 7, height: 5 }
  }

  btn, result = aegisub.dialog.display dialog_config, { "Restyle", "Cancel" }, { "ok": "Restyle", "cancel": "Cancel" }
  return if not btn

  -- Parse the data. Provided format is newline-separated comma-separated values
  replacements = {}
  data = result.data

  for s in data\gmatch "[^\n]+" do
    prefix, style = s\match "([^,]+),([^,]+)"

    if prefix and style
      replacements[prefix] = style
    else
      aegisub.debug.out "Invalid format for line: `#{s}`\n"
      return

  -- Iterate over the lines and replace the prefixes
  for i = 1, #selection do
    line = subs[selection[i]]

    for prefix, style in pairs replacements
      if line.text\match "^#{prefix}: "
        with line
          -- Remove the prefix from the line
          .text = .text\gsub "^#{prefix}: ", ""
          -- Change the style of the line
          .style = style

        -- Update the line
        subs[selection[i]] = line

  -- Save the configuration to the top of the script
  new_text = data\gsub "\n", "\\N"
  if existing_data_line
    existing_data_line.text = new_text
    subs[existing_data_line_i] = existing_data_line
  else
    existing_data_line = with make_line!
      .comment = true
      .effect = script_name
      .text = new_text
      .end_time = 0
    subs.insert(1, existing_data_line)

  aegisub.set_undo_point script_name
  selection -- Keep the initial selection

script_styles_validation = (subs, selection, active) -> true

aegisub.register_macro script_dir .. script_name, script_description, script_styles, script_styles_validation

util = require "aegisub.util"
require "karaskel"

lem = require "lem.util"
{ :make_line, :is_path_absolute } = lem

export script_name        = "Script inserter"
export script_description = "Insert lines into the script while timing"
export script_author      = "Lemmmy"
export script_version     = "1.0"

script_dir = ": Lemmmy :/"

default_path = "?script/script.md"

-- Looks for an existing "ScriptInserter" line in the script
find_existing_data_line = (subs) ->
  for i = 1, #subs
    line = subs[i]

    if line.class == "dialogue" and line.comment and line.effect == script_name
      return i, line

  return nil, nil

get_configured_path = (subs) ->
  existing_data_line_i, existing_data_line = find_existing_data_line subs
  return if not existing_data_line then ""
  path = aegisub.decode_path existing_data_line.text
  return path, existing_data_line_i, existing_data_line, existing_data_line.text

-- Reads the script file at the path. Errors if the file doesn't exist. Skips lines that don't match dialogue lines
-- (which also includes lines that have already been inserted, demarked by "[D]" at the start). A dialogue line looks
-- like: "SPEAKER: Text"
read_next_line = (path, skip) ->
  skip = skip or 0
  line_n = 0
  skipped = 0

  found_line = nil
  found_line_n = nil

  f, err = io.open path, "r"
  if not f
    aegisub.message.error "Failed to open file: #{err}"
    return

  for line in f\lines!
    line_n += 1

    if line\match "^[A-Z%-]+: .+"
      if skipped < skip
        skipped += 1
        continue

      found_line = line
      found_line_n = line_n
      break

  f\close!

  return found_line, found_line_n

-- Prefixes the spoecified line number with "[D]" (or any other marker) in the original file
update_inserted_line = (path, line_n, marker) ->
  marker = marker or "[D]"

  -- Read all lines from the file and determine the line ending
  lines = {}
  eol = nil

  f, err = io.open path, "r"
  if not f
    aegisub.message.error "Failed to open file: #{err}"
    return

  for line in f\lines!
    eol = if line\match "\r$" then "\r\n" else "\n"
    table.insert lines, (line\gsub "\r\n", "\n")
  f\close!

  -- Modify the specific line if it exists
  if line_n <= #lines
    lines[line_n] = marker .. lines[line_n]

    -- Write all lines back to the file
    f, err = io.open path, "w"
    if not f
      aegisub.message.error "Failed to open file: #{err}"
      return

    for _, line in ipairs lines
      f\write line, eol
    f\close!

  return

script_inserter_config = (subs, selection) ->
  -- Look for existing configuration in the script
  _, existing_data_line_i, existing_data_line, path = get_configured_path subs

  -- Display the config dialog
  dialog_config = {
    { class: "label", label: "Path of script file", x: 0, y: 0, width: 20, height: 1 },
    { class: "edit", name: "path", text: path or default_path, x: 0, y: 1, width: 20, height: 1 },
    { class: "label", label: " ", x: 0, y: 2, width: 20, height: 1 },
  }

  btn, result = aegisub.dialog.display dialog_config, { "Save", "Cancel" }, { "ok": "Save", "cancel": "Cancel" }
  return if not btn

  -- Verify the file exists by reading the next line
  path = aegisub.decode_path result.path
  next_line, next_line_n = read_next_line path
  if not next_line
    aegisub.message.error "File does not exist or has no readable/remaining dialogue lines"
    return

  -- Save the configuration to the top of the script
  if existing_data_line
    existing_data_line.text = path
    subs[existing_data_line_i] = existing_data_line
  else
    existing_data_line = with make_line!
      .comment = true
      .effect = script_name
      .text = result.path
      .end_time = 0
    subs.insert(1, existing_data_line)

  aegisub.set_undo_point script_name
  selection -- Keep the initial selection

script_inserter_config_validation = (subs, selection, active) -> true

script_inserter_macro = (marker, skip) ->
  (subs, selection) ->
    path, _, _ = get_configured_path subs
    if not path
      aegisub.message.error "No path configured"
      return

    next_line, next_line_n = read_next_line path, skip
    if not next_line
      aegisub.message.error "No readable/remaining dialogue lines"
      return

    -- Change the text of the selected line to the next line in the file
    if marker != "[S]"
      existing_line = subs[selection[1]]
      existing_line.text = next_line
      subs[selection[1]] = existing_line

    -- Update the inserted line in the file
    update_inserted_line path, next_line_n, marker

    aegisub.set_undo_point script_name
    selection -- Keep the initial selection

script_inserter_macro_validation = (subs, selection, active) -> #selection == 1

aegisub.register_macro script_dir .. script_name .. " config", script_description, script_inserter_config, script_inserter_config_validation
aegisub.register_macro script_dir .. script_name .. " insert", script_description, (script_inserter_macro "[D]", 0), script_inserter_macro_validation
aegisub.register_macro script_dir .. script_name .. " insert next", script_description, (script_inserter_macro "[D]", 1), script_inserter_macro_validation
aegisub.register_macro script_dir .. script_name .. " skip", script_description, (script_inserter_macro "[S]", 0), script_inserter_macro_validation

export script_name        = "Furigana"
export script_description = [[
Renders furigana for selected lines using the syntax [text|furigana]. Assumes the lines have already been wrapped
with \N. Simpler approach and usage than karaskel's more advanced furigana layout.
]]
export script_author      = "Lemmmy"
export script_version     = "1.0"

script_dir = ": Lemmmy :/"

util = require "aegisub.util"
require "karaskel"

lem = require "lem.util"
{ :make_basic_line, :alignments, :pos, :remove_pos } = lem

furi_height_mul = 0.6
furi_font_mul = 0.75
furi_style_mul = 0.75

make_furi_style = (style, style_name_furi) ->
  with util.copy style
    .name = style_name_furi
    .fontsize = style.fontsize * furi_font_mul -- TODO: Tune these values
    .outline = style.outline * furi_style_mul
    .shadow = style.shadow * furi_style_mul
    .align = alignments.bottom_center

-- Parses a set of furigana tags (`foo [A|B] bar\N[C|D] baz`) from a string and returns a table with this structure:
-- {
--   { type="normal", text="foo" },
--   { type="furigana", text="A", furigana="B" },
--   { type="normal", text="bar" },
--   { type="newline" },
--   { type="furigana", text="C", furigana="D" },
--   { type="normal", text="baz" },
--   ...
-- }
parse_text_furi = (text) ->
  result = {}

  -- If the text is empty, return an empty result
  if not text or text == ""
    return result

  current_pos = 1
  len = text\len!
  normal_buffer = "" -- Buffer for normal text

  while current_pos <= len
    char = text\sub(current_pos, current_pos)

    -- If we find an opening brace, check if it's a furigana tag
    if char == "["
      -- If we have accumulated normal text, add it to the result
      if normal_buffer != ""
        table.insert(result, { type: "normal", text: normal_buffer })
        normal_buffer = ""

      -- Look for the closing brace and separator
      start_pos = current_pos + 1
      separator_pos = nil
      end_pos = nil

      for i = start_pos, len
        if text\sub(i, i) == "|"
          separator_pos = i
        elseif text\sub(i, i) == "]"
          end_pos = i
          break

      -- If we found a valid furigana tag
      if separator_pos and end_pos and separator_pos < end_pos
        text_part = text\sub(start_pos, separator_pos - 1)
        furigana_part = text\sub(separator_pos + 1, end_pos - 1)

        table.insert(result, {
          type: "furigana",
          text: text_part,
          furigana: furigana_part
        })

        current_pos = end_pos + 1
      else
        -- Not a valid furigana tag, treat as normal text
        normal_buffer ..= char
        current_pos += 1
    -- Check for newline sequence \N
    elseif char == "\\" and current_pos + 1 <= len and text\sub(current_pos + 1, current_pos + 1) == "N"
      -- If we have accumulated normal text, add it to the result
      if normal_buffer != ""
        table.insert(result, { type: "normal", text: normal_buffer })
        normal_buffer = ""

      -- Add a newline entry
      table.insert(result, { type: "newline" })

      -- Skip both the backslash and the N
      current_pos += 2
    else
      -- Add to normal text buffer
      normal_buffer ..= char
      current_pos += 1

  -- Add any remaining normal text
  if normal_buffer != ""
    table.insert(result, { type: "normal", text: normal_buffer })

  return result

has_any_furi = (parsed_furi) ->
  for i = 1, #parsed_furi
    if parsed_furi[i].type == "furigana" then return true
  false

should_skip_line = (line, parsed_furi) ->
  parsed_furi = parsed_furi or parse_text_furi line.text
  line.comment or not line.style or line.style\match " furi$" or not has_any_furi parsed_furi

furigana_line = (subs, selection, meta, styles, ioff, selection_i) ->
  -- Fetch and preprocess the line
  line = subs[selection[selection_i] + ioff]
  karaskel.preproc_line subs, meta, styles, line

  parsed_furi = parse_text_furi line.text
  normal_lines = {}
  furi_lines = {}
  if should_skip_line line, parsed_furi then return ioff

  -- Comment out the original line
  subs[selection[selection_i] + ioff] = with line
    .comment = true

  -- Running normal text, reset on newline
  normal_text = ""
  normal_line_i = 1
  line_has_furi = false
  -- Track the running width of the normal text, so that we can figure out how far from the leftmost boundary of the
  -- overall text each furigana segment needs to be placed. However, they will need to be positioned in a separate step
  -- at the end, once we know the full width of the normal text.
  normal_text_width = 0

  furi_style = styles["#{line.style} furi"]
  _, furi_height = aegisub.text_extents(furi_style, "Aj")
  furi_height *= furi_height_mul

  for i = 1, #parsed_furi
    furi = parsed_furi[i]
    if furi.type == "furigana"
      -- Normal part
      normal_text_width = aegisub.text_extents(line.styleref, normal_text)
      normal_text ..= furi.text
      new_normal_text_width = aegisub.text_extents(line.styleref, furi.text)

      -- Furigana part
      table.insert furi_lines, with make_basic_line furi.furigana, line.start_time, line.end_time, "#{line.style} furi"
        .layer = line.layer + 1
        .furi_x = normal_text_width + (new_normal_text_width / 2)
        .furi_line_i = normal_line_i

      -- Additionally, mark the current normal line as having furigana, so its height can be adjusted accordingly
      line_has_furi = true
    else if furi.type == "newline"
      -- Flush the normal text
      table.insert normal_lines, with make_basic_line normal_text, line.start_time, line.end_time, line.style
        .layer = line.layer
        .has_furi = line_has_furi

      normal_text = ""
      normal_line_i += 1
      line_has_furi = false
    else
      normal_text ..= furi.text

  -- Flush the last normal text
  table.insert normal_lines, with make_basic_line normal_text, line.start_time, line.end_time, line.style
    .layer = line.layer
    .has_furi = line_has_furi

  -- Add the normal text lines and run karaskel to populate their positions. Run backwards so that we can
  -- calculate the running height of the lines.
  running_height = 0
  for i = #normal_lines, 1, -1
    ioff += 1
    line_i = selection[selection_i] + ioff

    normal_line = with normal_lines[i]
      .text = remove_pos .text
    subs.insert line_i, normal_line
    karaskel.preproc_line subs, meta, styles, normal_line

    subs[line_i] = with normal_line
      .text = "{#{pos normal_line.x, line.y + running_height}}#{normal_line.text}"
      .running_height = running_height
    karaskel.preproc_line subs, meta, styles, normal_line

    y_mul = if normal_line.valign == "top" then 1 else -1
    running_height += normal_line.height * y_mul
    if normal_line.has_furi
      running_height += furi_height * y_mul

  -- Add the furigana lines
  for i = 1, #furi_lines
    ioff += 1

    -- TODO: Support left and right alignments
    furi_line = furi_lines[i]
    normal_line = normal_lines[furi_line.furi_line_i]
    y_mul = if normal_line.valign == "top" then 1 else -1
    furi_x = normal_line.left + (furi_line.furi_x)
    furi_y = normal_line.top + normal_line.running_height - (furi_height * (1 - furi_height_mul) * y_mul)

    subs.insert (selection[selection_i] + ioff), with furi_line
      .text = "{#{pos furi_x, furi_y}}#{furi_line.text}"

  return ioff

furigana = (subs, selection) ->
  -- Obtain the existing styles from the script
  meta, styles = karaskel.collect_head subs

  -- Iterate the selection first and ensure a furi style for each selected line exists.
  ioff = 0
  for i = 1, #selection
    line = subs[selection[i] + ioff]
    style_name = line.style
    style_name_furi = "#{style_name} furi"
    if should_skip_line line then continue
    if styles[style_name_furi] then continue

    new_style = make_furi_style styles[style_name], style_name_furi
    subs.append new_style
    ioff += 1

  -- Collect the styles again so karaskel can populate any of its own fields
  meta, styles = karaskel.collect_head subs

  for i = 1, #selection
    ioff = furigana_line subs, selection, meta, styles, ioff, i

  aegisub.set_undo_point script_name

furigana_validation = (subs, selection, active) ->
  #selection >= 1

aegisub.register_macro script_dir .. script_name, script_description, furigana, furigana_validation

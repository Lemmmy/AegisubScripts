util = require "aegisub.util"
require "karaskel"

lem = require "lem.util"
{ :clean_tags } = lem

export script_filename    = "lem.MaskSign"
export script_name        = "Mask sign"
export script_description = "Temporarily makes selected lines red and transparent, or vice versa"
export script_author      = "Lemmmy"
export script_version     = "1.0"

script_dir = ": Lemmmy :/"

mask_tags = "\\c&H0000FF&\\alpha&H80&"

mask_sign = (subs, selection) ->
  -- For each line, swap \c and \alpha tags with \origc and \origalpha, and make the current color red if \orig tags
  -- aren't present
  for i = 1, #selection
    line = subs[selection[i]]
    text = line.text

    -- If the line is already masked, unmask it
    if text\find mask_tags
      text = text\gsub mask_tags, ""
      text = text\gsub "\\origc", "\\c"
      text = text\gsub "\\origalpha", "\\alpha"
      text = clean_tags text
    else
      -- If the line isn't masked, mask it
      text = text\gsub "\\c", "\\origc"
      text = text\gsub "\\alpha", "\\origalpha"
      text = clean_tags "{#{mask_tags}}#{text}"

    line.text = text
    subs[selection[i]] = line

  aegisub.set_undo_point script_name
  selection -- Keep the initial selection

mask_sign_validation = (subs, selection, active) -> #selection > 0

aegisub.register_macro script_dir .. script_name, script_description, mask_sign, mask_sign_validation

export script_name        = "Repetition"
export script_description = "Alpha-times repeated lines (x2, x3, x4...) Assumes a font with fixed-width digits."
export script_author      = "Lemmmy"
export script_version     = "1.0"

script_dir = ": Lemmmy :/"

util = require "aegisub.util"
require "karaskel"

lem = require "lem.util"
{ :pos, :rect, :clip, :clean_tags, :parse_pos, :remove_pos } = lem

repetition = (subs, selection) ->
  count = #selection
  digits = #tostring count

  text = subs[selection[1]].text

  for i = 1, #selection
    line = subs[selection[i]]

    shown_n = if i > 1 then "x#{tostring i}" else ""
    hidden_n = if i > 1 then "0"\rep digits - #shown_n else "x#{count}"
    hidden_alpha = if #hidden_n > 0 then "{\\alpha&HFF&}#{hidden_n}" else ""

    line.text = "#{text} #{shown_n}#{hidden_alpha}"
    subs[selection[i]] = line

  aegisub.set_undo_point script_name

repetition_validation = (subs, selection, active) ->
  #selection >= 2

aegisub.register_macro script_dir .. script_name, script_description, repetition, repetition_validation

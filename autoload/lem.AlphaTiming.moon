export script_name        = "Alpha timing"
export script_description = "Replaces markers or karaoke tags in the selected lines with alpha timing"
export script_author      = "Lemmmy"
export script_version     = "2.0"

script_dir = ": Lemmmy :/"

util = require "aegisub.util"
require "karaskel"

alpha = "{\\alpha&HFF&}"

alpha_timing_karaoke = (subs, selection) ->
  idx = selection[1]
  line = subs[idx]

  meta, styles = karaskel.collect_head subs
  karaskel.preproc_line subs, meta, styles, line

  subs.delete idx -- Remove the existing line

  alpha_i = 1
  text = "" -- cumulative text for the line

  for i = 1, #line.kara
    syl = line.kara[i]
    text ..= syl.text

    remaining_text = ""
    for j = i + 1, #line.kara
      remaining_text ..= line.kara[j].text

    new_line = with util.copy line
      .start_time = line.start_time + syl.start_time
      .end_time = line.start_time + syl.end_time
      .text = text .. alpha .. remaining_text

    subs.insert idx + i - 1, new_line

alpha_timing_markers = (subs, selection) ->
  for i = 1, #selection
    line = subs[selection[i]]

    -- Replace all the markers after `i` with `{\alpha&HFF&}`, and removes all
    -- the markers at or before `i`.
    alpha_i = 1
    line.text = line.text\gsub "{}", (marker) ->
      if alpha_i < i
        alpha_i += 1
        ""
      else
        alpha

    subs[selection[i]] = line

alpha_timing = (subs, selection) ->
  -- If only one line is selected, assume karaoke mode.
  if #selection == 1
    alpha_timing_karaoke(subs, selection)
  else
    alpha_timing_markers(subs, selection)

  aegisub.set_undo_point script_name
  selection

alpha_timing_validation = (subs, selection, active) ->
  #selection >= 1

aegisub.register_macro script_dir .. script_name, script_description, alpha_timing, alpha_timing_validation

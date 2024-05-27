--[[
README:

Replaces markers (`{}`) in the selected lines with alpha timing. Similar to,
but simpler than, Masquerade's Alpha Time/Alpha Text scripts, which are probably
way better than this.

Instructions:
- In the line you want to alpha-time, put markers `{}` where you want the alpha 
  timing to be. For example: `Next{} e{}pi{}sode`
- Split the line into two or more lines, where you want each timing point to
  be, e.g. using Ctrl+D.
- Run the script

TODO:
- Version using karaoke timing tags instead of markers + manual splitting
]]

script_name        = "Alpha timing"
script_description = "Replaces markers in the selected lines with alpha timing"
script_author      = "Lemmmy"
script_version     = "1.0"

local script_dir = ": Lemmmy :/"

local function alpha_timing(subtitles, selection)
  for i = 1, #selection do
    local line = subtitles[selection[i]]
    local text = line.text

    -- Replace all the markers after `i` with `{\alpha&HFF&}`, and removes all
    -- the markers at or before `i`.
    local alpha = "{\\alpha&HFF&}"
    local j = 1
    line.text = text:gsub("{}", function(marker)
      if j < i then
        j = j + 1
        return ""
      else
        return alpha
      end
    end)

    subtitles[selection[i]] = line
  end

  aegisub.set_undo_point(script_name)
  return selection -- Keep the initial selection
end

local function alpha_timing_validation(subtitles, selection, active)
  return #selection > 1
end

aegisub.register_macro(
  script_dir .. script_name, script_description, 
  alpha_timing, alpha_timing_validation
)


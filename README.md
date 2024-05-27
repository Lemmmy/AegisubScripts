Collection of ridiculous Aegisub scripts for incredibly specific tasks. May bite. No refunds.

# Alpha Timing
Replaces markers (`{}`) in the selected lines with alpha timing. Similar to, but simpler than, Masquerade's Alpha Time/Alpha Text scripts, which are probably way better than this.

Instructions:
- In the line you want to alpha-time, put markers `{}` where you want the alpha timing to be. For example: `Next{} e{}pi{}sode`
- Split the line into two or more lines, where you want each timing point to be, e.g. using Ctrl+D.
- Run the script

TODO: make it use a single line with karaoke timing tags

# Chorus
Takes two or more identical dialogue lines with different styles, and overlaps them stacked vertically:

![image](https://github.com/Lemmmy/AegisubScripts/assets/858456/5ec7355c-fedf-4cb5-a471-44b92d8d68fb)

Does not abide by collision detection, so if the chorus lines appear alongside other dialogue, one of the lines will need to be given a `\pos()` tag - all the lines will then be given that same position.

![image](https://github.com/Lemmmy/AegisubScripts/assets/858456/45593197-e17a-4d61-a1bd-b48172935867)

# Script Styles
Populates styles for selected lines based on actor names at the start of each line.

When given dialogue like this:
```
TOYOTA: Hello!
KUROSAWA: Hello!
MINAMIYA: Hello!
MINAMIYA: I'll be your guide for the tour of the Yamaha Toyooka factory today.
```

The script can be used to replace all of the actor names (`NAME: `, colon and space not required in the csv) with the specified styles. The names will be removed from the dialogue.

![image](https://github.com/Lemmmy/AegisubScripts/assets/858456/2c016858-d15c-4b44-b741-276c43fe338e)
![image](https://github.com/Lemmmy/AegisubScripts/assets/858456/0339624b-9c8f-4f33-8114-92241c449340)

# Yamaha Sign
Silly animated sign for a specific video - for top left corner. Left aligned scale and swipe animation, with second scaling stage and extra color background.

![dummy_002_94-cropped](https://github.com/Lemmmy/AegisubScripts/assets/858456/fc0b20a8-1b82-41d5-aa60-44e5610106cb)

https://github.com/Lemmmy/AegisubScripts/assets/858456/20c3c210-9ccb-4f89-9c84-ec6e4dd4f561

# Yamaha Sign 2
Silly animated sign for a specific video - for name cards. Horizontally centered scale animation with text spacing + fade.

![image](https://github.com/Lemmmy/AegisubScripts/assets/858456/8f63c25a-d8c7-4b51-af85-cef9e253fbe8)

https://github.com/Lemmmy/AegisubScripts/assets/858456/5892344f-c48a-44e9-9c08-285f85ea6a94


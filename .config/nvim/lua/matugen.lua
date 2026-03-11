 local M = {}

 function M.setup()
   require('base16-colorscheme').setup {
     -- Background tones
     base00 = '#291416', -- Default Background
     base01 = '#452124', -- Lighter Background (status bars)
     base02 = '#3e1e20', -- Selection Background
     base03 = '#756162', -- Comments, Invisibles
     -- Foreground tones
     base04 = '#b6afaf', -- Dark Foreground (status bars)
     base05 = '#f3f2f2', -- Default Foreground
     base06 = '#f3f2f2', -- Light Foreground
     base07 = '#f3f2f2', -- Lightest Foreground
     -- Accent colors
     base08 = '#d83340', -- Variables, XML Tags, Errors
     base09 = '#ded354', -- Integers, Constants
     base0A = '#de8e54', -- Classes, Search Background
     base0B = '#e46771', -- Strings, Diff Inserted
     base0C = '#eae394', -- Regex, Escape Chars
     base0D = '#ec939a', -- Functions, Methods
     base0E = '#eab894', -- Keywords, Storage
     base0F = '#51080d', -- Deprecated, Embedded Tags
   }
 end

 -- Register a signal handler for SIGUSR1 (matugen updates)
 local signal = vim.uv.new_signal()
 signal:start(
   'sigusr1',
   vim.schedule_wrap(function()
     package.loaded['matugen'] = nil
     require('matugen').setup()
   end)
 )

 return M
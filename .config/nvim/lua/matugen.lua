 local M = {}

function M.setup()
  require('base16-colorscheme').setup({
    base00 = '#161616',
    base01 = '#262626',
    base02 = '#303030',
    base03 = '#636363',
    base04 = '#dde1e6',
    base05 = '#f2f4f8',
    base06 = '#f2f4f8',
    base07 = '#f2f4f8',
    base08 = '#ee5396',
    base09 = '#be95ff',
    base0A = '#42be65',
    base0B = '#33b1ff',
    base0C = '#b180ff',
    base0D = '#80ceff',
    base0E = '#96e9ad',
    base0F = '#8c023e',
  })

  local hi = function(group, opts)
    vim.api.nvim_set_hl(0, group, opts)
  end

  hi('TelescopeNormal',         { fg = '#f2f4f8',          bg = '#161616' })
  hi('TelescopeBorder',         { fg = '#636363',             bg = '#161616' })
  hi('TelescopePromptNormal',   { fg = '#f2f4f8',          bg = '#161616' })
  hi('TelescopePromptBorder',   { fg = '#636363',             bg = '#161616' })
  hi('TelescopePromptPrefix',   { fg = '#33b1ff',             bg = '#161616' })
  hi('TelescopePromptCounter',  { fg = '#dde1e6',  bg = '#161616' })
  hi('TelescopePromptTitle',    { fg = '#161616',             bg = '#33b1ff' })
  hi('TelescopePreviewTitle',   { fg = '#161616',             bg = '#42be65' })
  hi('TelescopeResultsTitle',   { fg = '#161616',             bg = '#be95ff' })
  hi('TelescopeSelection',      { fg = '#f2f4f8',          bg = '#303030' })
  hi('TelescopeSelectionCaret', { fg = '#33b1ff',             bg = '#303030' })
  hi('TelescopeMatching',       { fg = '#33b1ff',             bold = true })
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

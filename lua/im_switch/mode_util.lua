----------------------------------------------------------------------------
-- THIS FILE WAS COPIED FROM https://github.com/nvim-lualine/lualine.nvim --
-- AND THE LICENSE BELONGS TO THEM.                                       --
----------------------------------------------------------------------------

local M = {}

M.map = {
  ['n']     = 'NORMAL',
  ['no']    = 'O-PENDING',
  ['nov']   = 'O-PENDING',
  ['noV']   = 'O-PENDING',
  ['no\22'] = 'O-PENDING',
  ['niI']   = 'NORMAL',
  ['niR']   = 'NORMAL',
  ['niV']   = 'NORMAL',
  ['nt']    = 'NORMAL',
  ['ntT']   = 'NORMAL',
  ['v']     = 'VISUAL',
  ['vs']    = 'VISUAL',
  ['V']     = 'V-LINE',
  ['Vs']    = 'V-LINE',
  ['\22']   = 'V-BLOCK',
  ['\22s']  = 'V-BLOCK',
  ['s']     = 'SELECT',
  ['S']     = 'S-LINE',
  ['\19']   = 'S-BLOCK',
  ['i']     = 'INSERT',
  ['ic']    = 'INSERT',
  ['ix']    = 'INSERT',
  ['R']     = 'REPLACE',
  ['Rc']    = 'REPLACE',
  ['Rx']    = 'REPLACE',
  ['Rv']    = 'V-REPLACE',
  ['Rvc']   = 'V-REPLACE',
  ['Rvx']   = 'V-REPLACE',
  ['c']     = 'COMMAND',
  ['cv']    = 'EX',
  ['ce']    = 'EX',
  ['r']     = 'REPLACE',
  ['rm']    = 'MORE',
  ['r?']    = 'CONFIRM',
  ['!']     = 'SHELL',
  ['t']     = 'TERMINAL',
}

---return the mode name based on `mode_char`
---@param mode? string: literal char result from `vim.api.nvim_get_mode()`. If none, current mode is used.
---@return string: mode name
function M.get_mode(mode)
  local mode_code = mode
  if mode_code == nil then
    mode_code = vim.api.nvim_get_mode().mode
  end
  return M.map[mode_code] or mode_code
end

return M

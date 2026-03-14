-- ==========================================
-- im_switch.nvim Basic Configuration Example
-- ==========================================

-- Load the plugin
require('im_switch').setup({
  -- Input method per mode
  imname = {
    norm = 'keyboard-us',    -- Normal mode: use English keyboard
    ins = 'rime',            -- Insert mode: use Rime (Chinese)
    cmd = 'keyboard-us',     -- Command mode: use English keyboard
    vis = 'keyboard-us',     -- Visual mode: use English keyboard
    sel = 'keyboard-us',     -- Select mode: use English keyboard
    opr = 'keyboard-us',     -- Operator-pending mode: use English keyboard
    term = 'keyboard-us',    -- Terminal mode: use English keyboard
    lang = 'keyboard-us',    -- Language mode: use English keyboard
  },

  -- Remember prior IM per mode (Layer 1)
  remember_prior = true,

  -- Enable Rime state memory (Layer 2) - Core Innovation!
  remember_rime_state = true,

  -- Backend selection method
  -- "auto" - automatically detect best backend (recommended)
  -- "dbus" - use D-Bus backends (ldbus or lgi)
  -- "lgi" - force use lgi backend
  -- "remote" - force use fcitx5-remote CLI
  rime_state_method = 'auto',

  -- Cache Rime state for this many milliseconds (default: 5000ms)
  -- Higher values = fewer D-Bus calls but potentially stale data
  rime_state_cache_ttl = 5000,

  -- Automatically define ModeChanged autocmd
  define_autocmd = true,

  -- Autostart fcitx5 if not running
  autostart_fcitx5 = true,

  -- Log level: "info", "warn", "error"
  log = "warn",

  -- Startup message
  msg = "im_switch.nvim loaded successfully!",
})

-- ==========================================
-- Common Configuration Scenarios
-- ==========================================

--[[
Scenario 1: Minimal Configuration (Just Works)
-----------------------------------------------
Use this if you want the plugin to work with minimal setup.

require('im_switch').setup({
  imname = {
    norm = 'keyboard-us',
    ins = 'rime',
  },
  remember_rime_state = true,  -- Remember Rime Chinese/English state
})
]]--

--[[
Scenario 2: Multiple IMs
------------------------
Use different IMs for different modes.

require('im_switch').setup({
  imname = {
    norm = 'keyboard-us',
    ins = 'rime',
    cmd = 'keyboard-us',
    vis = 'pinyin',  -- Use Pinyin in visual mode for searching
  },
})
]]--

--[[
Scenario 3: Disable Rime State Memory
--------------------------------------
If you don't use Rime or don't need state memory.

require('im_switch').setup({
  imname = {
    norm = 'keyboard-us',
    ins = 'rime',
  },
  remember_rime_state = false,  -- Disable Layer 2
  rime_state_method = 'remote', -- Use CLI only
})
]]--

--[[
Scenario 4: Force Specific Backend
----------------------------------
Force use of a specific backend for troubleshooting.

require('im_switch').setup({
  imname = {
    norm = 'keyboard-us',
    ins = 'rime',
  },
  rime_state_method = 'lgi',  -- Force lgi backend
})
]]--

--[[
Scenario 5: Advanced Cache Configuration
-----------------------------------------
Fine-tune cache for performance.

require('im_switch').setup({
  imname = {
    norm = 'keyboard-us',
    ins = 'rime',
  },
  rime_state_cache_ttl = 10000,  -- 10 second cache
  log = "info",  -- Enable verbose logging
})
]]--

-- ==========================================
-- Using Commands
-- ==========================================

--[[
Common Commands:
----------------
:ImSwitch                    - Show help
:ImSwitchSetName rime        - Force switch to Rime
:ImSwitchGeneious            - Switch to appropriate IM for current mode
:ImSwitchSetPrior rime ins   - Set Rime as prior for insert mode
:ImSwitchGetImname ins       - Get IM name for insert mode
:ImSwitchGetImnames          - Get all IM names
]]--

-- ==========================================
-- Lua API Usage
-- ==========================================

--[[
You can also use the Lua API directly:

-- Get current IM
local backend = require('im_switch.backend')
local current_im = backend.get_current_im()

-- Switch to specific IM
backend.switch_to_im('rime')

-- Get Rime state
local ascii_mode = backend.get_rime_ascii_mode()

-- Set Rime state (true = English, false = Chinese)
backend.set_rime_ascii_mode(false)

-- Get cache info
local cache_info = backend.get_rime_cache_info()
print(vim.inspect(cache_info))
]]--

-- ==========================================
-- Troubleshooting
-- ==========================================

--[[
If the plugin is not working:

1. Check if fcitx5-remote is available:
   :!fcitx5-remote -n

2. Enable verbose logging:
   log = "info"

3. Check backend detection:
   Run: :ImSwitchGetImnames

4. Verify Rime is enabled in fcitx5

5. Test manual switching:
   :ImSwitchSetName rime

6. Check if ldbus/lgi is installed:
   :lua print(pcall(require, "dbus.shared"))
   :lua print(pcall(require, "lgi"))
]]--

-- ==========================================
-- im_switch.nvim Basic Configuration Example
-- ==========================================

-- Minimal Configuration (Recommended)
------------------------------------
-- Only 3 configuration items needed!
require('im_switch').setup({
  -- Input method per mode (only norm/ins/cmd supported)
  -- 推荐配置：所有模式都使用 rime，插件会自动处理中英文状态
  imname = {
    norm = 'rime',    -- Normal mode: 使用 rime 英文模式
    ins = 'rime',     -- Insert mode: 使用 rime (恢复之前的中英文状态)
    cmd = 'rime',     -- Command mode: 使用 rime 英文模式
  },

  -- Enable Rime state memory (remembers Chinese/English state per buffer)
  enable_rime_memory = true,

  -- Log level: "info", "warn", "error"
  log_level = "warn",
})

-- ==========================================
-- What This Configuration Does
-- ==========================================

--[[
Core Features (Automatic):
--------------------------
1. Mode Auto-Switching:
   - Normal mode: Rime 强制英文模式 (用于输入命令)
   - Insert mode: Rime 恢复之前的中英文状态
   - Command mode: Rime 强制英文模式 (用于输入命令)

2. Per-Buffer State Memory:
   - 每个 buffer 记住自己的输入法状态
   - 在 buffer 之间切换时自动恢复各自的中文/英文状态

3. Rime Chinese/English State Memory:
   - 记住你是在中文模式 (ascii_mode=false) 还是英文模式 (ascii_mode=true)
   - 返回 buffer 时自动恢复正确的状态

4. 优先使用 Rime 英文模式:
   - norm 和 cmd 模式强制使用 rime 英文模式
   - 避免在不同输入法之间频繁切换
   - 提高响应速度和用户体验

5. Always-Enabled Autocmds:
   - ModeChanged 事件自动挂钩
   - 无需手动设置
]]--

-- ==========================================
-- Available Commands
-- ==========================================

--[[
Simplified Commands (only 3!):
-------------------------------
:ImSwitch          - Show help
:ImSwitchSet rime  - Force switch to Rime
:ImSwitchStatus    - Display current status

Example Usage:
:ImSwitchSet keyboard-us  - Switch to US keyboard
:ImSwitchStatus           - Show current IM and buffer states
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

-- Get Rime state (true = English, false = Chinese)
local ascii_mode = backend.get_rime_ascii_mode()

-- Set Rime state
backend.set_rime_ascii_mode(false)  -- Switch to Chinese
backend.set_rime_ascii_mode(true)   -- Switch to English

-- Get cache info
local cache_info = backend.get_rime_cache_info()
print(vim.inspect(cache_info))
]]--

-- ==========================================
-- Common Scenarios
-- ==========================================

--[[
Scenario 1: 带中文注释的单文件
----------------------------
编辑一个带中文注释的 Lua 文件:
- Normal mode: Rime 英文模式 (输入命令)
- Insert mode: Rime 中文模式 (输入注释)
- Command mode: Rime 英文模式 (输入命令)

Scenario 2: 多文件不同状态
---------------------------
- Buffer 1 (README.md): Insert 模式使用中文
- Buffer 2 (script.lua): Insert 模式使用英文
- 在 buffer 之间切换时自动恢复各自的状态

Scenario 3: 优先使用 Rime 英文模式
-----------------------------------
- Norm/Cmd 模式: Rime 强制切换到英文模式
- Ins 模式: Rime 恢复之前的中英文状态
- 避免在不同输入法之间切换，提高响应速度

Scenario 4: Insert 模式状态恢复
--------------------------------
- 在 Insert 模式下离开 buffer (中文输入)
- 切换到 Normal 模式，跳转到其他 buffer
- 返回原 buffer → Insert 模式恢复中文输入
]]--

-- ==========================================
-- Troubleshooting
-- ==========================================

--[[
If the plugin is not working:

1. Check if fcitx5 is running:
   :!fcitx5-remote -n

2. Enable verbose logging:
   log_level = "info"

3. Verify D-Bus connection:
   :lua print(require('im_switch.backend').get_backend().name)

4. Test manual switching:
   :ImSwitchSet rime

5. Check if lgi is installed:
   :lua print(pcall(require, "lgi"))

6. View current status:
   :ImSwitchStatus
]]--

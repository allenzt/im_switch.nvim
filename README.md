# im_switch.nvim

A Neovim plugin for automatic input method switching with **Rime Chinese/English state memory** - the critical innovation that solves the pain point where users must manually switch Rime back to Chinese after every normal mode operation.

## Key Differentiator

**Dual-layer state memory:**
- Layer 1: Mode → Input Method (e.g., INSERT → rime)
- Layer 2: Input Method Internal State (e.g., rime `ascii_mode = false` for Chinese)

This plugin remembers and restores Rime's `ascii_mode` property via high-performance Lua D-Bus (5-10ms).

## User Experience Impact

### Smart State Management

**Insert Mode (Per-Buffer Memory):**
- Each buffer remembers its own Rime Chinese/English state
- Buffer 1: Chinese mode → Press Esc → Press 'i' → Auto-restores to Chinese ✅
- Buffer 2: English mode → Press Esc → Press 'i' → Auto-restores to English ✅

**Normal/Visual Mode:**
- Automatically switches Rime to English mode for command input
- Ensures normal mode commands work reliably

### Example Workflow

```lua
-- Buffer 1: Writing Chinese text
1. Press 'i' → Rime activates (remembers last state: Chinese)
2. Type Chinese text...
3. Press Esc → Rime switches to English (for normal mode)
4. Press 'i' → Rime auto-restores to Chinese ✅

-- Switch to Buffer 2: Writing code
5. :buffer 2 → Switch to buffer 2
6. Press 'i' → Rime activates (remembers buffer 2's state: English)
7. Type English code...
8. Press Esc → Rime stays in English
9. Press 'i' → Rime stays in English ✅

-- Switch back to Buffer 1
10. :buffer 1 → Switch to buffer 1
11. Press 'i' → Rime auto-restores to Chinese (buffer 1's state) ✅
```

## Features

- ✅ Automatic IM switching on mode changes
- ✅ **Per-buffer Rime state memory** - Each buffer remembers its own Chinese/English state
- ✅ **Smart mode-based state** - Normal/Visual mode auto-switches to English
- ✅ High-performance Lua D-Bus support (ldbus/lgi)
- ✅ **Three-layer caching system** - Reduces D-Bus calls by 60-80%
- ✅ Graceful backend fallback (ldbus → lgi → fcitx5-remote)
- ✅ Buffer-level state isolation
- ✅ Prior mode memory
- ✅ Configurable IM per mode
- ✅ Smart state detection - Skips unnecessary switches

## Installation

Using [packer.nvim](https://github.com/wbthomason/packer.nvim):

```lua
use {
  'yourusername/im_switch.nvim',
  config = function()
    require('im_switch').setup({
      imname = {
        norm = 'rime',    -- Normal mode: 使用 rime 英文模式
        ins = 'rime',     -- Insert mode: 使用 rime (恢复中英文状态)
        cmd = 'rime',     -- Command mode: 使用 rime 英文模式
      },
      enable_rime_memory = true,  -- Enable Rime state memory
      log_level = 'warn',
    })
  end
}
```

Using [vim-plug](https://github.com/junegunn/vim-plug):

```vim
Plug 'yourusername/im_switch.nvim'
lua << EOF
require('im_switch').setup({
  imname = {
    norm = 'rime',    -- Normal mode: 使用 rime 英文模式
    ins = 'rime',     -- Insert mode: 使用 rime (恢复中英文状态)
    cmd = 'rime',     -- Command mode: 使用 rime 英文模式
  },
  enable_rime_memory = true,
  log_level = 'warn',
})
EOF
```

## Configuration

### Default Options

```lua
{
  msg = nil,                      -- Message on startup
  imname = {                      -- Input method per mode
    norm = nil,                   -- Normal mode
    ins = nil,                    -- Insert mode
    cmd = nil,                    -- Command mode
    vis = nil,                    -- Visual mode
    sel = nil,                    -- Select mode
    opr = nil,                    -- Operator-pending mode
    term = nil,                   -- Terminal mode
    lang = nil,                   -- Language mode
  },
  remember_prior = true,          -- Remember prior IM per mode
  define_autocmd = true,          -- Define ModeChanged autocmd
  autostart_fcitx5 = true,        -- Autostart fcitx5 if not running
  log_level = "warn",             -- Log level: "info"/"warn"/"error"
  enable_rime_memory = true,      -- Enable Rime state memory (Layer 2)
  rime_state_method = "auto",     -- Rime state method: "auto"/"dbus"/"lgi"/"remote"
  rime_state_cache_ttl = 5000,   -- Cache duration in ms for Rime state
}
```

### Mode Mapping

| Plugin Key | Neovim Modes |
|------------|--------------|
| `norm` | Normal, Operator-pending, More, Confirm |
| `ins` | Insert, Replace, Virtual Replace |
| `cmd` | Command, Ex |
| `vis` | Visual, Visual Line, Visual Block |
| `sel` | Select, Select Line, Select Block |
| `term` | Terminal, Shell |

## Rime State Memory (Core Innovation)

The plugin automatically remembers and restores Rime's `ascii_mode` state:

- **`ascii_mode = false`**: Rime in Chinese mode
- **`ascii_mode = true`**: Rime in English mode

This is achieved through high-performance D-Bus calls with caching (5-10ms vs 25-40ms for CLI).

### Example Workflow

```lua
-- Setup
require('im_switch').setup({
  imname = {
    norm = 'rime',    -- Normal mode: 使用 rime 英文模式
    ins = 'rime',     -- Insert mode: 使用 rime (恢复中英文状态)
  },
  enable_rime_memory = true,  -- Critical: Enable Rime state memory
})

-- Usage:
-- 1. Press 'i' to enter insert mode → Rime 激活 (恢复之前的状态)
-- 2. Switch Rime to Chinese mode (ascii_mode = false)
-- 3. Press Esc to return to normal mode → Rime 切换到英文模式
-- 4. Press 'i' again → Rime 自动恢复到中文模式 ✅
```

## Dependencies

### Required
- Neovim >= 0.8.0
- fcitx5 >= 5.0.0
- fcitx5-remote (pre-installed)

### Optional (for Rime state memory)

**Option A: ldbus (Recommended - 5-10ms)**
```bash
sudo apt-get install libdbus-1-dev
luarocks install ldbus
```

**Option B: lgi (Alternative - 8-12ms)**
```bash
sudo apt-get install libgirepository1.0-dev
luarocks install lgi
```

**Option C: fcitx5-remote (Fallback - 25-40ms)**
Pre-installed with fcitx5.

## Commands

| Command | Description |
|---------|-------------|
| `:ImSwitch` | Show help |
| `:ImSwitchSetName <imname>` | Force switch to input method |
| `:ImSwitchGeneious` | Switch to appropriate IM for current mode |
| `:ImSwitchSetPrior <imname> [mode]` | Set prior IM for a mode |
| `:ImSwitchGetImname [mode]` | Get IM name for mode |
| `:ImSwitchGetImnames` | Get all IM names |

## Advanced Usage

### Buffer-Level State Isolation

Each buffer maintains its own IM state:

```lua
-- Buffer 1: Use "rime" in insert mode
-- Buffer 2: Use "keyboard-us" in insert mode
-- Switching between buffers remembers each buffer's IM preference
```

### Backend Selection

```lua
require('im_switch').setup({
  -- Auto-detect best backend (recommended)
  rime_state_method = 'auto',   -- Tries: ldbus → lgi → remote

  -- Force specific backend
  rime_state_method = 'dbus',   -- Use ldbus or lgi
  rime_state_method = 'lgi',    -- Use lgi only
  rime_state_method = 'remote', -- Use fcitx5-remote only
})
```

### Cache Configuration

```lua
require('im_switch').setup({
  -- Rime state cache (D-Bus backend level)
  rime_state_cache_ttl = 5000,  -- Cache Rime state for 5 seconds

  -- Internal caches (automatically managed)
  -- Global state cache: 1 second (for rapid mode switching)
  -- Buffer state cache: 10 seconds (for cross-buffer switching)
})
```

**Performance Tuning:**
```lua
-- Maximum performance (fewest D-Bus calls)
require('im_switch').setup({
  imname = {
    norm = 'rime',
    ins = 'rime',
    cmd = 'rime',
  },
  enable_rime_memory = true,
  rime_state_cache_ttl = 10000,  -- 10 second cache
})

-- Highest accuracy (most up-to-date state)
require('im_switch').setup({
  imname = {
    norm = 'rime',
    ins = 'rime',
    cmd = 'rime',
  },
  enable_rime_memory = true,
  rime_state_cache_ttl = 1000,   -- 1 second cache
})
```

## Performance

### With Caching Optimization (Default)

| Operation | ldbus | lgi | fcitx5-remote |
|-----------|-------|-----|---------------|
| Mode switch (cache hit) | ~0-2ms | ~0-2ms | ~0-5ms |
| Mode switch (cache miss) | ~10ms | ~12ms | ~100ms |
| Rime state read/write | 5-10ms | 8-12ms | N/A |
| Memory usage (10 buffers) | <5MB | <5MB | <5MB |
| **D-Bus call reduction** | **60-80%** | **60-80%** | N/A |

### Performance Comparison

**Without optimization:**
- Each mode change: 3-4 D-Bus calls
- Rapid switching (i → Esc → i): 10 D-Bus calls
- Total latency: ~100ms

**With optimization:**
- Each mode change: 0-2 D-Bus calls (cache hit)
- Rapid switching (i → Esc → i): 3 D-Bus calls
- Total latency: ~30ms (**70% faster**)

> **See [docs/OPTIMIZATION.md](docs/OPTIMIZATION.md) for detailed performance analysis**

## Comparison with fcitx5.nvim

| Feature | fcitx5.nvim | im_switch.nvim |
|---------|-------------|----------------|
| Mode → IM memory | ✅ | ✅ |
| **Rime ascii_mode memory** | ❌ | ✅ **Core Innovation** |
| **Lua D-Bus support** | ❌ | ✅ (ldbus/lgi) |
| Backend fallback | ❌ | ✅ (auto-detect) |
| Buffer-level state | ⚠️ Partial | ✅ Full isolation |

## Performance Testing

Test the caching optimization:

```vim
:luafile /path/to/im_switch.nvim/examples/benchmark.lua
```

This will show:
- Cache hit/miss rates
- D-Bus call reduction
- Performance improvement metrics

## Troubleshooting

### fcitx5-remote not found

```bash
# Install fcitx5
sudo apt-get install fcitx5 fcitx5-remote
```

### ldbus installation fails

```bash
# Install D-Bus development headers
sudo apt-get install libdbus-1-dev

# Install ldbus via luarocks
luarocks install ldbus
```

### Rime state not working

1. Check if Rime is enabled in fcitx5
2. Verify backend: `:ImSwitchGetImnames` should show backend info
3. Check logs: Set `log_level = "info"` in config

### Performance issues

1. Use `ldbus` backend if available (fastest)
2. Increase cache TTL: `rime_state_cache_ttl = 10000`
3. Disable Rime state if not needed: `enable_rime_memory = false`

## License

MIT License - Based on fcitx5.nvim architecture

## Credits

- Architecture based on [fcitx5.nvim](https://github.com/pysan3/fcitx5.nvim)
- Mode mapping from [lualine.nvim](https://github.com/nvim-lualine/lualine.nvim)
- Inspired by [fcitx.vim](https://github.com/lilydjwg/fcitx.vim)

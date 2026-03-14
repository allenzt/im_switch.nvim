# Quick Start Guide

## Installation

### 1. Install Dependencies

```bash
# Required
sudo apt-get install fcitx5 fcitx5-remote

# Optional (for Rime state memory - Recommended!)
sudo apt-get install libdbus-1-dev
luarocks install ldbus
```

### 2. Install Plugin

Using [packer.nvim](https://github.com/wbthomason/packer.nvim):

```lua
use {
  'yourusername/im_switch.nvim',
  config = function()
    require('im_switch').setup({
      imname = {
        norm = 'keyboard-us',
        ins = 'rime',
        cmd = 'keyboard-us',
      },
      remember_rime_state = true,  -- Enable Rime state memory!
    })
  end
}
```

### 3. Verify Installation

Run the test script in Neovim:

```vim
:luafile /path/to/im_switch.nvim/examples/test_installation.lua
```

All tests should pass.

## Basic Usage

1. **Enter Insert Mode**: Press `i`
   - IM automatically switches to Rime
   - Rime remembers if you were in Chinese or English mode

2. **Return to Normal Mode**: Press `Esc`
   - IM automatically switches to English keyboard
   - Rime state (Chinese/English) is saved

3. **Enter Insert Mode Again**: Press `i`
   - IM automatically switches to Rime
   - **Rime automatically restores your previous Chinese/English state!** ⭐

## Common Commands

| Command | Description |
|---------|-------------|
| `:ImSwitch` | Show help |
| `:ImSwitchSetName rime` | Force switch to Rime |
| `:ImSwitchGetImnames` | See all configured IMs |

## Troubleshooting

### IM doesn't switch

1. Check fcitx5 is running:
   ```bash
   ps aux | grep fcitx5
   ```

2. Test fcitx5-remote:
   ```bash
   fcitx5-remote -n  # Get current IM
   fcitx5-remote -s rime  # Switch to Rime
   ```

3. Enable verbose logging:
   ```lua
   require('im_switch').setup({
     log = "info",  -- Show detailed logs
   })
   ```

### Rime state doesn't restore

1. Check if ldbus is installed:
   ```vim
   :lua print(pcall(require, "dbus.shared"))
   ```

2. Verify Rime is enabled in fcitx5:
   - Open fcitx5 configuration
   - Check "Rime" is in the input method list

3. Check backend detection:
   ```vim
   :ImSwitchGetImnames
   ```
   Should show the detected backend.

## Next Steps

- Read the full [README.md](README.md) for advanced configuration
- Check [examples/basic_config.lua](examples/basic_config.lua) for more examples
- Customize your IM mappings in the config

## The Core Innovation

What makes this plugin special is **Layer 2 state memory**:

- **Layer 1**: Mode → Input Method (like other plugins)
- **Layer 2**: Rime Chinese/English state (unique to this plugin!)

This means you never have to manually switch Rime back to Chinese after pressing Esc! 🎉

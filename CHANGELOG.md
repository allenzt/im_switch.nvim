# Changelog

All notable changes to this project will be documented in this file.

## [Unreleased]

### Added
- Initial release of im_switch.nvim
- Dual-layer state memory (mode → IM + IM internal state)
- Rime `ascii_mode` memory via D-Bus
- High-performance Lua D-Bus support (ldbus/lgi)
- Graceful backend fallback (ldbus → lgi → fcitx5-remote)
- Buffer-level state isolation
- Configurable IM per mode
- Prior mode memory
- Comprehensive command interface
- Cache management for Rime state

## [0.1.0] - 2025-03-14

### Features
- Automatic input method switching on mode changes
- Support for all Neovim modes (normal, insert, visual, select, replace, command, terminal)
- Backend auto-detection (ldbus, lgi, fcitx5-remote)
- Rime state memory with configurable TTL cache
- Buffer-level state isolation
- User commands for manual control

### Configuration
- `imname`: Configure IM per mode
- `remember_prior`: Enable/disable prior memory
- `remember_rime_state`: Enable Rime state memory (Layer 2)
- `rime_state_method`: Backend selection (auto/dbus/lgi/remote)
- `rime_state_cache_ttl`: Cache duration in ms
- `define_autocmd`: Automatic mode change handling
- `autostart_fcitx5`: Start fcitx5 if not running

### Commands
- `:ImSwitch` - Show help
- `:ImSwitchSetName <imname>` - Force switch to input method
- `:ImSwitchGeneious` - Switch to appropriate IM for current mode
- `:ImSwitchSetPrior <imname> [mode]` - Set prior IM for a mode
- `:ImSwitchGetImname [mode]` - Get IM name for mode
- `:ImSwitchGetImnames` - Get all IM names

### Dependencies
- Neovim >= 0.8.0
- fcitx5 >= 5.0.0
- fcitx5-remote (included)
- ldbus or lgi (optional, for Rime state memory)

### Performance
- Mode switch: < 20ms (D-Bus) / < 100ms (CLI)
- Rime state read/write: 5-12ms (D-Bus with caching)
- Memory usage: < 5MB with 10 buffers

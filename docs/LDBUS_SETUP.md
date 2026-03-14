# ldbus 安装指南

## 检查ldbus是否已安装

运行以下命令检查：

```bash
lua -e "pcall(require,'dbus.shared')"
```

如果没有任何输出，说明ldbus已安装 ✅

如果看到错误信息，说明需要安装。

## 安装ldbus

### Ubuntu/Debian

```bash
# 安装libdbus开发库
sudo apt-get update
sudo apt-get install libdbus-1-dev

# 使用luarocks安装ldbus
luarocks install ldbus
```

### Arch Linux

```bash
# 安装dbus
sudo pacman -S dbus

# 安装ldbus
luarocks install ldbus
```

### Fedora

```bash
# 安装dbus开发库
sudo dnf install dbus-devel

# 安装ldbus
luarocks install ldbus
```

### 验证安装

安装完成后，验证：

```bash
lua -e "pcall(require,'dbus.shared')" && echo "✓ ldbus 安装成功"
```

## 性能说明

使用 `backend = "ldbus"` 的优势：

- ⚡ **最快速度**: 5-10ms 延迟
- ✅ **原生绑定**: Lua D-Bus原生支持
- ✅ **Rime状态记忆**: 完整支持Rime中英文状态记忆
- ✅ **三层缓存**: 全局、Buffer、D-Bus三层缓存优化

## 注意事项

⚠️ **使用 `backend = "ldbus"` 后：**
- 如果ldbus不可用，插件初始化会失败
- 不会自动降级到其他后端
- 请确保ldbus已正确安装

## 故障排查

如果遇到问题：

### 1. 检查后端是否初始化成功

在Neovim中运行：

```vim
:lua print(require('im_switch.backend').get_backend().name)
```

应该输出：`ldbus`

### 2. 查看详细日志

配置中已启用 `log = "info"`，查看日志：

```vim
:messages
```

### 3. 如果ldbus不可用

临时解决方案：使用自动检测模式

```lua
backend = "auto",  -- 自动选择最佳后端
```

## 完整配置示例

```lua
require("im_switch").setup({
  imname = {
    norm = "keyboard-us",
    ins = "rime",
    cmd = "keyboard-us",
  },
  remember_rime_state = true,
  backend = "ldbus",        -- ⚡ 强制使用ldbus
  rime_state_cache_ttl = 5000,
  remember_prior = true,
  define_autocmd = true,
  autostart_fcitx5 = true,
  log = "info",             -- 便于调试
})
```

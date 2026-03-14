# im_switch.nvim 快速开始

## 🎯 一键安装 ldbus

在 Neovim 中运行：

```vim
:ImSwitchInstallLdbus
```

这是**推荐方式**，最简单最快！插件会自动：
1. 下载 ldbus 源码
2. 编译安装
3. 提示重启 Neovim

## 📋 安装步骤

### 1. 安装系统依赖

```bash
sudo apt-get install -y libdbus-1-dev build-essential git
```

### 2. 安装 ldbus

**方式 A: Neovim 命令（推荐）**
```vim
:ImSwitchInstallLdbus
```

**方式 B: 安装脚本**
```bash
cd ~/data/repo/input/im_switch.nvim
./scripts/install_ldbus_from_source.sh
```

### 3. 重启 Neovim

安装完成后重启 Neovim 使更改生效。

## ✅ 验证安装

```vim
:lua print(require('im_switch.backend').get_backend().name)
" 应该输出: ldbus
```

## 🎉 完成！

现在你拥有：
- ⚡ **最快速度**: ldbus (5-10ms)
- ✅ **Rime 状态记忆**: 自动记住中英文状态
- 🎯 **Smart Normal Mode**: Normal 模式保持 Rime 英文
- 🔧 **自动配置**: 无需手动设置

## 📚 更多信息

- **docs/INSTALL_LDBUS.md**: 详细安装指南
- **docs/SMART_NORMAL_MODE.md**: Smart Normal Mode 说明
- **AUTOMATED_TESTING.md**: 自动化测试工具

## 🐛 遇到问题？

查看故障排查：`docs/INSTALL_LDBUS.md#故障排查`

或运行自动化测试：
```bash
./scripts/auto_test.sh
```

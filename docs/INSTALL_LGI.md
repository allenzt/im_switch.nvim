# lgi 后端安装指南

## 问题描述

当前系统没有安装 `gobject-introspection` 开发包，无法编译安装 lgi。

## 解决方案

### 选项1: 手动安装依赖 (推荐)

```bash
# 安装 gobject-introspection 开发包
sudo apt-get update
sudo apt-get install -y libgirepository1.0-dev gobject-introspection

# 安装 lgi
cd ~/data/repo/input/im_switch.nvim
./scripts/install_lgi.sh
```

### 选项2: 使用 fcitx5-remote (当前方案)

当前配置 `backend = "auto"` 已经自动使用 fcitx5-remote 作为后端：

**优点**:
- ✅ 无需额外安装
- ✅ 基本功能正常

**缺点**:
- ❌ 不支持 Rime 状态记忆
- ⚠️ 延迟较高 (25-40ms)

### 选项3: 等待 ldbus 支持

ldbus 是另一个 D-Bus 后端选择，但目前 luarocks 上没有 Lua 5.1 版本。

## 验证安装

安装完成后，验证 lgi 是否可用：

```bash
# 测试 lgi
lua -e "require('lgi')" && echo "✓ lgi 可用" || echo "✗ lgi 不可用"
```

## 更新配置

安装成功后，更新配置文件 `~/.config/nvim/lua/plugins/fcitx.lua`:

```lua
backend = "lgi",  -- 使用 lgi 后端
```

重启 Neovim，验证后端：

```vim
:lua print(require('im_switch.backend').get_backend().name)
```

应该输出: `lgi`

## 性能对比

| 后端 | 延迟 | Rime状态 | 状态 |
|------|------|---------|------|
| lgi | 8-12ms | ✅ | 需安装 |
| fcitx5-remote | 25-40ms | ❌ | ✅ 当前 |

## 自动化脚本

项目提供了以下自动化脚本：

- `scripts/install_lgi.sh` - lgi 安装脚本
- `scripts/auto_test.sh` - 自动化测试脚本
- `examples/ldbus_diagnosis.lua` - 后端诊断工具

## 下一步

1. 选择一个安装选项
2. 运行对应的安装命令
3. 更新配置文件
4. 重启 Neovim
5. 运行测试验证: `./scripts/auto_test.sh`

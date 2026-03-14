# Lazy.nvim 自动配置指南

## 快速开始

### 方法1: 使用本地路径（开发调试）

在 `~/.config/nvim/lua/plugins/im_switch.lua` 中创建：

```lua
return {
  {
    dir = "~/data/repo/input/im_switch.nvim",  -- 本地开发路径
    event = "VeryLazy",
    config = function()
      require("im_switch").setup({
        imname = {
          norm = "keyboard-us",
          ins = "rime",
          cmd = "keyboard-us",
        },
        remember_prior = true,
        remember_rime_state = true,
        rime_state_method = "auto",
        rime_state_cache_ttl = 5000,
        define_autocmd = true,
        autostart_fcitx5 = true,
        log = "warn",
      })
    end,
  },
}
```

### 方法2: 从GitHub安装（正式使用）

```lua
return {
  {
    "allenzt/im_switch.nvim",
    event = "VeryLazy",
    config = function()
      require("im_switch").setup({
        imname = {
          norm = "keyboard-us",
          ins = "rime",
        },
        remember_rime_state = true,
        rime_state_method = "auto",
      })
    end,
  },
}
```

## 完整Lazy.nvim配置

参考 `examples/lazy_config.lua`，包含：
- im_switch.nvim配置
- 自动更新配置
- 快捷键设置
- 性能优化

复制到 `~/.config/nvim/init.lua`：

```bash
cp examples/lazy_config.lua ~/.config/nvim/init.lua
```

## 自动更新配置

### 在 `init.lua` 中配置

```lua
require("lazy").setup({
  spec = {
    -- ... 你的插件配置
  },
  opts = {
    checker = {
      enabled = true,           -- 启用更新检查
      frequency = 3600,         -- 每小时检查一次
      notify = true,            -- 有更新时通知
    },
    update = {
      mode = "sync",            -- 启动时同步更新
      notify = true,
    },
  },
})
```

### 手动命令

在Neovim中：

```vim
:Lazy update          " 更新所有插件
:Lazy update im_switch.nvim  " 更新im_switch.nvim
:Lazy check            " 检查更新
:Lazy log              " 查看更新日志
:Lazy sync             " 同步插件
```

## 自动测试

### 方法1: 使用自动化测试脚本

```bash
# 运行交互式菜单
./scripts/auto_update_test.sh

# 运行全部流程
./scripts/auto_update_test.sh --all
```

这会自动：
1. 检查环境（Neovim、fcitx5）
2. 更新插件代码
3. 语法检查
4. 运行自动化测试
5. 生成测试报告

### 方法2: 在Neovim中运行测试

```vim
:luafile examples/test_automated.lua
:lua require("test_automated").run_all()
```

### 方法3: 使用诊断工具

```vim
:luafile examples/diagnose_buffer_state.lua
:lua require("diagnose_buffer_state").run_all()
```

## 自动启动配置

### 使用systemd用户服务（Linux）

创建 `~/.config/systemd/user/nvim-auto-start.service`：

```ini
[Unit]
Description=Neovim Auto Start
After=graphical-session.target

[Service]
Type=oneshot
ExecStart=/usr/bin/nvim --headless +qa
RemainAfterExit=yes

[Install]
WantedBy=default.target
```

启用服务：

```bash
systemctl --user enable nvim-auto-start.service
systemctl --user start nvim-auto-start.service
```

### 使用crontab（自动启动测试）

编辑crontab：

```bash
crontab -e
```

添加：

```cron
# 每小时测试一次
0 * * * * cd ~/data/repo/input/im_switch.nvim && ./scripts/auto_update_test.sh --all

# 每天凌晨3点运行完整测试
0 3 * * * cd ~/data/repo/input/im_switch.nvim && ./scripts/auto_update_test.sh --all
```

## 持续集成（CI/CD）

### GitHub Actions示例

创建 `.github/workflows/test.yml`：

```yaml
name: Test im_switch.nvim

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v3

      - name: Install Neovim
        run: |
          sudo add-apt-repository ppa:neovim-ppa/unstable
          sudo apt-get update
          sudo apt-get install -y neovim

      - name: Install fcitx5
        run: |
          sudo apt-get install -y fcitx5 fcitx5-remote

      - name: Install ldbus
        run: |
          sudo apt-get install -y libdbus-1-dev
          luarocks install ldbus

      - name: Run tests
        run: |
          nvim --headless "+luafile examples/test_automated.lua" \
               "+lua require('test_automated').run_all()" \
               "+:qa"
```

## 开发工作流

### 典型开发流程

```
1. 编辑代码
   ↓
2. 在Neovim中测试
   :luafile examples/test_automated.lua
   :lua require("test_automated").run_all()
   ↓
3. 提交代码
   git add .
   git commit -m "feat: xxx"
   ↓
4. 推送到GitHub
   git push
   ↓
5. GitHub Actions自动运行测试
   ↓
6. 查看测试结果
```

### 本地开发配置

```lua
-- ~/.config/nvim/lua/plugins/im_switch.lua
return {
  {
    -- 开发时使用本地路径
    dir = "~/data/repo/input/im_switch.nvim",

    -- 开发时禁用延迟加载
    lazy = false,

    -- 开发时启用详细日志
    config = function()
      require("im_switch").setup({
        log = "debug",  -- 开发时用debug
        -- ... 其他配置
      })
    end,
  },
}
```

## 快捷键配置

在 `init.lua` 或插件配置中添加：

```lua
-- 在im_switch配置中
vim.keymap.set("n", "<Leader>is", function()
  local state = require("im_switch.state_manager").get_buffer_state(
    vim.api.nvim_get_current_buf(),
    "ins"
  )
  print(vim.inspect(state))
end, { desc = "显示当前Buffer状态" })

vim.keymap.set("n", "<Leader>it", function()
  require("test_automated").run_all()
end, { desc = "运行自动化测试" })

vim.keymap.set("n", "<Leader>iu", function()
  vim.cmd("Lazy update im_switch.nvim")
end, { desc = "更新im_switch.nvim" })
```

## 状态栏集成（可选）

### lualine集成

```lua
require("lualine").setup({
  sections = {
    lualine_a = { "mode" },
    lualine_b = {
      {
        "im_switch",
        icon = "",
      }
    },
    -- ...
  },
})
```

## 故障排查

### Q1: 插件没有自动加载

**检查**：
```vim
:Lazy log
```

**解决**：
```vim
:Lazy sync
```

### Q2: 自动更新不工作

**检查lazy.nvim配置**：
```lua
opts = {
  checker = {
    enabled = true,  -- 确保启用
  },
}
```

### Q3: 测试失败

**运行诊断**：
```vim
:luafile examples/diagnose_buffer_state.lua
:lua require("diagnose_buffer_state").run_all()
```

**查看日志**：
```vim
:messages
```

## 性能优化

### 延迟加载配置

```lua
return {
  {
    dir = "~/data/repo/input/im_switch.nvim",
    event = "VeryLazy",  -- 启动后立即加载
    -- 或者使用特定事件
    -- event = "InsertEnter",  -- 第一次进入插入模式时加载
    -- keys = { "i", "a", "o" },  -- 按下这些键时加载
  },
}
```

### 禁用不用的功能

```lua
require("im_switch").setup({
  define_autocmd = false,  -- 手动定义autocmd
  autostart_fcitx5 = false,  -- 不自动启动fcitx5
})
```

## 总结

使用lazy.nvim管理im_switch.nvim的优势：

1. ✅ **自动管理**: 自动加载、更新、清理
2. ✅ **延迟加载**: 提高启动速度
3. ✅ **版本控制**: 锁定特定版本
4. ✅ **依赖管理**: 自动处理依赖关系
5. ✅ **性能优化**: 并发加载、缓存

完整配置文件：
- `examples/lazy_spec.lua` - 插件规范
- `examples/lazy_config.lua` - 完整配置
- `scripts/auto_update_test.sh` - 自动化脚本

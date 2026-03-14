# im_switch.nvim 配置选项

## 完整配置示例

```lua
require('im_switch').setup({
  -- ==========================================
  -- 模式-输入法映射
  -- ==========================================
  imname = {
    norm = "keyboard-us",  -- 普通模式：英文键盘
    ins = "rime",         -- 插入模式：Rime
    cmd = "keyboard-us",   -- 命令模式：英文键盘
    vis = "keyboard-us",   -- 可视模式：英文键盘
    sel = "keyboard-us",   -- 选择模式：英文键盘
    opr = "keyboard-us",   -- 操作符等待模式：英文键盘
    term = "keyboard-us",  -- 终端模式：英文键盘
  },

  -- ==========================================
  -- 基础配置
  -- ==========================================
  remember_prior = true,        -- 记住上次状态
  define_autocmd = true,         -- 定义自动命令
  autostart_fcitx5 = true,       -- 自动启动fcitx5

  -- ==========================================
  -- Rime状态记忆
  -- ==========================================
  remember_rime_state = true,   -- 启用Rime状态记忆

  -- ==========================================
  -- 后端配置
  -- ==========================================
  backend = "auto",              -- 指定后端："auto"/"ldbus"/"lgi"/"fcitx5_remote"
                                 -- "auto": 自动选择最佳后端（默认）
                                 -- "ldbus": 使用ldbus D-Bus后端（推荐，5-10ms）
                                 -- "lgi": 使用lgi D-Bus后端（8-12ms）
                                 -- "fcitx5_remote": 使用fcitx5-remote CLI（25-40ms）
                                 -- ⚠️ 指定后端后不会自动降级

  -- ==========================================
  -- 缓存配置
  -- ==========================================
  rime_state_cache_ttl = 5000,   -- Rime状态缓存时长（毫秒）

  -- ==========================================
  -- 日志配置
  -- ==========================================
  log = "warn",                   -- 日志级别："debug"/"info"/"warn"/"error"

  -- ==========================================
  -- 其他
  -- ==========================================
  msg = nil,                     -- 启动完成消息
})
```

## 配置选项详解

### `imname` (table)

模式-输入法映射表，定义每种模式使用的输入法。

**支持的模式：**
- `norm`: NORMAL模式
- `ins`: INSERT模式
- `cmd`: COMMAND模式
- `vis`: VISUAL模式
- `sel`: SELECT模式
- `opr`: O-PENDING模式
- `term`: TERMINAL模式
- `lang`: LANGUAGE模式

**示例：**
```lua
imname = {
  norm = "keyboard-us",  -- 普通模式用英文
  ins = "rime",         -- 插入模式用Rime
  cmd = "keyboard-us",   -- 命令模式用英文
}
```

### `remember_prior` (boolean, default: true)

是否记住上次离开某模式时使用的输入法。

- `true`: 记住每个模式的上次输入法
- `false`: 使用配置中的固定输入法

**示例：**
```lua
remember_prior = true,  -- 记住上次状态

-- 行为：
-- 1. 在insert模式使用pinyin
-- 2. Esc到normal模式
-- 3. 再次进入insert模式
-- -> 自动恢复到pinyin ✅
```

### `remember_rime_state` (boolean, default: true)

是否启用Rime中英文状态记忆（Layer 2状态）。

- `true`: 记住每个Buffer的Rime中英文状态
- `false`: 不记忆Rime状态

**示例：**
```lua
remember_rime_state = true,

-- 行为：
-- 1. 在insert模式切换Rime到中文
-- 2. Esc到normal模式（Rime自动切换到英文）
-- 3. 再次进入insert模式
-- -> Rime自动恢复到中文 ✅
```

### `backend` (string, default: "auto")

**指定使用的后端。**

**可用值：**
- `"auto"`: 自动选择最佳后端（推荐）
  - 优先级：ldbus → lgi → fcitx5_remote
  - 如果首选后端不可用，尝试下一个

- `"ldbus"`: 使用ldbus D-Bus后端（最快，推荐）
  - 延迟：5-10ms
  - 需要：`libdbus-1-dev` 和 `luarocks install ldbus`
  - ⚠️ 如果ldbus不可用，插件初始化失败

- `"lgi"`: 使用lgi D-Bus后端
  - 延迟：8-12ms
  - 需要：`libgirepository1.0-dev` 和 `luarocks install lgi`
  - ⚠️ 如果lgi不可用，插件初始化失败

- `"fcitx5_remote"`: 使用fcitx5-remote CLI后端
  - 延迟：25-40ms
  - 需要：fcitx5-remote（通常已预装）
  - ⚠️ 不支持Rime状态记忆

**重要：**
- 指定后端后，**不会自动降级**
- 如果指定的后端不可用，插件初始化会失败
- 建议使用 `"auto"` 让插件自动选择最佳后端

**示例：**
```lua
-- 推荐：自动选择
backend = "auto",

-- 强制使用ldbus（最快）
backend = "ldbus",

-- 强制使用fcitx5-remote（最兼容）
backend = "fcitx5_remote",
```

### `rime_state_cache_ttl` (integer, default: 5000)

Rime状态缓存时长，单位：毫秒。

**作用：**
- 减少D-Bus调用次数
- 提高性能

**建议值：**
- `5000` (5秒): 默认值，平衡性能和准确性
- `10000` (10秒): 更高性能，可能稍有延迟
- `1000` (1秒): 更高准确性，性能稍降

**示例：**
```lua
rime_state_cache_ttl = 5000,  -- 5秒缓存
```

### `define_autocmd` (boolean, default: true)

是否定义自动命令（ModeChanged事件监听）。

- `true`: 自动定义，自动切换输入法
- `false`: 手动定义或使用命令触发

**示例：**
```lua
define_autocmd = true,  -- 自动模式切换
```

### `autostart_fcitx5` (boolean, default: true)

fcitx5未运行时是否自动启动。

- `true`: 自动启动fcitx5
- `false**: 不启动，直接使用

### `log` (string, default: "warn")

日志级别，控制日志输出详细程度。

**可用值：**
- `"debug"`: 最详细，包含所有调试信息
- `"info"`: 包含状态变化、缓存命中等信息
- `"warn"`: 仅警告和错误（默认）
- `"error"`: 仅错误

**示例：**
```lua
log = "info",  -- 启用详细日志，便于调试
```

### `msg` (string|nil, default: nil)

启动完成时显示的消息。

**示例：**
```lua
msg = "im_switch.nvim loaded! 🚀",
```

## 常见配置场景

### 场景1: 最小配置（推荐）

```lua
require('im_switch').setup({
  imname = {
    norm = "keyboard-us",
    ins = "rime",
  },
})
```

### 场景2: 高性能配置

```lua
require('im_switch').setup({
  imname = {
    norm = "keyboard-us",
    ins = "rime",
  },
  backend = "ldbus",           -- 强制使用最快的后端
  rime_state_cache_ttl = 10000, -- 10秒缓存
})
```

### 场景3: 调试配置

```lua
require('im_switch').setup({
  imname = {
    norm = "keyboard-us",
    ins = "rime",
  },
  log = "debug",  -- 最详细的日志
})
```

### 场景4: 兼容性配置

```lua
require('im_switch').setup({
  imname = {
    norm = "keyboard-us",
    ins = "rime",
  },
  backend = "fcitx5_remote",   -- 使用CLI后端，最兼容
  remember_rime_state = false, -- CLI不支持Rime状态
})
```

### 场景5: 多Buffer混合编辑

```lua
require('im_switch').setup({
  imname = {
    norm = "keyboard-us",
    ins = "rime",
  },
  remember_prior = true,         -- 启用prior记忆
  remember_rime_state = true,    -- 启用Rime状态记忆
  backend = "auto",              -- 自动选择最佳后端
  rime_state_cache_ttl = 10000,  -- 10秒缓存
})

-- 行为：
-- Buffer 1 (readme.md): Insert模式 → Rime中文
-- Buffer 2 (main.lua): Insert模式 → Rime英文
-- 每个Buffer独立记忆 ✅
```

## Lazy.nvim配置示例

### 本地开发配置

```lua
-- ~/.config/nvim/lua/plugins/im_switch.lua
return {
  {
    dir = "~/data/repo/input/im_switch.nvim",
    event = "VeryLazy",
    config = function()
      require("im_switch").setup({
        imname = {
          norm = "keyboard-us",
          ins = "rime",
        },
        backend = "ldbus",  -- 指定后端，不fallback
        log = "warn",
      })
    end,
  },
}
```

### 生产环境配置

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
        backend = "auto",  -- 自动选择最佳后端
      })
    end,
  },
}
```

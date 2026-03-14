# im_switch.nvim 行为说明

## 核心设计理念

im_switch.nvim 采用**智能模式感知**的设计，根据不同的编辑模式自动调整输入法状态，提供最佳的用户体验。

## 模式与输入法状态映射

### Normal/Visual/Operator-Pending 模式

**行为**: Rime 自动切换到英文模式 (`ascii_mode = true`)

**原因**:
- Normal 模式下的命令（如 `dd`, `ciw`, `:w`）需要英文字符输入
- 确保命令输入的可靠性
- 避免中文输入法干扰命令执行

**示例**:
```vim
# 在 insert 模式输入中文
你好世界

# 按 Esc 进入 normal 模式
# Rime 自动切换到英文模式

# 输入命令
:write          # 可以正常输入英文命令
dd              # 可以正常执行删除命令
```

### Insert/Replace 模式

**行为**: Rime 恢复该 buffer 上次保存的状态

**特点**:
- 每个 buffer 独立记忆自己的中英文状态
- 切换 buffer 时自动恢复对应的状态
- 适合同时编辑中文文档和英文代码

**示例**:
```lua
-- Buffer 1: 中文文档
你好世界         -- Insert 模式，Rime 中文模式
<Esc>           -- Normal 模式，Rime 英文模式
i               -- Insert 模式，Rime 恢复中文模式 ✅

-- Buffer 2: 英文代码
function foo()   -- Insert 模式，Rime 英文模式
<Esc>           -- Normal 模式，Rime 英文模式
i               -- Insert 模式，Rime 保持英文模式 ✅
```

### Command 模式

**行为**: 类似 Normal 模式，Rime 保持英文模式

**原因**: 命令行命令（如 `:%s/foo/bar/g`）需要英文输入

## Buffer 级别状态隔离

### 状态存储结构

每个 buffer 独立存储以下信息:

```lua
buffer_state = {
  [1] = {                    -- Buffer 1
    ins = {
      im = "rime",
      rime_ascii = false,    -- 中文模式
      last_update = 1234567890,
    }
  },
  [2] = {                    -- Buffer 2
    ins = {
      im = "rime",
      rime_ascii = true,     -- 英文模式
      last_update = 1234567891,
    }
  }
}
```

### 典型使用场景

#### 场景 1: 编辑中文文档

```
Buffer 1 (readme.md):
1. 打开文件 → Insert 模式 → Rime 中文模式
2. 输入中文内容...
3. 按 Esc → Normal 模式 → Rime 英文模式
4. 执行命令 :w → 正常工作
5. 按 i → Insert 模式 → Rime 恢复中文模式 ✅
```

#### 场景 2: 同时编辑中英文文件

```
Buffer 1 (readme.md) - 中文文档:
- Insert 模式: Rime 中文模式
- Normal 模式: Rime 英文模式

Buffer 2 (main.lua) - 英文代码:
- Insert 模式: Rime 英文模式
- Normal 模式: Rime 英文模式

切换过程:
1. Buffer 1 输入中文 → Esc → 切换到 Buffer 2
2. Buffer 2 按 i → Rime 英文模式 ✅
3. Buffer 2 按 Esc → 切换回 Buffer 1
4. Buffer 1 按 i → Rime 中文模式 ✅
```

## 状态切换时机

### 保存状态时机

当从 Insert/Command 模式离开时:
1. 获取当前 IM 和 Rime 状态
2. 保存到全局缓存
3. **保存到当前 buffer 的状态记录**
4. 保存到 prior memory

### 恢复状态时机

当进入 Insert/Command 模式时:
1. **优先从当前 buffer 状态恢复**
2. 如果 buffer 状态不存在，使用 prior memory
3. 如果 prior memory 不存在，使用默认配置

### Normal/Visual 模式特殊处理

当进入 Normal/Visual/Operator-Pending 模式时:
1. IM 切换到配置的输入法（通常是 keyboard-us）
2. **如果 IM 是 rime，强制切换到英文模式** (`ascii_mode = true`)
3. 不保存这个状态（因为这是临时的命令状态）

## 性能优化

### 三层缓存

1. **全局缓存** (1秒): 快速连续模式切换
2. **Buffer 缓存** (10秒): Buffer 间切换
3. **D-Bus 缓存** (5秒): Rime 状态查询

### 智能判断

- 如果当前 IM 已经是目标 IM，跳过 IM 切换
- 如果当前 Rime 状态已经是目标状态，跳过状态切换
- 优先使用缓存，减少 D-Bus 调用

## 配置建议

### 中文写作为主

```lua
require('im_switch').setup({
  imname = {
    norm = 'keyboard-us',
    ins = 'rime',
  },
  remember_rime_state = true,
})
```

**行为**: Insert 模式默认中文，Normal 模式英文

### 中英文混合工作

```lua
require('im_switch').setup({
  imname = {
    norm = 'keyboard-us',
    ins = 'rime',
  },
  remember_rime_state = true,
  rime_state_cache_ttl = 10000,  -- 10秒缓存
})
```

**行为**: 每个 buffer 记住自己的状态

### 仅使用英文输入法

```lua
require('im_switch').setup({
  imname = {
    norm = 'keyboard-us',
    ins = 'keyboard-us',
  },
  remember_rime_state = false,  -- 禁用 Rime 状态记忆
})
```

**行为**: 不使用 Rime，简单的 IM 切换

## 常见问题

### Q: 为什么 Normal 模式要强制英文？

**A**: Normal 模式的命令（如 `dd`, `:w`）需要英文输入。如果保持中文模式，可能导致:
- 命令输入错误
- 标点符号变成中文标点
- 命令无法执行

### Q: 可以关闭 Normal 模式的强制英文吗？

**A**: 目前这个行为是内置的，不适合关闭。如果你不需要这个功能，建议:
- 设置 `remember_rime_state = false`
- 或者不使用 Rime 作为 normal 模式的输入法

### Q: Buffer 状态会一直保存吗？

**A**: Buffer 状态在以下情况会保留:
- Buffer 在内存中（未关闭）
- 10秒缓存有效期内
- 手动调用保存函数

Buffer 关闭后状态会被清除，下次打开会使用默认配置。

### Q: 如何查看当前 buffer 的状态？

**A**: 使用以下命令:
```vim
:lua print(vim.inspect(require("im_switch.state_manager").get_buffer_state(vim.api.nvim_get_current_buf(), "ins")))
```

### Q: 如何手动设置 buffer 的状态？

**A**: 使用以下函数:
```lua
:lua require("im_switch.state_manager").save_buffer_state(1, "ins", "rime", false)
```

这会设置 Buffer 1 的 Insert 模式为 Rime 中文模式。

## 技术细节

### 状态优先级

Insert 模式状态恢复的优先级:
1. Buffer 状态缓存（10秒有效）
2. Prior memory
3. 全局状态缓存（1秒有效）
4. 默认配置

### 性能指标

- 状态恢复（缓存命中）: 0-2ms
- 状态恢复（缓存未命中）: 10-20ms (D-Bus)
- D-Bus 调用减少: 60-80%

## 总结

im_switch.nvim 的核心设计是**智能模式感知** + **per-buffer 状态记忆**:

1. **Normal/Visual 模式**: 英文模式，确保命令可靠
2. **Insert 模式**: 恢复 buffer 的上次状态
3. **Per-buffer**: 每个 buffer 独立记忆
4. **高性能**: 三层缓存，减少 D-Bus 调用

这种设计让中英文混合编辑变得无缝且高效！

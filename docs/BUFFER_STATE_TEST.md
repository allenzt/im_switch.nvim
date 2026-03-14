# Per-Buffer状态记忆测试指南

## 修复说明

已修复Per-Buffer状态记忆的问题：
- **移除了current_im == "rime"的限制** - 现在可以保存任何IM的状态
- **移除了缓存时间的限制** - 即使缓存过期也会使用保存的buffer状态
- **增强了日志输出** - 更详细的状态信息，便于调试

## 快速测试

### 步骤1: 运行诊断脚本

在Neovim中运行：

```vim
:luafile /path/to/im_switch.nvim/examples/diagnose_buffer_state.lua
:lua require("diagnose_buffer_state").run_all()
```

这会检查：
- 插件是否正确加载
- 配置是否正确
- 后端是否初始化
- 状态管理器是否工作
- 手动保存和恢复测试

### 步骤2: 启用详细日志

在你的init.lua中临时添加：

```lua
require('im_switch').setup({
  log = "info",  -- 启用详细日志
  -- ... 其他配置
})
```

或者运行时设置：

```vim
:lua require('im_switch.config').log = "info"
```

### 步骤3: 测试单Buffer状态记忆

```
1. 打开一个文件（如 test1.txt）
2. 按 i 进入插入模式
3. 手动切换Rime到中文（按Shift或Ctrl+`）
4. 输入一些中文
5. 按 Esc 返回普通模式
   -> 应该看到日志：Rime切换到英文
6. 按 i 再次进入插入模式
   -> 应该看到日志：Rime恢复到中文
7. 确认Rime确实是中文状态
```

### 步骤4: 测试多Buffer状态记忆

```
1. 打开文件A（如 readme.md，中文文档）
2. 按 i 进入插入模式
3. 切换Rime到中文
4. 按 Esc

5. 打开文件B（如 main.lua，英文代码）
6. 按 i 进入插入模式
   -> Rime应该保持英文（或恢复到上次状态）
7. 按 Esc

8. 切换回文件A（:buffer readme.md 或 :b#）
9. 按 i 进入插入模式
   -> Rime应该恢复到中文（文件A的状态）✅
```

## 检查命令

### 查看当前Buffer状态

```vim
:lua print(vim.inspect(require("im_switch.state_manager").get_buffer_state(vim.api.nvim_get_current_buf(), "ins")))
```

输出示例：
```lua
{
  im = "rime",
  rime_ascii = false,  -- false=中文, true=英文
  last_update = 1710445200000
}
```

### 查看所有Buffer状态

```vim
:lua print(vim.inspect(require("im_switch.state_manager").buffer_state))
```

### 查看全局状态

```vim
:lua print(vim.inspect(require("im_switch.state_manager").get_global_state()))
```

### 手动保存状态（测试用）

```vim
:lua require("im_switch.state_manager").save_buffer_state(1, "ins", "rime", false)
```

这会保存Buffer 1的insert模式为Rime中文状态。

### 手动清除状态（重置测试）

```vim
:lua require("im_switch.state_manager").cleanup_buffer(vim.api.nvim_get_current_buf())
```

## 预期行为

### Normal/Visual模式

- **输入法**: 切换到配置的IM（如keyboard-us）
- **Rime状态**: 强制切换到英文（ascii_mode = true）
- **原因**: 确保命令输入可靠

**日志示例**：
```
Mode changed: ins -> norm
Switched to IM: keyboard-us
Normal/Visual mode: Force Rime to English (ascii_mode=true)
```

### Insert模式

- **输入法**: 切换到配置的IM（如rime）
- **Rime状态**: 恢复该buffer的上次状态
- **原因**: 每个buffer独立记忆

**日志示例（Buffer 1 - 中文文档）**：
```
Mode changed: norm -> ins
Buffer 1: Restoring ins mode Rime state: ascii_mode=false (中文)
Set Rime state: ascii_mode=false (中文)
```

**日志示例（Buffer 2 - 英文代码）**：
```
Mode changed: norm -> ins
Buffer 2: Restoring ins mode Rime state: ascii_mode=true (英文)
Set Rime state: ascii_mode=true (英文)
```

## 常见问题

### Q1: 为什么没有恢复Buffer状态？

**检查项**：
1. 是否启用了 `remember_rime_state = true`？
2. 是否之前保存过状态？
3. 使用D-Bus后端（ldbus/lgi）还是fcitx5-remote？
   - fcitx5-remote不支持Rime状态记忆

**解决方案**：
```lua
require('im_switch').setup({
  remember_rime_state = true,
  rime_state_method = 'auto',  -- 使用D-Bus
})
```

### Q2: 日志显示"Buffer X: No state saved"

**原因**: 该buffer还没有保存过状态

**解决**: 正常现象，首次使用该buffer时会有此日志。使用一次后会自动保存。

### Q3: 不同Buffer的状态混淆了

**检查项**:
1. 查看buffer状态：`get_buffer_state()`
2. 确认buffer号是否正确

**可能原因**: buffer被关闭后重新打开，状态被清除了

### Q4: 状态保存了但不恢复

**检查日志**:
1. 是否看到 "Saved buffer state" 日志？
2. 是否看到 "Restoring Rime state" 日志？
3. `target_rime_ascii` 是否为nil？

**调试步骤**:
```vim
" 启用最详细日志
:lua require('im_switch.config').log = "debug"

" 测试并查看日志
:messages
```

### Q5: Neovim 0.11.6兼容性问题

**检查版本**:
```vim
:version
```

**已知问题**: Neovim 0.11.6应该完全兼容，如果没有自动加载，手动触发：

```vim
:ImSwitchGeneious
```

## 完整测试流程

```vim
" 1. 加载诊断脚本
:luafile /path/to/im_switch.nvim/examples/diagnose_buffer_state.lua

" 2. 运行自动测试
:lua require("diagnose_buffer_state").run_all()

" 3. 启用详细日志
:lua require('im_switch.config').log = "info"

" 4. 清除所有状态（重新开始）
" (手动关闭所有buffer重新打开)

" 5. 测试Buffer 1
:e test1.txt
i        " 进入插入模式
" 切换Rime到中文
你好
<Esc>    " 返回普通模式

" 6. 测试Buffer 2
:e test2.txt
i        " 进入插入模式
" Rime应该保持英文或恢复状态
hello
<Esc>

" 7. 切换回Buffer 1
:b#
i        " 进入插入模式
" Rime应该恢复到中文

" 8. 查看当前状态
:lua require("diagnose_buffer_state").show_current_buffer_state()

" 9. 查看日志
:messages
```

## 预期日志输出

### 保存状态时

```
Mode changed: ins -> norm
Using cached global state: im=rime, rime_ascii=false
Buffer 1: Saved ins mode state: im=rime, rime_ascii=中文
Switched to IM: keyboard-us
Normal/Visual mode: Force Rime to English (ascii_mode=true)
Set Rime state: ascii_mode=true (英文)
```

### 恢复状态时

```
Mode changed: norm -> ins
Switched to IM: rime
Buffer 1: Restoring ins mode Rime state: ascii_mode=false (中文)
Set Rime state: ascii_mode=false (中文)
```

## 配置建议

### 最小配置（推荐）

```lua
require('im_switch').setup({
  imname = {
    norm = 'keyboard-us',
    ins = 'rime',
  },
  remember_rime_state = true,  -- 必须启用
  rime_state_method = 'auto',   -- 自动检测D-Bus
})
```

### 调试配置

```lua
require('im_switch').setup({
  imname = {
    norm = 'keyboard-us',
    ins = 'rime',
  },
  remember_rime_state = true,
  rime_state_method = 'auto',
  log = 'info',  -- 启用详细日志
})
```

## 技术细节

### 状态保存时机

- 离开insert/command模式时
- 条件：`remember_rime_state = true`
- 保存到：`buffer_state[bufnr][mode]`

### 状态恢复时机

- 进入insert/command模式时
- 优先级：Buffer状态 → Prior memory → 全局状态 → 默认值

### 缓存策略

- **全局缓存**: 1秒，用于快速连续切换
- **Buffer缓存**: 10秒，但即使过期也会使用（本次修复）
- **D-Bus缓存**: 5秒TTL，由后端管理

## 需要帮助？

如果按照以上步骤仍然无法工作，请收集以下信息：

1. Neovim版本：`:version`
2. 插件配置：`:lua print(vim.inspect(require('im_switch.config')))`
3. 后端信息：`:lua print(vim.inspect(require('im_switch.backend').get_backend()))`
4. 日志输出：`:messages`
5. 复现步骤

然后提交issue到：https://github.com/allenzt/im_switch.nvim/issues

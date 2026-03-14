# Per-Buffer 状态保存修复总结

## 修复日期
2026-03-14

## 问题描述

原有的 per-buffer 状态保存实现存在以下问题：

1. **不必要的 global_state 缓存**：Normal 模式总是在英文状态，不需要复杂的全局缓存机制
2. **状态保存逻辑过于复杂**：为所有模式保存状态，但实际上 Normal/Command 模式状态是固定的
3. **性能问题**：维护 global_state 缓存增加了不必要的复杂度和性能开销

## 核心原理

### Normal/Command 模式的特性
- **Normal 模式**：总是在英文状态（rime_ascii = true）
- **Command 模式**：总是在英文状态（rime_ascii = true）
- **Insert 模式**：需要记忆和恢复中英文状态

### 简化后的设计
```
状态管理层次：
┌─────────────────────────────────────┐
│  配置层 (config.imname)             │
│  - norm → rime (固定)               │
│  - cmd  → rime (固定)               │
│  - ins  → rime (可配置)             │
└─────────────────────────────────────┘
           ↓
┌─────────────────────────────────────┐
│  Buffer状态层 (buffer_state)        │
│  - 只保存 Insert 模式的状态         │
│  - Normal/Command 不需要保存        │
└─────────────────────────────────────┘
           ↓
┌─────────────────────────────────────┐
│  D-Bus后端缓存 (backend/dbus/rime)  │
│  - 5秒 TTL                          │
│  - 减少实际的 D-Bus 调用            │
└─────────────────────────────────────┘
```

## 修改内容

### 1. lua/im_switch/state_manager.lua

#### 移除的代码
- `global_state` 表及其所有相关字段
- `get_global_state()` 函数
- `update_global_state()` 函数
- `is_global_state_valid()` 函数
- `get_prior_rime_state()` 函数（逻辑移到 autocmds.lua）

#### 简化后的代码
```lua
local M = {
  -- Buffer-level state storage (Insert mode only, Normal/Command are always English)
  -- buffer_state[bufnr] = {
  --   ins = { im = "rime", rime_ascii = false, last_update = 1234567890 },
  -- }
  -- Note: Normal and Command modes are always in English state for Rime, no need to save
  buffer_state = {},
}
```

#### get_prior_im() 简化
```lua
-- 之前：3层查找（buffer_state → global_state → config）
-- 现在：2层查找（buffer_state → config）
M.get_prior_im = function(mode)
  local bufnr = vim.api.nvim_get_current_buf()
  local buffer_state = M.buffer_state[bufnr]

  -- Priority 1: Try to get from buffer state
  if buffer_state and buffer_state[mode] and buffer_state[mode].im then
    return buffer_state[mode].im
  end

  -- Priority 2: Fall back to config
  return config.imname[mode]
end
```

### 2. lua/im_switch/autocmds.lua

#### Phase 1: 只保存 Insert 模式状态
```lua
-- 之前：保存所有模式的状态
if old_mode then  -- Save state for ALL modes (norm, ins, cmd)
  current_im = backend.get_current_im()
  state_manager.save_buffer_state(bufnr, old_mode, current_im, current_rime_ascii)
  state_manager.update_global_state(current_im, current_rime_ascii, bufnr, old_mode)
end

-- 现在：只保存 Insert 模式状态
if old_mode == "ins" then  -- Only save Insert mode state
  current_im = backend.get_current_im()
  state_manager.save_buffer_state(bufnr, old_mode, current_im, current_rime_ascii)
elseif old_mode and (old_mode == "norm" or old_mode == "cmd") then
  -- Normal/Command modes are always in English state for Rime
  -- No need to save their state
  current_im = backend.get_current_im()
  lib.info(string.format("%s mode: Always English for Rime, skipping state save", old_mode))
end
```

#### Phase 3: 简化状态恢复逻辑
```lua
-- 之前：使用 get_prior_rime_state() 函数
local target_rime_ascii = state_manager.get_prior_rime_state(new_mode)

-- 现在：直接内联逻辑
if target_im == "rime" and config.enable_rime_memory then
  local target_rime_ascii = nil

  -- Normal/Command modes: Always force English
  if new_mode == "norm" or new_mode == "cmd" then
    target_rime_ascii = true
  elseif new_mode == "ins" then
    -- Insert mode: Restore from buffer state
    local buffer_state = state_manager.get_buffer_state(bufnr, "ins")
    if buffer_state and buffer_state.rime_ascii ~= nil then
      target_rime_ascii = buffer_state.rime_ascii
    end
  end

  -- Set Rime state if we have a target
  if target_rime_ascii ~= nil then
    backend.set_rime_ascii_mode(target_rime_ascii)
  end
end
```

#### 移除的代码
- Phase 1 中的 `state_manager.update_global_state()` 调用
- Phase 3 末尾的 `state_manager.update_global_state()` 调用
- 不再需要读取最终状态来更新 global_state

### 3. examples/test_per_buffer_fix.lua

#### 更新的测试用例
- 移除 `test_global_state_cache` 测试
- 移除 `test_prior_rime_state` 测试
- 移除 `test_prior_im_with_cache` 测试
- 新增 `test_insert_mode_saving` 测试
- 新增 `test_buffer_cleanup` 测试

#### 测试结果
```
=== Per-Buffer State Memory Fix Tests ===
Test 1: Insert mode state saving
  ✅ PASS: Insert mode state saved correctly
  ✅ PASS: Normal mode state NOT saved (always English)

Test 2: Multi-buffer state isolation
  ✅ PASS: Multi-buffer state isolation works

Test 3: get_prior_im
  ✅ PASS: Uses config when buffer state is empty
  ✅ PASS: Uses buffer state when available

Test 4: Verify global_state is removed
  ✅ PASS: global_state removed (Normal always English)
```

## 修复效果

### 代码简化
- **state_manager.lua**: 减少 87 行代码（~40%）
- **autocmds.lua**: 简化 55 行代码（~20%）
- **总代码减少**: ~140 行

### 性能提升
- **减少状态检查**：不再需要维护 global_state 缓存的有效性
- **简化查找路径**：从 3 层查找简化为 2 层
- **减少内存占用**：不再需要存储 global_state 表

### 逻辑清晰度
- **明确的模式语义**：Normal/Command 总是英文，Insert 记忆状态
- **简化的状态管理**：只需要管理 Insert 模式的状态
- **更易维护**：减少了复杂的缓存逻辑

## 使用场景验证

### 场景 1：Normal → Insert → Normal
```
用户操作：
1. Normal 模式（自动英文）✅
2. 按 i 进入 Insert 模式（恢复上次状态）✅
3. 手动切换到中文
4. 按 Esc 返回 Normal 模式（自动英文）✅
5. 按 i 进入 Insert 模式（恢复到中文）✅
```

### 场景 2：多 Buffer 状态隔离
```
Buffer 1 (README.md):
- Insert 模式 → 中文状态
- 保存到 buffer_state[1]["ins"] = {im="rime", rime_ascii=false} ✅

Buffer 2 (main.lua):
- Insert 模式 → 英文状态
- 保存到 buffer_state[2]["ins"] = {im="rime", rime_ascii=true} ✅

切换回 Buffer 1:
- Insert 模式 → 恢复到中文状态 ✅
```

### 场景 3：Normal 模式不保存状态
```
Normal 模式切换：
1. Insert → Normal（中文 → 英文）
2. 不保存 Normal 状态（因为总是英文）✅
3. Normal → Insert（英文 → 中文，从 buffer_state 恢复）✅
```

## 向后兼容性

### 配置兼容
- ✅ 所有现有配置项保持不变
- ✅ `enable_rime_memory` 配置继续有效
- ✅ `imname` 配置继续有效

### API 兼容性
- ⚠️ 移除了 `get_global_state()` 函数
- ⚠️ 移除了 `update_global_state()` 函数
- ⚠️ 移除了 `is_global_state_valid()` 函数
- ⚠️ 移除了 `get_prior_rime_state()` 函数
- ✅ 所有其他 API 保持不变

### 行为变化
- **更简洁**：移除了不必要的缓存层
- **更可靠**：Normal/Command 模式强制英文，不依赖缓存
- **更高效**：减少了状态管理的复杂度

## 总结

这次修复的核心思想是：**利用 Normal/Command 模式总是在英文状态这一事实，简化状态管理逻辑**。

通过移除 global_state 缓存层，我们：
1. 简化了代码实现（减少 ~140 行）
2. 提升了性能（减少缓存检查）
3. 提高了可维护性（逻辑更清晰）
4. 保持了功能完整性（per-buffer 状态记忆依然正常工作）

这是一个典型的"做减法"优化：通过理解业务本质（Normal 总是英文），移除不必要的复杂性。

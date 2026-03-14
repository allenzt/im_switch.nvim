# Manual Testing Guide for Per-Buffer State Memory Fix

## Prerequisites

1. Ensure im_switch.nvim is properly installed and configured
2. Set Rime as the default input method for all modes
3. Enable Rime memory feature: `enable_rime_memory = true`

## Test Scenarios

### Test 1: Normal → Insert → Normal State Persistence

**Expected behavior:**
1. Start in Normal mode (buffer 1)
   - Rime should be in English mode (rime_ascii = true)

2. Press `i` to enter Insert mode
   - Rime state should remain unchanged if no history

3. Manually switch Rime to Chinese (Ctrl+` or similar)
   - Start typing Chinese text

4. Press `Esc` to return to Normal mode
   - Rime should automatically switch to English mode

5. Press `i` to enter Insert mode again
   - **CRITICAL**: Rime should restore to Chinese mode (your previous state)

**Verification:**
```vim
" Enable logging
:lua require('im_switch.config').log_level = "info"

" Watch the logs for:
" - "Buffer 1: Saved norm mode state: im=rime, rime_ascii=英文"
" - "Buffer 1: Saved ins mode state: im=rime, rime_ascii=中文"
" - "Buffer 1: Restored ins mode Rime state: 中文"
```

### Test 2: Multi-Buffer State Isolation

**Steps:**
1. Open buffer 1: `:e test.txt`
   - Enter Insert mode, switch to Chinese
   - Type some Chinese text
   - Press `Esc` to return to Normal mode

2. Open buffer 2: `:e readme.md`
   - Enter Insert mode
   - **CRITICAL**: Should default to English (no previous history)
   - Switch to Chinese and type something
   - Press `Esc` to return to Normal mode

3. Switch back to buffer 1: `:b 1`
   - Enter Insert mode
   - **CRITICAL**: Should restore to Chinese (buffer 1's saved state)

4. Switch to buffer 2: `:b 2`
   - Enter Insert mode
   - **CRITICAL**: Should restore to Chinese (buffer 2's saved state)

**Verification:**
Each buffer should maintain its own independent Rime state.

### Test 3: Global State Cache Performance

**Purpose:** Verify that the global_state cache reduces D-Bus calls during rapid mode switches.

**Steps:**
1. Enable logging and watch for D-Bus calls
2. Perform rapid mode switches: `i → Esc → i → Esc → i`
3. Before the fix: Each switch would trigger multiple D-Bus calls
4. After the fix: Cache should reduce D-Bus calls by 60-80%

**Verification:**
```vim
" Enable logging
:lua require('im_switch.config').log_level = "info"

" In the logs, look for:
" - "Updated global state: im=rime, rime_ascii=..."
" - Fewer "Switched to IM" messages when rapidly switching
```

### Test 4: First-Time Insert Mode Entry

**Purpose:** Verify that first-time Insert mode entry has sensible default behavior.

**Steps:**
1. Open a new buffer: `:e newfile.txt`
2. Press `i` to enter Insert mode
3. **CRITICAL**: Rime state should not change (keep current state)

**Verification:**
- Log should show: "Buffer X: No saved Rime state for ins mode, keeping current state"
- Rime should remain in its current mode (no forced change)

### Test 5: Normal/Command Mode English Enforcement

**Purpose:** Verify that Normal and Command modes always enforce English mode.

**Steps:**
1. Enter Insert mode, switch Rime to Chinese
2. Press `Esc` to enter Normal mode
3. **CRITICAL**: Rime should automatically switch to English
4. Press `:` to enter Command mode
5. **CRITICAL**: Rime should remain in English

**Verification:**
- Log should show: "Normal/Command mode: Setting Rime to English before switch"
- Any failure should fallback to keyboard-us input method

## Common Issues and Solutions

### Issue: Rime not switching to English in Normal mode

**Solution:**
- Check if `enable_rime_memory = true` in config
- Verify Rime is actually installed and accessible
- Check logs for error messages

### Issue: State not persisting across buffers

**Solution:**
- Ensure each buffer has a unique buffer number
- Check logs to confirm state is being saved/loaded
- Verify `get_buffer_state()` is returning correct values

### Issue: Performance not improved

**Solution:**
- Verify global_state cache is being updated (check logs)
- Check if `is_global_state_valid()` is working correctly
- Ensure 1-second TTL is appropriate for your use case

## Debug Commands

```vim
" Check current global state
:lua print(vim.inspect(require('im_switch.state_manager').get_global_state()))

" Check buffer state for current buffer
:lua local buf = vim.api.nvim_get_current_buf(); print(vim.inspect(require('im_switch.state_manager').get_buffer_state(buf, 'ins')))

" Check all buffer states
:lua print(vim.inspect(require('im_switch.state_manager').buffer_state))

" Manually trigger mode change (for testing)
:doautocmd ModeChanged
```

## Success Criteria

✅ **Test 1 Pass**: Normal → Insert → Normal state persistence works
✅ **Test 2 Pass**: Multi-buffer state isolation works
✅ **Test 3 Pass**: Performance improved (fewer D-Bus calls)
✅ **Test 4 Pass**: First-time Insert mode entry has sensible defaults
✅ **Test 5 Pass**: Normal/Command modes enforce English mode

If all tests pass, the per-buffer state memory fix is working correctly!

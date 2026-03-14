-- ==========================================
-- 自动测试脚本
-- 用于测试im_switch.nvim插件功能
-- ==========================================

local M = {}

-- 颜色输出
local colors = {
  reset = "\27[0m",
  red = "\27[31m",
  green = "\27[32m",
  yellow = "\27[33m",
  blue = "\27[34m",
  cyan = "\27[36m",
}

local function print_colored(color, text)
  print(color .. text .. colors.reset)
end

local function print_success(text)
  print_colored(colors.green, "✓ " .. text)
end

local function print_error(text)
  print_colored(colors.red, "✗ " .. text)
end

local function print_warning(text)
  print_colored(colors.yellow, "⚠ " .. text)
end

local function print_info(text)
  print_colored(colors.cyan, "ℹ " .. text)
end

local function print_header(text)
  print("\n" .. string.rep("=", 60))
  print_colored(colors.blue, text)
  print(string.rep("=", 60))
end

---测试1: 检查Neovim环境
M.test_neovim_env = function()
  print_header("测试1: Neovim环境检查")

  local version = vim.version()
  print_info(string.format("Neovim版本: %d.%d.%d", version.major, version.minor, version.patch))

  if version.major >= 0 and version.minor >= 8 then
    print_success("Neovim版本满足要求 (>= 0.8)")
    return true
  else
    print_error("Neovim版本过低，需要 >= 0.8")
    return false
  end
end

---测试2: 检查fcitx5环境
M.test_fcitx5_env = function()
  print_header("测试2: fcitx5环境检查")

  -- 检查fcitx5进程
  local has_fcitx5 = vim.fn.system("pgrep -a fcitx5") ~= ""
  if has_fcitx5 then
    print_success("fcitx5进程正在运行")
  else
    print_warning("fcitx5进程未运行")
  end

  -- 检查fcitx5-remote
  if vim.fn.executable("fcitx5-remote") == 1 then
    print_success("fcitx5-remote 可用")
  else
    print_error("fcitx5-remote 不可用")
    return false
  end

  -- 检查显示服务器
  local display = os.getenv("DISPLAY") or os.getenv("WAYLAND_DISPLAY")
  if display then
    print_success("显示服务器: " .. display)
  else
    print_warning("未检测到显示服务器")
  end

  return true
end

---测试3: 检查lazy.nvim
M.test_lazy_nvim = function()
  print_header("测试3: lazy.nvim检查")

  local ok, lazy = pcall(require, "lazy")
  if ok then
    print_success("lazy.nvim 已加载")

    -- 检查插件列表
    local plugins = lazy.plugins()
    print_info("已安装插件数量: " .. #plugins)

    -- 查找im_switch.nvim
    local im_switch_found = false
    for _, plugin in pairs(plugins) do
      if plugin.name == "im_switch.nvim" or plugin.dir:match("im_switch") then
        im_switch_found = true
        print_success("im_switch.nvim 已在插件列表中")
        print_info("  路径: " .. plugin.dir)
        print_info("  状态: " .. (plugin.loaded and "已加载" or "未加载"))
        break
      end
    end

    if not im_switch_found then
      print_warning("im_switch.nvim 不在插件列表中")
      return false
    end

    return true
  else
    print_error("lazy.nvim 未加载")
    return false
  end
end

---测试4: 检查插件加载
M.test_plugin_loaded = function()
  print_header("测试4: 插件加载检查")

  local ok, plugin = pcall(require, "im_switch")
  if ok then
    print_success("im_switch插件已加载")

    -- 检查配置
    local config_ok, config = pcall(require, "im_switch.config")
    if config_ok then
      print_info("配置已加载:")
      print(string.format("  remember_prior: %s", tostring(config.remember_prior)))
      print(string.format("  remember_rime_state: %s", tostring(config.remember_rime_state)))
      print(string.format("  rime_state_method: %s", tostring(config.rime_state_method)))
    end

    return true
  else
    print_error("im_switch插件未加载")
    return false
  end
end

---测试5: 检查后端
M.test_backend = function()
  print_header("测试5: 后端检查")

  local backend_ok, backend = pcall(require, "im_switch.backend")
  if not backend_ok then
    print_error("无法加载后端")
    return false
  end

  print_success("后端已加载")

  -- 检查后端初始化
  local current_backend = backend.get_backend()
  if current_backend then
    print_success(string.format("后端已初始化: %s", current_backend.name or "unknown"))

    -- 测试获取当前IM
    local current_im = backend.get_current_im()
    if current_im then
      print_success(string.format("当前输入法: %s", current_im))
    else
      print_warning("无法获取当前输入法")
    end

    -- 测试Rime功能
    if current_backend.get_rime_ascii_mode then
      local ascii = current_backend.get_rime_ascii_mode()
      print_info(string.format("Rime状态: ascii_mode=%s", tostring(ascii)))
    else
      print_info("Rime状态检测不支持（fcitx5-remote模式）")
    end

    return true
  else
    print_warning("后端未初始化，尝试初始化...")
    local init_ok = backend.init()
    if init_ok then
      print_success("后端初始化成功")
      return true
    else
      print_error("后端初始化失败")
      return false
    end
  end
end

---测试6: 测试状态管理
M.test_state_manager = function()
  print_header("测试6: 状态管理器检查")

  local ok, state_manager = pcall(require, "im_switch.state_manager")
  if not ok then
    print_error("无法加载状态管理器")
    return false
  end

  print_success("状态管理器已加载")

  -- 测试保存和恢复
  local bufnr = vim.api.nvim_get_current_buf()
  print_info(string.format("当前Buffer号: %d", bufnr))

  -- 手动保存测试状态
  state_manager.save_buffer_state(bufnr, "ins", "rime", false)
  print_success("手动保存测试状态")

  -- 尝试读取
  local state = state_manager.get_buffer_state(bufnr, "ins")
  if state and state.im == "rime" and state.rime_ascii == false then
    print_success("状态读取成功: im=rime, ascii_mode=false")
    return true
  else
    print_error("状态读取失败")
    return false
  end
end

---测试7: 测试模式切换
M.test_mode_switch = function()
  print_header("测试7: 模式切换测试")

  local backend_ok, backend = pcall(require, "im_switch.backend")
  if not backend_ok then
    print_error("后端未加载")
    return false
  end

  print_info("手动切换测试:")

  -- 测试切换到rime
  print_info("  尝试切换到 rime...")
  local result = backend.switch_to_im("rime")
  if result then
    print_success("  切换到 rime 成功")
  else
    print_warning("  切换到 rime 失败（可能rime不可用）")
  end

  -- 测试切换到keyboard-us
  print_info("  尝试切换到 keyboard-us...")
  result = backend.switch_to_im("keyboard-us")
  if result then
    print_success("  切换到 keyboard-us 成功")
  else
    print_error("  切换到 keyboard-us 失败")
    return false
  end

  return true
end

---运行所有测试
M.run_all = function()
  print("\n")
  print("╔═══════════════════════════════════════════════════════════╗")
  print_colored(colors.cyan, "║     im_switch.nvim 自动测试套件                            ║")
  print("╚═══════════════════════════════════════════════════════════╝")

  local results = {
    neovim_env = M.test_neovim_env(),
    fcitx5_env = M.test_fcitx5_env(),
    lazy_nvim = M.test_lazy_nvim(),
    plugin_loaded = M.test_plugin_loaded(),
    backend = M.test_backend(),
    state_manager = M.test_state_manager(),
    mode_switch = M.test_mode_switch(),
  }

  -- 打印总结
  print_header("测试总结")

  local total = 0
  local passed = 0
  local failed = 0

  for test_name, result in pairs(results) do
    total = total + 1
    if result then
      passed = passed + 1
      print_success(test_name)
    else
      failed = failed + 1
      print_error(test_name)
    end
  end

  print(string.rep("-", 60))
  print(string.format("总计: %d | 通过: %d | 失败: %d", total, passed, failed))
  print(string.rep("=", 60))

  -- 返回测试结果
  return failed == 0
end

---运行快速测试（跳过环境检查）
M.run_quick = function()
  print("\n快速测试模式（跳过环境检查）\n")

  return M.run_all()
end

return M

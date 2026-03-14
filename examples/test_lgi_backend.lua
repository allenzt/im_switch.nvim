-- ==========================================
-- LGI 后端测试脚本
-- ==========================================

local M = {}

local colors = {
  reset = "\27[0m",
  green = "\27[32m",
  red = "\27[31m",
  yellow = "\27[33m",
  blue = "\27[34m",
  cyan = "\27[36m",
}

local function print_colored(color, text)
  print(color .. text .. colors.reset)
end

-- 测试 lgi 后端
M.test_lgi_backend = function()
  print_colored(colors.blue, "==========================================")
  print_colored(colors.blue, "LGI 后端测试")
  print_colored(colors.blue, "==========================================")
  print("")

  -- 1. 测试 lgi 加载
  print_colored(colors.cyan, "步骤 1: 测试 lgi 加载...")
  local ok, lgi = pcall(require, "lgi")
  if not ok then
    print_colored(colors.red, "✗ lgi 未安装")
    print_colored(colors.yellow, "请运行: luarocks install --local lgi")
    return false
  end
  print_colored(colors.green, "✓ lgi 已加载")

  -- 2. 测试 D-Bus 连接
  print_colored(colors.cyan, "步骤 2: 测试 D-Bus 连接...")
  local Gio = lgi.require("Gio")
  local bus_ok, bus = pcall(function()
    return Gio.bus_get_sync(Gio.BusType.SESSION)
  end)

  if not bus_ok then
    print_colored(colors.red, "✗ D-Bus 连接失败: " .. tostring(bus))
    return false
  end
  print_colored(colors.green, "✓ D-Bus 连接成功")

  -- 3. 测试 fcitx5 proxy
  print_colored(colors.cyan, "步骤 3: 测试 fcitx5 controller proxy...")
  local fcitx_ok, fcitx_proxy = pcall(function()
    return Gio.DBusProxy.new_sync(
      bus,
      Gio.DBusProxyFlags.NONE,
      nil,
      "org.fcitx.Fcitx5",
      "/controller",
      "org.fcitx.Fcitx.Controller1",
      nil
    )
  end)

  if not fcitx_ok then
    print_colored(colors.red, "✗ fcitx5 proxy 创建失败: " .. tostring(fcitx_proxy))
    return false
  end
  print_colored(colors.green, "✓ fcitx5 proxy 创建成功")

  -- 4. 测试获取当前输入法
  print_colored(colors.cyan, "步骤 4: 测试获取当前输入法...")
  local im_ok, im_result = pcall(function()
    return fcitx_proxy:call_sync("CurrentInputMethod", nil, Gio.DBusCallFlags.NONE, -1)
  end)

  if not im_ok then
    print_colored(colors.red, "✗ 获取当前输入法失败: " .. tostring(im_result))
    return false
  end

  -- Handle GLib.Variant userdata
  local current_im = nil
  local result_type = type(im_result)

  if result_type == "userdata" then
    local GLib = lgi.require("GLib")
    local unwrap_ok, value = pcall(function()
      local child = im_result:get_child_value(0)
      return child:get_string()
    end)
    if unwrap_ok then
      current_im = value
    end
  elseif result_type == "table" then
    if im_result.value and im_result.value[1] then
      current_im = im_result.value[1]
    elseif im_result[1] then
      current_im = im_result[1]
    end
  elseif result_type == "string" then
    current_im = im_result
  end

  if current_im then
    print_colored(colors.green, "✓ 当前输入法: " .. tostring(current_im))
  else
    print_colored(colors.red, "✗ 无法提取输入法名称")
    return false
  end

  -- 5. 测试 Rime proxy
  print_colored(colors.cyan, "步骤 5: 测试 Rime proxy...")
  local rime_ok, rime_proxy = pcall(function()
    return Gio.DBusProxy.new_sync(
      bus,
      Gio.DBusProxyFlags.NONE,
      nil,
      "org.fcitx.Fcitx5",
      "/rime",
      "org.fcitx.Fcitx.Rime1",
      nil
    )
  end)

  if not rime_ok then
    print_colored(colors.yellow, "⚠ Rime proxy 不可用 (Rime 可能未启用)")
  else
    print_colored(colors.green, "✓ Rime proxy 创建成功")

    -- 测试获取 Rime 状态
    print_colored(colors.cyan, "步骤 6: 测试获取 Rime 状态...")
    local rime_state_ok, rime_state = pcall(function()
      return rime_proxy:call_sync("IsAsciiMode", nil, Gio.DBusCallFlags.NONE, -1)
    end)

    if rime_state_ok then
      local ascii_mode = nil
      local state_result_type = type(rime_state)

      if state_result_type == "userdata" then
        local GLib = lgi.require("GLib")
        local unwrap_ok, value = pcall(function()
          local child = rime_state:get_child_value(0)
          return child:get_boolean()
        end)
        if unwrap_ok then
          ascii_mode = value
        end
      elseif state_result_type == "table" then
        if rime_state.value and rime_state.value[1] then
          ascii_mode = rime_state.value[1]
        elseif rime_state[1] then
          ascii_mode = rime_state[1]
        end
      elseif state_result_type == "boolean" then
        ascii_mode = rime_state
      end

      if ascii_mode ~= nil then
        local state_str = ascii_mode == true and "英文" or "中文"
        print_colored(colors.green, "✓ Rime 状态: " .. state_str)
      else
        print_colored(colors.yellow, "⚠ 无法解析 Rime 状态")
      end
    else
      print_colored(colors.yellow, "⚠ 获取 Rime 状态失败: " .. tostring(rime_state))
    end
  end

  print("")
  print_colored(colors.blue, "==========================================")
  print_colored(colors.green, "所有测试通过！")
  print_colored(colors.blue, "==========================================")
  print("")

  return true
end

return M

-- Comprehensive test for all backend interfaces
package.path = package.path .. ';/home/dengzt/.luarocks/share/lua/5.1/?.lua;./lua/?.lua;./lua/?/init.lua'
package.cpath = package.cpath .. ';/home/dengzt/.luarocks/lib/lua/5.1/?.so'

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

local test_passed = 0
local test_failed = 0

local function test_result(name, passed, detail)
  if passed then
    print_colored(colors.green, "  ✓ " .. name)
    if detail then print("    " .. detail) end
    test_passed = test_passed + 1
  else
    print_colored(colors.red, "  ✗ " .. name)
    if detail then print("    " .. detail) end
    test_failed = test_failed + 1
  end
end

print_colored(colors.blue, "========================================")
print_colored(colors.blue, "完整接口测试")
print_colored(colors.blue, "========================================")
print("")

-- Load lgi
print_colored(colors.cyan, "加载 lgi 模块...")
local ok, lgi = pcall(require, "lgi")
if not ok then
  print_colored(colors.red, "✗ lgi 未安装，无法继续测试")
  return
end
local Gio = lgi.require("Gio")
print_colored(colors.green, "✓ lgi 模块加载成功")
print("")

-- Create bus
print_colored(colors.cyan, "创建 D-Bus 连接...")
local bus = Gio.bus_get_sync(Gio.BusType.SESSION)
if not bus then
  print_colored(colors.red, "✗ D-Bus 连接失败")
  return
end
print_colored(colors.green, "✓ D-Bus 连接成功")
print("")

-- Create fcitx5 proxy
print_colored(colors.cyan, "测试 fcitx5 Controller 接口:")
local fcitx_proxy, err = Gio.DBusProxy.new_sync(
  bus,
  Gio.DBusProxyFlags.NONE,
  nil,
  "org.fcitx.Fcitx5",
  "/controller",
  "org.fcitx.Fcitx.Controller1",
  nil
)

if not fcitx_proxy then
  print_colored(colors.red, "✗ fcitx5 proxy 创建失败: " .. tostring(err))
  return
end
test_result("fcitx5 Controller proxy 创建", fcitx_proxy ~= nil)

-- Test 1: CurrentInputMethod
local im_ok, im_result = pcall(function()
  return fcitx_proxy:call_sync("CurrentInputMethod", nil, Gio.DBusCallFlags.NONE, -1)
end)

if im_ok and im_result then
  local imname = nil
  local result_type = type(im_result)

  if result_type == "userdata" then
    local unwrap_ok, value = pcall(function()
      local child = im_result:get_child_value(0)
      return child:get_string()
    end)
    if unwrap_ok then
      imname = value
    end
  elseif result_type == "table" then
    if im_result.value and im_result.value[1] then
      imname = im_result.value[1]
    elseif im_result[1] then
      imname = im_result[1]
    end
  elseif result_type == "string" then
    imname = im_result
  end

  test_result("CurrentInputMethod 调用", imname ~= nil, "返回: " .. tostring(imname))
else
  test_result("CurrentInputMethod 调用", false, tostring(im_result))
end

-- Test 2: SetCurrentIM
local switch_ok, switch_result = pcall(function()
  local GLib = lgi.require("GLib")
  local variant = GLib.Variant("(s)", {"rime"})
  return fcitx_proxy:call_sync("SetCurrentIM", variant, Gio.DBusCallFlags.NONE, -1)
end)
test_result("SetCurrentIM 调用", switch_ok)
print("")

-- Create rime proxy
print_colored(colors.cyan, "测试 fcitx5 Rime 接口:")
local rime_proxy, rime_err = Gio.DBusProxy.new_sync(
  bus,
  Gio.DBusProxyFlags.NONE,
  nil,
  "org.fcitx.Fcitx5",
  "/rime",
  "org.fcitx.Fcitx.Rime1",
  nil
)

if not rime_proxy then
  print_colored(colors.yellow, "⚠ Rime proxy 不可用 (Rime 可能未启用)")
else
  test_result("Rime proxy 创建", rime_proxy ~= nil)

  -- Test 3: IsAsciiMode
  local ascii_ok, ascii_result = pcall(function()
    return rime_proxy:call_sync("IsAsciiMode", nil, Gio.DBusCallFlags.NONE, -1)
  end)

  if ascii_ok and ascii_result then
    local ascii_mode = nil
    local result_type = type(ascii_result)

    if result_type == "userdata" then
      local unwrap_ok, value = pcall(function()
        local child = ascii_result:get_child_value(0)
        return child:get_boolean()
      end)
      if unwrap_ok then
        ascii_mode = value
      end
    elseif result_type == "table" then
      if ascii_result.value and ascii_result.value[1] then
        ascii_mode = ascii_result.value[1]
      elseif ascii_result[1] then
        ascii_mode = ascii_result[1]
      end
    elseif result_type == "boolean" then
      ascii_mode = ascii_result
    end

    local mode_str = ascii_mode == true and "英文" or "中文"
    test_result("IsAsciiMode 调用", ascii_mode ~= nil, "返回: " .. mode_str)
  else
    test_result("IsAsciiMode 调用", false, tostring(ascii_result))
  end

  -- Test 4: SetAsciiMode
  local set_ok, set_result = pcall(function()
    local GLib = lgi.require("GLib")
    local variant = GLib.Variant("(b)", {true})
    return rime_proxy:call_sync("SetAsciiMode", variant, Gio.DBusCallFlags.NONE, -1)
  end)
  test_result("SetAsciiMode(true) 调用", set_ok)

  -- Test 5: GetCurrentSchema
  local schema_ok, schema_result = pcall(function()
    return rime_proxy:call_sync("GetCurrentSchema", nil, Gio.DBusCallFlags.NONE, -1)
  end)

  if schema_ok and schema_result then
    local schema = nil
    local result_type = type(schema_result)

    if result_type == "userdata" then
      local unwrap_ok, value = pcall(function()
        local child = schema_result:get_child_value(0)
        return child:get_string()
      end)
      if unwrap_ok then
        schema = value
      end
    elseif result_type == "table" then
      if schema_result.value and schema_result.value[1] then
        schema = schema_result.value[1]
      elseif schema_result[1] then
        schema = schema_result[1]
      end
    elseif result_type == "string" then
      schema = schema_result
    end

    test_result("GetCurrentSchema 调用", schema ~= nil, "返回: " .. tostring(schema))
  else
    test_result("GetCurrentSchema 调用", false, tostring(schema_result))
  end
end

print("")
print_colored(colors.blue, "========================================")
if test_failed == 0 then
  print_colored(colors.green, "✓ 所有测试通过！")
else
  print_colored(colors.red, "✗ 部分测试失败")
  print_colored(colors.yellow, "通过: " .. test_passed .. "  失败: " .. test_failed)
end
print_colored(colors.blue, "========================================")

local lib = require("im_switch.lib")

local M = {
  name = "lgi",
  initialized = false,
  bus = nil,
  fcitx_proxy = nil,
  rime_proxy = nil,
}

-- 提取 IM 名称（模块级别函数，避免每次调用时重新定义）
local function extract_im_name(result_value)
  local result_type = type(result_value)

  if result_type == "userdata" then
    local ok, child = pcall(function()
      return result_value:get_child_value(0)
    end)
    if ok then
      local ok2, str = pcall(function()
        return child:get_string()
      end)
      if ok2 then
        return str
      end
    end
  end

  if result_type == "table" then
    if result_value.value and result_value.value[1] then
      return result_value.value[1]
    elseif result_value[1] then
      return result_value[1]
    end
  end

  if result_type == "string" then
    return result_value
  end

  return nil
end

-- 提取 boolean（模块级别函数，避免每次调用时重新定义）
local function extract_boolean(result_value)
  local result_type = type(result_value)

  if result_type == "userdata" then
    local ok, child = pcall(function()
      return result_value:get_child_value(0)
    end)
    if ok then
      local ok2, bool = pcall(function()
        return child:get_boolean()
      end)
      if ok2 then
        return bool
      end
    end
  end

  if result_type == "table" then
    if result_value.value and result_value.value[1] ~= nil then
      return result_value.value[1]
    elseif result_value[1] ~= nil then
      return result_value[1]
    end
  end

  if result_type == "boolean" then
    return result_value
  end

  return nil
end

---Initialize the lgi D-Bus backend
---@return boolean: true if successful
M.init = function()
  local ok, lgi = pcall(require, "lgi")
  if not ok then
    return false
  end

  local Gio = lgi.require("Gio")
  local GLib = lgi.require("GLib")
  M.lgi = lgi
  M.Gio = Gio
  M.GLib = GLib

  local bus_ok, bus = pcall(function()
    return Gio.bus_get_sync(Gio.BusType.SESSION)
  end)

  if not bus_ok then
    return false
  end

  M.bus = bus

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
    return false
  end

  M.fcitx_proxy = fcitx_proxy

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

  if rime_ok then
    M.rime_proxy = rime_proxy
  end

  M.initialized = true
  return true
end

---Get current input method name
---@return string|nil: current IM name or nil if failed
M.get_current_im = function()
  if not M.initialized or not M.fcitx_proxy then
    return nil
  end

  local ok, result = pcall(function()
    return M.fcitx_proxy:call_sync("CurrentInputMethod", nil, M.Gio.DBusCallFlags.NONE, -1)
  end)

  if not ok then
    return nil
  end

  if result == nil then
    return nil
  end

  return extract_im_name(result)
end

---Switch to a specific input method
---@param imname string: target input method name
---@return boolean: true if successful
M.switch_to_im = function(imname)
  if not M.initialized or not M.fcitx_proxy then
    return false
  end

  local ok = pcall(function()
    local variant = M.GLib.Variant("(s)", {imname})
    M.fcitx_proxy:call_sync("SetCurrentIM", variant, M.Gio.DBusCallFlags.NONE, -1)
  end)

  return ok
end

---Get Rime ascii_mode state
---@return boolean|nil: ascii_mode state or nil if not supported
M.get_rime_ascii_mode = function()
  if not M.initialized or not M.rime_proxy then
    return nil
  end

  local ok, result = pcall(function()
    return M.rime_proxy:call_sync("IsAsciiMode", nil, M.Gio.DBusCallFlags.NONE, -1)
  end)

  if not ok or result == nil then
    return nil
  end

  local value = extract_boolean(result)
  if value == nil then
    return nil
  end

  return value == true
end

---Set Rime ascii_mode state
---@param ascii boolean: ascii_mode value
---@return boolean: true if successful
M.set_rime_ascii_mode = function(ascii)
  if not M.initialized or not M.rime_proxy then
    return false
  end

  local ok = pcall(function()
    local variant = M.GLib.Variant("(b)", {ascii})
    M.rime_proxy:call_sync("SetAsciiMode", variant, M.Gio.DBusCallFlags.NONE, -1)
  end)

  return ok
end

return M

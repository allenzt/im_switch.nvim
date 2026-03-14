local config = require("im_switch.config")
local lib = require("im_switch.lib")

local M = {
  current_backend = nil,
  available_backends = {},
  rime_module = nil,
}

---Detect and load the best available backend
---@return table|nil: backend module or nil if none available
M.detect = function()
  local method = config.rime_state_method

  lib.info(string.format("Detecting backend with method: %s", method))

  if method == "auto" then
    return M._detect_ldbus() or M._detect_lgi() or M._detect_remote()
  elseif method == "dbus" then
    return M._detect_ldbus() or M._detect_lgi()
  elseif method == "lgi" then
    return M._detect_lgi()
  elseif method == "remote" then
    return M._detect_remote()
  else
    lib.error(string.format("Unknown rime_state_method: %s", method))
    return M._detect_remote() -- Fallback to remote
  end
end

---Detect ldbus backend
---@return table|nil: backend module or nil
M._detect_ldbus = function()
  local ok, ldbus = pcall(require, "im_switch.backend.dbus.ldbus")
  if ok and ldbus.init() then
    lib.info("ldbus backend detected and initialized")
    return ldbus
  end
  return nil
end

---Detect lgi backend
---@return table|nil: backend module or nil
M._detect_lgi = function()
  local ok, lgi = pcall(require, "im_switch.backend.dbus.lgi")
  if ok and lgi.init() then
    lib.info("lgi backend detected and initialized")
    return lgi
  end
  return nil
end

---Detect fcitx5-remote backend
---@return table|nil: backend module or nil
M._detect_remote = function()
  local ok, remote = pcall(require, "im_switch.backend.fcitx5_remote")
  if ok and remote.init() then
    lib.info("fcitx5-remote backend detected and initialized")
    return remote
  end
  return nil
end

---Initialize the backend system
---@return boolean: true if successful
M.init = function()
  M.current_backend = M.detect()

  if M.current_backend then
    lib.info(string.format("Backend initialized: %s", M.current_backend.name or "unknown"))

    -- Initialize Rime state module if backend supports it
    if M.current_backend.get_rime_ascii_mode and M.current_backend.set_rime_ascii_mode then
      local rime_ok, rime = pcall(require, "im_switch.backend.dbus.rime")
      if rime_ok then
        rime.init(M.current_backend)
        M.rime_module = rime
        lib.info("Rime state module with caching initialized")
      end
    end

    return true
  end

  lib.error("No suitable backend found")
  return false
end

---Get current backend
---@return table|nil: current backend module
M.get_backend = function()
  return M.current_backend
end

---Get current input method
---@return string|nil: current IM name
M.get_current_im = function()
  if M.current_backend then
    return M.current_backend.get_current_im()
  end
  return nil
end

---Switch to a specific input method
---@param imname string: target input method name
---@return boolean: true if successful
M.switch_to_im = function(imname)
  if M.current_backend then
    return M.current_backend.switch_to_im(imname)
  end
  return false
end

---Get Rime ascii_mode state (if supported, with caching)
---@return boolean|nil: ascii_mode state or nil if not supported
M.get_rime_ascii_mode = function()
  -- Use Rime module with caching if available
  if M.rime_module then
    return M.rime_module.get_ascii_mode()
  end

  -- Fallback to direct backend call
  if M.current_backend and M.current_backend.get_rime_ascii_mode then
    return M.current_backend.get_rime_ascii_mode()
  end

  return nil
end

---Set Rime ascii_mode state (if supported, with caching)
---@param ascii boolean: ascii_mode value
---@return boolean: true if successful
M.set_rime_ascii_mode = function(ascii)
  -- Use Rime module with caching if available
  if M.rime_module then
    return M.rime_module.set_ascii_mode(ascii)
  end

  -- Fallback to direct backend call
  if M.current_backend and M.current_backend.set_rime_ascii_mode then
    return M.current_backend.set_rime_ascii_mode(ascii)
  end

  return false
end

---Get Rime cache information
---@return table|nil: cache info or nil if not supported
M.get_rime_cache_info = function()
  if M.rime_module then
    return M.rime_module.get_cache_info()
  end
  return nil
end

return M

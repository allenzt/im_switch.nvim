local lib = require("im_switch.lib")

local M = {
  current_backend = nil,
}

-- IM 查询缓存：插件自己是主要的 IM 切换者，记住上次状态可大幅减少 D-Bus 调用
local im_cache = { value = nil, time = 0, ttl = 1000 }

local function init_lgi()
  local ok, lgi = pcall(require, "im_switch.backend.dbus.lgi")
  if ok and lgi.init() then
    lib.info("lgi backend initialized")
    return lgi
  end
  return nil
end

M.init = function()
  M.current_backend = nil
  im_cache.value = nil
  im_cache.time = 0

  M.current_backend = init_lgi()

  if not M.current_backend then
    local remote_ok, remote = pcall(require, "im_switch.backend.remote")
    if remote_ok and remote.init() then
      M.current_backend = remote
    end
  end

  if not M.current_backend then
    lib.error("Backend initialization failed")
    return false
  end

  lib.info(string.format("Backend: %s", M.current_backend.name or "unknown"))

  -- 加载输入法状态驱动（rime 等）
  local rime_ok = pcall(require, "im_switch.drivers.rime")
  if rime_ok then
    lib.info("Rime state driver loaded")
  end

  return true
end

M.get_backend = function()
  return M.current_backend
end

M.get_current_im = function()
  if not M.current_backend then
    return nil
  end
  local now = vim.loop.now()
  if im_cache.value and (now - im_cache.time) < im_cache.ttl then
    return im_cache.value
  end
  local im = M.current_backend.get_current_im()
  im_cache.value = im
  im_cache.time = now
  return im
end

M.switch_to_im = function(imname)
  if not M.current_backend then
    return false
  end
  local now = vim.loop.now()
  if im_cache.value == imname and im_cache.time > 0 and (now - im_cache.time) < im_cache.ttl then
    return true
  end
  local current = M.current_backend.get_current_im()
  if current == imname then
    im_cache.value = imname
    im_cache.time = now
    return true
  end
  local ok = M.current_backend.switch_to_im(imname)
  if ok then
    im_cache.value = imname
    im_cache.time = now
  end
  return ok
end

-- Rime ascii_mode: 直接透传，供 rime driver 使用
M.get_rime_ascii_mode = function()
  if M.current_backend and M.current_backend.get_rime_ascii_mode then
    return M.current_backend.get_rime_ascii_mode()
  end
  return nil
end

M.set_rime_ascii_mode = function(ascii)
  if not M.current_backend or not M.current_backend.set_rime_ascii_mode then
    return false
  end
  local get_fn = M.current_backend.get_rime_ascii_mode
  if get_fn then
    local current = get_fn()
    if current == ascii then
      return true
    end
  end
  return M.current_backend.set_rime_ascii_mode(ascii)
end

return M

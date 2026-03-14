local config = require("im_switch.config")
local lib = require("im_switch.lib")

local M = {
  backend = nil,
  cache = {
    ascii_mode = nil,
    last_update = 0,
  },
}

---Initialize Rime state module
---@param backend_table table: backend module with get/set_rime_ascii_mode
M.init = function(backend_table)
  M.backend = backend_table
  lib.info("Rime state module initialized")
end

---Get Rime ascii_mode with caching
---@return boolean|nil: ascii_mode state or nil if not available
M.get_ascii_mode = function()
  if M.backend == nil then
    lib.warn("Rime backend not initialized")
    return nil
  end

  local now = vim.loop.now()

  -- Check cache
  if M.cache.ascii_mode ~= nil and (now - M.cache.last_update) < config.rime_state_cache_ttl then
    lib.info(string.format("Rime ascii_mode cache hit: %s (age: %dms)", tostring(M.cache.ascii_mode), now - M.cache.last_update))
    return M.cache.ascii_mode
  end

  -- Cache miss: fetch from backend
  lib.info("Rime ascii_mode cache miss, fetching from backend")
  local ascii_mode = M.backend.get_rime_ascii_mode()

  if ascii_mode ~= nil then
    M.cache.ascii_mode = ascii_mode
    M.cache.last_update = now
  end

  return ascii_mode
end

---Set Rime ascii_mode with cache update
---@param ascii boolean: ascii_mode value
---@return boolean: true if successful
M.set_ascii_mode = function(ascii)
  if M.backend == nil then
    lib.warn("Rime backend not initialized")
    return false
  end

  local ok = M.backend.set_rime_ascii_mode(ascii)

  if ok then
    -- Update cache immediately
    M.cache.ascii_mode = ascii
    M.cache.last_update = vim.loop.now()
    lib.info(string.format("Set Rime ascii_mode: %s (cache updated)", tostring(ascii)))
  else
    lib.error(string.format("Failed to set Rime ascii_mode: %s", tostring(ascii)))
  end

  return ok
end

---Invalidate cache
M.invalidate_cache = function()
  M.cache.ascii_mode = nil
  M.cache.last_update = 0
  lib.info("Rime ascii_mode cache invalidated")
end

---Get cache statistics
---@return table: cache info
M.get_cache_info = function()
  local now = vim.loop.now()
  local age = M.cache.last_update > 0 and (now - M.cache.last_update) or -1

  return {
    cached = M.cache.ascii_mode ~= nil,
    value = M.cache.ascii_mode,
    age_ms = age,
    ttl_ms = config.rime_state_cache_ttl,
    valid = M.cache.ascii_mode ~= nil and age < config.rime_state_cache_ttl,
  }
end

return M

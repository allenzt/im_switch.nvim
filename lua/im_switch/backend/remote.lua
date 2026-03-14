-- fcitx5-remote fallback backend (no D-Bus dependencies)
local M = {
	name = "fcitx5-remote",
}

function M.init()
	return vim.fn.executable("fcitx5-remote") == 1
end

function M.get_current_im()
	local ok, out = pcall(function()
		return vim.trim(vim.fn.system("fcitx5-remote -n"))
	end)
	return ok and out ~= "" and out or nil
end

function M.switch_to_im(imname)
	vim.fn.system("fcitx5-remote -s " .. vim.fn.shellescape(imname))
	return true
end

-- Aliases for compatibility
M.set_current_im = M.switch_to_im

-- Rime ascii_mode not supported via fcitx5-remote
function M.get_rime_ascii_mode()
	return nil
end

function M.set_rime_ascii_mode(_)
	-- no-op
end

return M

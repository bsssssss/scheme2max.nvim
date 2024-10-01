local M = {}

local config = {
	addr = "127.0.0.1",
	port = 7777,
}

local keys = {
	send_paragraph = "<D-e>",
}

local osc

local function init_osc()
	if not osc then
		osc = require("osc").new({
			transport = "udp",
			sendAddr = config.addr,
			sendPort = config.port,
		})
	else
		print("OSC server already started")
	end
end

-- Yank the paragraph at cursor position into register 's'
-- return the cursor to original position aftewards
local function get_paragraph()
	local cursor_pos = vim.api.nvim_win_get_cursor(0)
	vim.cmd('normal! vip"sy')
	vim.api.nvim_win_set_cursor(0, cursor_pos)
	local expression = vim.fn.getreg("s")
	return expression
end

-- Wrap expression in a begin statement so that we can
-- evaluate multiple blocks
local function begin_wrap(s)
	return string.format("\n(begin \n%s)", s)
end

local function send_to_max(s)
	local message = osc.new_message({
		address = "/nvim/s4m",
		types = "s",
		begin_wrap(s),
	})
	local ok, err = osc:send(message)
	if not ok then
		print(err)
	end
end

local function setup_keymaps()
	vim.keymap.set({ "n", "i" }, keys.send_paragraph, M.send_paragraph)
end

local function setup_autocmds()
	vim.api.nvim_create_autocmd({ "BufEnter", "FileType" }, {
		pattern = "*.scm",
		callback = function()
			init_osc()
			vim.api.nvim_create_user_command("S2MSendParagraph", M.send_paragraph, {})
			setup_keymaps()
		end,
	})
end

function M.send_paragraph()
	local message = get_paragraph()
	send_to_max(message)
end

function M.setup(opts)
	opts = opts or {}

	config.addr = opts.addr or config.addr
	config.port = opts.port or config.port
	keys.send_paragraph = (opts.keys and opts.keys.send_paragraph) or keys.send_paragraph

	-- setup_keymaps()
	setup_autocmds()
end

return M

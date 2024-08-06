vim.g.nimb = true
vim.opt.mousescroll = [[ver:1,hor:2]]

---@diagnostic disable-next-line: duplicate-set-field
vim.notify = function(msg, level, opts)
	msg = type(msg) == "string" and msg or vim.inspect(msg)
	level = level or vim.log.levels.INFO
	opts = opts or {}
	vim.rpcnotify(1, "nimb_notify", { msg, level, opts })
end

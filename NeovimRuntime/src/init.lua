vim.g.nimb = true
vim.opt.mousescroll = [[ver:1,hor:2]]

---@diagnostic disable-next-line: duplicate-set-field
-- vim.notify = function(msg, level, opts)
--   msg = type(msg) == "string" and msg or vim.inspect(msg)
--   level = type(level) == "number" or vim.log.levels.INFO
--
--   opts = opts or {}
--   local new_opts = {}
--   if opts.title and type(opts.title) == "string" then
--     new_opts.title = opts.title
--   else
--     new_opts.title = "Nimb"
--   end
--   new_opts.opts_inspected = vim.inspect(opts)
--
--   vim.rpcnotify(1, "nimb_notify", { msg, level, opts = new_opts })
-- end

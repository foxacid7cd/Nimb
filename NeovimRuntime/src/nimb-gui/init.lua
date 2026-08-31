# SPDX-License-Identifier: MIT

local r = require("nimb-gui.response")

local M = {}

---@param direction string
---@param count number
function M.scroll(direction, count)
  local directions = {
    up = [[<ScrollWheelUp>]],
    down = [[<ScrollWheelDown>]],
    left = [[<ScrollWheelLeft>]],
    right = [[<ScrollWheelRight>]],
  }
  local keys = vim.api.nvim_replace_termcodes(directions[direction], true, false, true)
  local multipleKeys = ""
  for _ = 1, count, 1 do
    multipleKeys = multipleKeys .. keys
  end
  vim.api.nvim_feedkeys(multipleKeys, "n", false)
end

function M.buf_text_for_copy()
  local a_orig = vim.fn.getreg("a")
  local mode = vim.fn.mode()

  if mode ~= "v" and mode ~= "V" then
    vim.cmd([[normal! V]])
  end

  vim.cmd([[normal! "aygv]])

  local text = vim.fn.getreg("a")
  vim.fn.setreg("a", a_orig)

  return r.success(text)
end

---Runs an Ex command given as a dict. Arguments are passed through rather than
---spliced into a command line, so a path needs no escaping. Most callers do not
---wait for the reply, so a failure is also reported in the message area.
---@param cmd table
local function run(cmd)
  -- No file magic: a path holding % or # is a path, not a reference to the
  -- current or alternate file.
  cmd.magic = { file = false, bar = false }
  local ok, err = pcall(vim.api.nvim_cmd, cmd, {})
  if not ok then
    vim.notify(err, vim.log.levels.ERROR)
    return r.failure(err)
  end
end

function M.edit(path)
  return run({ cmd = "edit", args = { path } })
end

function M.write()
  return run({ cmd = "write" })
end

function M.save_as(path)
  -- bang: the save panel already asked about replacing an existing file.
  return run({ cmd = "saveas", bang = true, args = { path } })
end

-- confirm: quitting is where unsaved work is lost, so Neovim asks rather than
-- refusing with an error the user has no way to answer.
function M.close()
  return run({ cmd = "quit", mods = { confirm = true } })
end

function M.quit_all()
  return run({ cmd = "qall", mods = { confirm = true } })
end

function M.echo_err(text)
  local escaped = vim.fn.escape(text, "\"\\")
  vim.cmd(([[echohl ErrorMsg | echomsg "%s" | echohl None]]):format(escaped))
end

return M

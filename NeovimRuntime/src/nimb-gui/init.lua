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

function M.edit(path)
  local escaped = vim.fn.escape(path, "\"\\")
  vim.v.errmsg = ""
  vim.cmd(([[silent! edit %s]]):format(escaped))
  if vim.v.errmsg ~= "" then
    return r.failure(vim.v.errmsg)
  end
end

function M.write()
  vim.v.errmsg = ""
  vim.cmd([[silent! write]])
  if vim.v.errmsg ~= "" then
    return r.failure(vim.v.errmsg)
  end
end

function M.save_as(path)
  local escaped = vim.fn.escape(path, "\"\\")
  vim.v.errmsg = ""
  vim.cmd(([[silent! saveas %s]]):format(escaped))
  if vim.v.errmsg ~= "" then
    return r.failure(vim.v.errmsg)
  end
end

function M.close()
  vim.v.errmsg = ""
  vim.cmd([[silent! close]])
  if vim.v.errmsg ~= "" then
    return r.failure(vim.v.errmsg)
  end
end

function M.quit_all()
  vim.v.errmsg = ""
  vim.cmd([[silent! qa]])
  if vim.v.errmsg ~= "" then
    return r.failure(vim.v.errmsg)
  end
end

function M.echo_err(text)
  local escaped = vim.fn.escape(text, "\"\\")
  vim.cmd(([[echohl ErrorMsg | echomsg "%s" | echohl None]]):format(escaped))
end

return M

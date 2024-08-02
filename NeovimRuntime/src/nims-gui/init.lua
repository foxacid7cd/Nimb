# SPDX-License-Identifier: MIT

local r = require("nims-gui.response")

local M = {}

---@param direction string
---@param count number
function M.scroll(direction, count)
  local directions = {
    up = [[\<c-y>]],
    down = [[\<c-e>]],
    left = [[zhzh]],
    right = [[zlzl]],
  }
  local suffix = directions[direction]

  local cmd = [[exe "normal! ]]
  for _=1,count do
    cmd = cmd .. suffix
  end
  cmd = cmd .. [["]]

  vim.cmd(cmd)
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

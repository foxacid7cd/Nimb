# SPDX-License-Identifier: MIT

local M = {}

function M.buf_text_for_copy()
  local a_orig = vim.fn.getreg("a")
  local mode = vim.fn.mode()
  if mode ~= "v" and mode ~= "V" then
    vim.cmd([[normal! V]])
  end
  vim.cmd([[silent! normal! "aygv]])
  local text = vim.fn.getreg("a")
  vim.fn.setreg("a", a_orig)
  return text
end

function M.edit(path)
  vim.cmd([[e ]] .. path)
end

function M.write()
  vim.cmd([[w]])
end

function M.save_as(path)
  vim.cmd([[sav ]] .. path)
end

function M.quit()
  vim.cmd([[q]])
end

function M.quit_all()
  vim.cmd([[qa]])
end

return M

# SPDX-License-Identifier: MIT

local r = require("nims-gui.response")

local M = {}

function M.buf_text_for_copy()
  vim.cmd([[stopinsert]])

  local a_orig = vim.fn.getreg("a")
  local mode = vim.fn.mode()

  local status, error = pcall(function()
    if mode ~= "v" and mode ~= "V" then
      vim.cmd([[normal! V]])
    end
    vim.cmd([[normal! "aygv]])
  end)

  local text = vim.fn.getreg("a")
  vim.fn.setreg("a", a_orig)

  if not status and error then
    return r.failure(error)
  else
    return r.success(text)
  end
end

function M.edit(path)
  vim.cmd([[stopinsert]])

  local status, error = pcall(function()
    vim.cmd([[edit ]] .. path)
  end)
  if not status and error then
    return r.failure(error)
  end
end

function M.write()
  vim.cmd([[stopinsert]])

  local status, error = pcall(function()
    vim.cmd([[write]])
  end)
  if not status and error then
    return r.failure(error)
  end
end

function M.save_as(path)
  vim.cmd([[stopinsert]])

  local status, error = pcall(function()
    vim.cmd([[saveas ]] .. path)
  end)
  if not status and error then
    return r.failure(error)
  end
end

function M.quit()
  vim.cmd([[stopinsert]])

  local status, error = pcall(function()
    vim.cmd([[quit]])
  end)
  if not status and error then
    return r.failure(error)
  end
end

function M.quit_all()
  vim.cmd([[stopinsert]])

  local status, error = pcall(function()
    vim.cmd([[quitall]])
  end)
  if not status and error then
    return r.failure(error)
  end
end

return M

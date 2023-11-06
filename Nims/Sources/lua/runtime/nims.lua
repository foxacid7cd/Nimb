# SPDX-License-Identifier: MIT

local function failure(param)
  local error
  local param_type = type(param)
  if (param_type == "table") then
    error = param
  elseif (param_type == "string") then
    error = { param }
  end

  if (error) then
    return {
      failure = error
    }
  end
end

local function success(param)
  if (param) then
    return {
      success = param
    }
  end
end

local M = {}

function M.buf_text_for_copy()
  vim.cmd([[stopinsert]])

  local a_orig = vim.fn.getreg("a")
  local mode = vim.fn.mode()
  if mode ~= "v" and mode ~= "V" then
    vim.cmd([[normal! V]])
  end
  vim.cmd([[silent! normal! "aygv]])
  local text = vim.fn.getreg("a")
  vim.fn.setreg("a", a_orig)
  return success(text)
end

function M.edit(path)
  vim.cmd([[stopinsert]])

  vim.v.errmsg = ""
  vim.cmd([[silent! edit ]] .. path)
  if vim.v.errmsg ~= "" then
    return failure(vim.v.errmsg)
  end
end

function M.write()
  vim.cmd([[stopinsert]])

  vim.v.errmsg = ""
  vim.cmd([[silent! write]])
  if vim.v.errmsg ~= "" then
    return failure(vim.v.errmsg)
  end
end

function M.save_as(path)
  vim.cmd([[stopinsert]])

  vim.v.errmsg = ""
  vim.cmd([[silent! saveas ]] .. path)
  if vim.v.errmsg ~= "" then
    return failure(vim.v.errmsg)
  end
end

function M.quit()
  vim.cmd([[stopinsert]])

  vim.v.errmsg = ""
  vim.cmd([[silent! quit]])
  if vim.v.errmsg ~= "" then
    return failure(vim.v.errmsg)
  end
end

function M.quit_all()
  vim.cmd([[stopinsert]])

  vim.v.errmsg = ""
  vim.cmd([[silent! quitall]])
  if vim.v.errmsg ~= "" then
    return failure(vim.v.errmsg)
  end
end

return M

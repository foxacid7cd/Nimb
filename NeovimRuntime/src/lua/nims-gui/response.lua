# SPDX-License-Identifier: MIT

local M = {}

function M.success(value)
  if value then
    return {
      success = value
    }
  end
end

function M.failure(value)
  local failure
  if type(value) == "table" then
    failure = value
  elseif type(value) == "string" then
    failure = { value }
  else
    failure = { vim.inspect(value) }
  end
  return {
    failure = failure
  }
end

return M

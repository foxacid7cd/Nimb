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

local visual_modes = { v = true, V = true, ["\22"] = true }

---The visual selection, or the current line when nothing is selected, read
---without touching a register or leaving the mode the user is in.
function M.buf_text_for_copy()
  local mode = vim.fn.mode()
  if not visual_modes[mode] then
    return r.success(vim.api.nvim_get_current_line() .. "\n")
  end

  local lines = vim.fn.getregion(vim.fn.getpos("v"), vim.fn.getpos("."), { type = mode })
  local text = table.concat(lines, "\n")
  -- Linewise selections carry their final newline, the way yanking them does.
  if mode == "V" then
    text = text .. "\n"
  end
  return r.success(text)
end

---Copies, then deletes what it took. Only where deleting means something: in
---insert or terminal mode there is nothing selected to cut.
function M.cut()
  local mode = vim.fn.mode()
  if visual_modes[mode] then
    local result = M.buf_text_for_copy()
    vim.api.nvim_feedkeys("d", "nx", false)
    return result
  elseif mode == "n" then
    local result = M.buf_text_for_copy()
    vim.api.nvim_feedkeys("dd", "nx", false)
    return result
  end
end

local function escape_key()
  return vim.api.nvim_replace_termcodes("<Esc>", true, false, true)
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

---Leaves insert or replace mode first, so an undo takes the whole insert with
---it rather than whatever came before it.
local function undo_redo(cmd)
  local mode = vim.fn.mode()
  if mode == "t" or mode == "c" then
    return
  end
  if mode ~= "n" and not visual_modes[mode] then
    vim.api.nvim_feedkeys(escape_key(), "nx", false)
  end
  return run({ cmd = cmd })
end

function M.undo()
  return undo_redo("undo")
end

function M.redo()
  return undo_redo("redo")
end

---Selects the whole buffer, linewise, whatever mode the user is in.
function M.select_all()
  local mode = vim.fn.mode()
  if mode == "t" or mode == "c" then
    return
  end
  local keys = ""
  if mode ~= "n" and not visual_modes[mode] then
    keys = escape_key()
  end
  vim.api.nvim_feedkeys(keys .. "ggVG", "nx", false)
end

function M.edit(path)
  return run({ cmd = "edit", args = { path } })
end

---Opens a directory and makes it the working directory, which is what opening
---a project folder is expected to mean.
---@param path string
function M.open_folder(path)
  local failure = run({ cmd = "cd", args = { path } })
  if failure then
    return failure
  end
  return run({ cmd = "edit", args = { path } })
end

---Opens paths handed over by the system: the first in the current window, the
---rest as buffers, a directory as the working directory.
---@param paths string[]
function M.open_paths(paths)
  for index, path in ipairs(paths) do
    if vim.fn.isdirectory(path) == 1 then
      local failure = M.open_folder(path)
      if failure then
        return failure
      end
    else
      -- The buffer API rather than :drop and :badd, which take several file
      -- arguments and so split a path on its spaces.
      local buffer = vim.fn.bufadd(path)
      vim.bo[buffer].buflisted = true
      if index == 1 then
        local window = vim.fn.win_findbuf(buffer)[1]
        if window then
          vim.api.nvim_set_current_win(window)
        else
          vim.api.nvim_win_set_buf(0, buffer)
        end
      end
    end
  end
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

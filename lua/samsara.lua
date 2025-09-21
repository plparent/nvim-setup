local M = {}

local list = {}
list.__index = list
setmetatable(list, { __call = function(_, _) return setmetatable({ length = 0 }, list) end })

function list:insert(t)
  if self.length > 0 then
    t._next = self.index._next
    t._next._prev = t
    t._prev = self.index
    t._prev._next = t
    self.index = t
  else
    self.index = t
    self.index._next = t
    self.index._prev = t
  end
  self.length = self.length + 1
end

function list:remove(t)
  if self.length > 1 then
    if self.index == t then
      self.index = t._prev
    end
    t._next._prev = t._prev
    t._prev._next = t._next
  else
    self.index = nil
  end
  self.length = self.length - 1
end

function list:next()
  self.index = self.index._next
  return self.index
end

function list:prev()
  self.index = self.index._prev
  return self.index
end

function list:iterate()
  local index = 0
  local current = self.index
  return function()
    index = index + 1
    if index <= self.length then
      local value = current
      current = current._next
      return value
    end
  end
end

M.groups = {}
M.references = {}
M.calls = {}

function M.print()
  for win_id, buffer in pairs(M.groups) do
    print(win_id, "==========================================")
    for value in buffer:iterate() do
      if vim.api.nvim_buf_is_valid(value[1]) then
        print(value[1], vim.api.nvim_buf_get_name(value[1]))
      else
        print(value[1])
      end
    end
  end
  print("----------------------------------------------")
  for buffer, windows in pairs(M.references) do
    print(buffer, "=========================================")
    for key, _ in pairs(windows) do
      print(key)
    end
  end
end

function M.bnext()
  local win_id = vim.fn.win_getid()
  local buf = M.groups[win_id]:next()
  vim.api.nvim_win_set_buf(win_id, buf[1])
end

function M.bprev()
  local win_id = vim.fn.win_getid()
  local buf = M.groups[win_id]:prev()
  vim.api.nvim_win_set_buf(win_id, buf[1])
end

function M.setup(opts)
  opts = opts or {}

  vim.api.nvim_create_autocmd("BufEnter", {
    callback = function(args)
      table.insert(M.calls, "BufEnter")
      table.insert(M.calls, args.buf)
      local win_id = vim.fn.win_getid()
      if M.references[args.buf] == nil then
        M.references[args.buf] = {}
      end
      if not M.references[args.buf][win_id] then
        M.references[args.buf][win_id] = true
        if M.groups[win_id] then
          M.groups[win_id]:insert({ args.buf })
        end
      end
    end,
  })

  vim.api.nvim_create_autocmd("BufUnload", {
    callback = function(args)
      table.insert(M.calls, "BufUnload")
      table.insert(M.calls, args.buf)
      if M.references[args.buf] then
        for window, _ in pairs(M.references[args.buf]) do
          for value in M.groups[window]:iterate() do
            if value[1] == args.buf then
              M.groups[window]:remove(value)
              break
            end
          end
        end
        M.references[args.buf] = nil
      end
    end,
  })

  vim.api.nvim_create_autocmd("WinEnter", {
    callback = function(_)
      table.insert(M.calls, "WinEnter")
      local win_id = vim.fn.win_getid()
      table.insert(M.calls, win_id)
      if not M.groups[win_id] then
        M.groups[win_id] = list()
      end
    end,
  })

  vim.api.nvim_create_autocmd("WinClosed", {
    callback = function(args)
      local win_id = tonumber(args.match)
      table.insert(M.calls, "WinClosed")
      table.insert(M.calls, win_id)
      if M.groups[win_id] then
        for value in M.groups[win_id]:iterate() do
          M.references[value[1]][win_id] = nil
        end
        M.groups[win_id] = nil
      end
    end,
  })

  vim.api.nvim_create_user_command('Groups', M.print, {})

  vim.api.nvim_create_user_command('Test', function()
    for _, value in ipairs(M.calls) do
      print(value)
    end
  end, {})

  for _, value in ipairs(vim.api.nvim_list_wins()) do
    M.groups[value] = list()
  end
end

return M

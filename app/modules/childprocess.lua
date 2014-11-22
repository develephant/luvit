--[[

Copyright 2014 The Luvit Authors. All Rights Reserved.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS-IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

--]]

local core = require('core')
local timer = require('timer')
local uv = require('uv')

local function spawn(command, args, options)
  local envPairs, em, onCallback, kill

  envPairs = {}
  args = args or {}
  options = options or {}
  options.detached = options.detached or false

  if options.env then
    for k, v in pairs(options.env) do
      table.insert(envPairs, k .. '=' .. v)
    end
  end

  em = core.Emitter:new()
  em.stdin = core.Stream:new(uv.new_pipe(false))
  em.stdout = core.Stream:new(uv.new_pipe(false))
  em.stderr = core.Stream:new(uv.new_pipe(false))
  em.handle, em.pid = uv.spawn(command, {
    stdio = {em.stdin.handle, em.stdout.handle, em.stderr.handle},
    args = args,
    env = envPairs,
    detached = options.detached,
  }, function(code, signal)
    timer.setTimeout(0, function()
      if em.handle then uv.close(em.handle) end
      if em.stderr then em.stderr:close() end
      if em.stdout then em.stdout:close() end
      if em.stdin then em.stdin:close() end
    end)
    em:emit('exit', code, signal)
  end)

  em.kill = function(self, signal)
    if not uv.is_active(self.handle) then return end
    uv.process_kill(self.handle, signal or 'SIGTERM')
  end

  em.stdin:readStart()
  em.stdout:readStart()
  em.stderr:readStart()

  return em
end

exports.spawn = spawn

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

local spawn = require('childprocess').spawn
local los = require('los')
local path = require('luvi').path

require('tap')(function(test)
  test('environment subprocess', function(expect)
    local child, options, onStdout, onExit, onEnd

    options = {
      env = { TEST1 = 1 }
    }

    if los.type() == 'win32' then
      child = spawn('cmd.exe', {'/C', 'set'}, options)
    else
      child = spawn('env', {}, options)
    end

    function onStdout(chunk)
      assert(chunk:find('TEST1=1'))
    end

    function onExit(code, signal)
      assert(code == 0)
    end

    function onEnd()
    end

    child.stdout:on('end', expect(onEnd))
    child.stdout:on('data', expect(onStdout))
    child:on('exit', expect(onExit))
  end)

  test('kill process', function()
    local child, loopPath, onData
    loopPath = path.join(module.dir, 'fixtures', 'loop.lua')
    child = spawn(args[0], { loopPath })

    function onData()
      child:kill()
    end

    child.stdout:on('data', onData)
  end)
end)


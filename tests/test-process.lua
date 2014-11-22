local spawn = require('childprocess').spawn
local los = require('los')

local environmentTestResult = false

require('tap')(function(test)
  test('environment subprocess', function(expect)
    local child, options, onStdout, onExit

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

    child.stdout:on('data', expect(onStdout))
    child:on('exit', expect(onExit))
  end)
end)


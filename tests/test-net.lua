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

local net = require('net')
local uv = require('uv')

local function createTestServer(port, host, listenCallback)
  local server = net.createServer(function(client)
   client:on("data", function(chunk)
     client:write(chunk, function(err)
       assert(err == nil)
     end)
   end)
  end)
  server:listen(port, host, listenCallback)
  server:on("error", function(err) assert(err) end)
  return server
end

require('tap')(function (test)
  test("simple server", function(expect)
    local port = 10081
    local host = '127.0.0.1'
    local server
    server = createTestServer(port, host, expect(function()
      local client
      client = net.createConnection(port, host, expect(function()
        client:on('data', expect(function(data)
          assert(#data == 5)
          assert(data == 'hello')
          client:destroy()
          server:close()
        end))
        client:write('hello')
      end))
    end))
  end)

  test("keepalive server", function(expect)
    local port = 10082
    local host = '127.0.0.1'
    local server
    server = createTestServer(port, host, expect(function()
      local client
      client = net.createConnection(port, host, expect(function(err)
        if err then
          assert(err)
        end
        client:keepalive(true, 10)
        assert(type(client:getsockname()) == 'table')
        assert(client:isConnected() == true)
        client:on('data', expect(function(data)
          client:keepalive(true, 10)
          assert(#data == 5)
          assert(data == 'hello')
          client:destroy()
          server:close()
        end))
        client:write('hello')
      end))
      assert(client:isConnected() == false)
    end))
  end)

  test("nodelay server", function(expect)
    local port = 10083
    local host = '127.0.0.1'
    local server
    server = createTestServer(port, host, expect(function()
      local client
      client = net.createConnection(port, host, expect(function(err)
        if err then
          assert(err)
        end
        client:nodelay(true)
        assert(type(client:getsockname()) == 'table')
        assert(client:isConnected() == true)
        client:on('data', expect(function(data)
          assert(#data == 5)
          assert(data == 'hello')
          client:destroy()
          server:close()
        end))
        client:write('hello')
      end))
    end))
  end)

  test("timeout client", function(expect)
    local port = 10083
    local host = '127.0.0.1'
    local timeout = 500
    local server = net.createServer(expect(function() end))
    server:listen(port, host, expect(function()
      local client
      client = net.createConnection(port, host, expect(function(err)
        assert(not err, err)
        client:write('hello')
      end))
      client:setTimeout(timeout, expect(function()
        client:destroy()
        server:close()
      end))
    end))
  end)
end)

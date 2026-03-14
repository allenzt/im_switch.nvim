-- Wrapper to run lgi backend test
package.path = package.path .. ';/home/dengzt/.luarocks/share/lua/5.1/?.lua;./examples/?.lua'
package.cpath = package.cpath .. ';/home/dengzt/.luarocks/lib/lua/5.1/?.so'

local test = require("test_lgi_backend")
test.test_lgi_backend()

LUA_EXE = ...

if not LUA_EXE then
    io.stderr:write('Usage: lua pak.lua <lua-exe>\n')
    os.exit(1)
end
local fd = assert(io.popen(LUA_EXE..' -e "print(_VERSION)"'))
local ver = fd:read("*a")
fd:close()
ver = tonumber(string.match(ver, 'Lua 5%.(.)'))
if not (ver and ver>=1) then
    io.stderr:write('Usage: lua pak.lua <lua-exe>\n')
    io.stderr:write('       requires Lua >= 5.1\n')
    os.exit(1)
end

local fout = assert(io.open('ceu','w'))
local fin  = assert(io.open'ceu.lua'):read'*a'

local function subst (name)
    local s, e = string.find(fin, "dofile '"..name.."'")
    fin = string.sub(fin, 1, (s-1)) ..
            '\ndo\n' ..
                assert(io.open(name)):read'*a' ..
            '\nend\n' ..
          string.sub(fin, (e+1))
end

-- Lua 5.3
unpack     = unpack     or table.unpack
loadstring = loadstring or load

subst 'tp.lua'
subst 'lines.lua'
subst 'parser.lua'
subst 'ast.lua'
subst 'adj.lua'
subst 'sval.lua'
subst 'env.lua'
subst 'adt.lua'
subst 'mode.lua'
subst 'ref.lua'
subst 'tight.lua'
subst 'fin.lua'
subst 'props.lua'
subst 'ana.lua'
subst 'acc.lua'
subst 'trails.lua'
subst 'labels.lua'
subst 'tmps.lua'
subst 'mem.lua'
subst 'val.lua'
subst 'code.lua'

fin = [[
FILES = {
    template_h =
        [====[]]..'\n'..assert(io.open'../c/template.h'):read'*a'..[[]====],
    template_c =
        [====[]]..'\n'..assert(io.open'../c/template.c'):read'*a'..[[]====],
    ceu_sys_h =
        [====[]]..'\n'..assert(io.open'../c/ceu_sys.h'):read'*a'..[[]====],
    ceu_sys_c =
        [====[]]..'\n'..assert(io.open'../c/ceu_sys.c'):read'*a'..[[]====],
    ceu_pool_h =
        [====[]]..'\n'..assert(io.open'../c/ceu_pool.h'):read'*a'..[[]====],
    ceu_pool_c =
        [====[]]..'\n'..assert(io.open'../c/ceu_pool.c'):read'*a'..[[]====],
    ceu_vector_h =
        [====[]]..'\n'..assert(io.open'../c/ceu_vector.h'):read'*a'..[[]====],
    ceu_vector_c =
        [====[]]..'\n'..assert(io.open'../c/ceu_vector.c'):read'*a'..[[]====],
}
]]..fin

fout:write([=[
#!/usr/bin/env ]=]..LUA_EXE..[=[

--[[
-- This file is automatically generated.
-- Check the github repository for a readable version:
-- http://github.com/fsantanna/ceu
--
-- Céu is distributed under the MIT License:
--

Copyright (C) 2012 Francisco Sant'Anna

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
of the Software, and to permit persons to whom the Software is furnished to do
so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

--
--]]

-- Lua 5.3
unpack     = unpack     or table.unpack
loadstring = loadstring or load

LUA_EXE  = ']=]..LUA_EXE..[=['

]=] .. fin)

fout:close()
os.execute('chmod +x ceu')

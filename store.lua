--[[

 store - v0.1.1 - public domain Lua partial persistent table library
 no warranty implied; use at your own risk

 author: Ilya Kolbin (iskolbin@gmail.com)
 url: github.com/iskolbin/lstore

 See documentation in README file.

 COMPATIBILITY

 Lua 5.1, 5.2, 5.3, LuaJIT 1, 2

 LICENSE

 See end of file for license information.

--]]

local select, tinsert, tremove = _G.select, table.insert, table.remove

local store = {}

local DELETED = {}

local _history = {}

-- TODO implement circular buffer of commands
local function addhistory( self, command )
	local history = _history[self]
	local oldlastcursor = history.lastcursor
	local newcursor = history.cursor+1
	local lastcursor = newcursor
	local commands = history.commands
	history.cursor = lastcursor
	history.lastcursor = lastcursor
	commands[lastcursor] = command
	-- invalidate
	for i = lastcursor+1, oldlastcursor do
		commands[i] = nil
	end
end

function store:init( limit )
	_history[self] = setmetatable( {
		commands = {},
		limit = limit or math.huge,
		cursor = 0,
		lastcursor = 0}, {__mode = 'k'} )
end

function store:set( ... )
	local n = select( '#', ... )
	if n > 1 then
		local obj = self
		for i = 1, n-2 do
			obj = obj[(select( i, ... ))]
		end
		local k, v = select( n-1, ... )
		local oldv = obj[k]
		if v ~= oldv then
			local command = {true, oldv == nil and DELETED or oldv, ...}
			obj[k] = v
			addhistory( self, command )
			return self
		else
			return self, 'not changed'
		end
	else
		return self, 'not end arguments'
	end
end

function store:unset( ... )
	local n = select( '#', ... )
	if n > 0 then
		local obj = self
		for i = 1, n-1 do
			obj = obj[(select( i, ... ))]
		end
		local k = select( n, ... )
		local oldv = obj[k]
		if oldv ~= nil then
			local command = {true, oldv, ...}
			command[n+3] = DELETED
			obj[k] = nil
			addhistory( self, command )
			return self
		else
			return self, 'not changed'
		end
	else
		return self, 'not enough arguments'
	end
end

function store:update( ... )
	local n = select( '#', ... )
	if n > 1 then
		local obj = self
		for i = 1, n-2 do
			obj = obj[(select( i, ... ))]
		end
		local k, fn = select( n-1, ... )
		local oldv = obj[k]
		local v = fn( oldv, k, obj )
		if v ~= oldv then
			local command = {true, oldv == nil and DELETED or oldv, ...}
			command[n+2] = v
			obj[k] = v
			addhistory( self, command )
			return self
		else
			return self, 'not changed'
		end
	else
		return self, 'not enough arguments'
	end
end

function store:insert( ... )
	local n = select( '#', ... )
	if n > 1 then
		local obj = self
		for i = 1, n-2 do
			obj = obj[(select( i, ... ))]
		end
		local i, v = select( n-1, ... )
		local objlen = #obj
		if i < 0 then
			i = i + objlen + 1
		end
		if i >= 1 and i <= objlen+1 then
			local command = {false, DELETED, ...}
			tinsert( obj, i, v )
			addhistory( self, command )
			return self
		else
			return self, 'position out of bounds'
		end
	else
		return self, 'not enough arguments'
	end
end

function store:remove( ... )
	local n = select( '#', ... )
	if n > 0 then
		local obj = self
		for i = 1, n-1 do
			obj = obj[(select( i, ... ))]
		end
		local objlen = #obj
		if objlen > 0 then
			local i = select( n-1, ... )
			if i < 0 then
				i = i + objlen + 1
			end
			local command = {false, obj[i], ...}
			tinsert( command, DELETED )
			tremove( obj, i )
			addhistory( self, command )
			return self
		else
			return self, 'sequence is empty'
		end
	else
		return self, 'not enough arguments'
	end
end

function store:push( ... )
	local n = select( '#', ... )
	if n > 0 then
		local obj = self
		for i = 1, n-1 do
			obj = obj[(select( i, ... ))]
		end
		local v = select( n, ... )
		local command = {false, DELETED, ...}
		command[n+3] = command[n+2]
		command[n+2] = #obj + 1
		tinsert( obj, v )
		addhistory( self, command )
		return self
	else
		return self, 'not enough arguments'
	end
end

function store:pop( ... )
	local n = select( '#', ... )
	if n > 0 then
		local obj = self
		for i = 1, n do
			obj = obj[(select( i, ... ))]
		end
		local objlen = #obj
		if objlen > 0 then
			local command = {false, obj[objlen], ...}
			command[n+3] = objlen
			command[n+4] = DELETED
			tremove( obj )
			addhistory( self, command )
			return self
		else
			return self, 'sequence is empty'
		end
	else
		return self, 'not enough arguments'
	end
end

function store:unshift( ... )
	local n = select( '#', ... )
	if n > 0 then
		local obj = self
		for i = 1, n-1 do
			obj = obj[(select( i, ... ))]
		end
		local v = select( n, ... )
		local command = {false, DELETED, ...}
		command[n+3] = command[n+2]
		command[n+2] = 1
		tinsert( obj, 1, v )
		addhistory( self, command )
		return self
	else
		return self, 'not enough arguments'
	end
end

function store:shift( ... )
	local n = select( '#', ... )
	if n > 0 then
		local obj = self
		for i = 1, n do
			obj = obj[(select( i, ... ))]
		end
		local objlen = #obj
		if objlen > 0 then
			local command = {false, obj[1], ...}
			command[n+3] = 1
			command[n+4] = DELETED
			tremove( obj, 1 )
			addhistory( self, command )
			return self
		else
			return self, 'sequence is empty'
		end
	else
		return self, 'not enough arguments'
	end
end

function store:undo()
	local history = _history[self]
	local command = history.commands[history.cursor]
	if command ~= nil then
		local obj, n = self, #command
		for i = 3, n-2 do
			obj = obj[command[i]]
		end
		local associative, oldv, k = command[1], command[2], command[n-1]
		if associative then
			obj[k] = oldv ~= DELETED and oldv or nil
		else
			if oldv == DELETED then
				tremove( obj, k )
			else
				tinsert( obj, k, oldv )
			end
		end
		-- TODO circular buffer
		history.cursor = history.cursor-1
		return self
	else
		return self, 'cannot undo'
	end
end

function store:redo()
	local history = _history[self]
	-- TODO circular buffer
	local command = history.commands[history.cursor+1]
	if command ~= nil then
		local obj, n = self, #command
		for i = 3, n-2 do
			obj = obj[command[i]]
		end
		local associative, k, v = command[1], command[n-1], command[n]
		if associative then
			obj[k] = v ~= DELETED and v or nil
		else
			if v == DELETED then
				tremove( obj, k )
			else
				tinsert( obj, k, v )
			end
		end
		-- TODO circular buffer
		history.cursor = history.cursor+1
		return self
	else
		return self, 'cannot redo'
	end
end

-- TODO circular buffer
function store:setlimit( limit )
	_history[self].limit = limit
end

function store:getlimit()
	return _history[self].limit
end

function store:__gethistory()
	return _history[self]
end

function store:__sethistory( history )
	_history[self] = history
end

return store

--[[
------------------------------------------------------------------------------
This software is available under 2 licenses -- choose whichever you prefer.
------------------------------------------------------------------------------
ALTERNATIVE A - MIT License
Copyright (c) 2019 Ilya Kolbin
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
------------------------------------------------------------------------------
ALTERNATIVE B - Public Domain (www.unlicense.org)
This is free and unencumbered software released into the public domain.
Anyone is free to copy, modify, publish, use, compile, sell, or distribute this
software, either in source code form or as a compiled binary, for any purpose,
commercial or non-commercial, and by any means.
In jurisdictions that recognize copyright laws, the author or authors of this
software dedicate any and all copyright interest in the software to the public
domain. We make this dedication for the benefit of the public at large and to
the detriment of our heirs and successors. We intend this dedication to be an
overt act of relinquishment in perpetuity of all present and future rights to
this software under copyright law.
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
------------------------------------------------------------------------------
--]]

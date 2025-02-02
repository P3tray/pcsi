
local cmd = {
	name = script.Name,
	desc = [[Run luau instructions in a sandboxed enviroment]],
	usage = "$ luau compile|interpret|environment (filename) ",
	displayOutput = false,
	ready = function(pCsi, essentials)
		pCsi.fileTypeBindings["luau"] = {
			command = "luau",
			args = {
			}
		}
	end, 
	fn = function(plr, pCsi, essentials, args)

		local luac = pCsi.libs.luac
		local fione = pCsi.libs.fione

		-- lua.lua - Lua 5.1 interpreter (lua.c) reimplemented in Lua.
		--
		-- WARNING: This is not completed but was quickly done just an experiment.
		-- Fix omissions/bugs and test if you want to use this in production.
		-- Particularly pay attention to error handling.
		--
		-- (c) David Manura, 2008-08
		-- Licensed under the same terms as Lua itself.
		-- Based on lua.c from Lua 5.1.3.
		-- Improvements by Shmuel Zeigerman.

		-- Variables analogous to those in luaconf.h
		local LUA_INIT = "LUA_INIT"
		local LUA_PROGNAME = "lua"
		local LUA_PROMPT = "> "
		local LUA_PROMPT2 = ">> "
		local function LUA_QL(x)
			return "'" .. x .. "'"
		end

		-- Variables analogous to those in lua.h
		local LUA_RELEASE = "Lua 5.1.3"
		local LUA_COPYRIGHT = "Copyright (C) 1994-2008 Lua.org, PUC-Rio"

		-- Note: don't allow user scripts to change implementation.
		-- Check for globals with "cat lua.lua | luac -p -l - | grep ETGLOBAL"
		local _G = _G
		local assert = assert
		local pcall = pcall
		local rawget = rawget
		local select = select
		local tostring = tostring
		local type = type
		local unpack = unpack
		local xpcall = xpcall
		local string_format = string.format
		local string_sub = string.sub
		local error = function(...) 
			local args = table.concat({...})
			args = args:gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;"):gsub('"', "&quot;"):gsub("'", "&apos;")
			task.spawn(function()
				essentials.Console.error(args)
			end)
		end

		local progname = LUA_PROGNAME
		local osenv = getfenv()

		local environment = {}

		local oldparse = pCsi.parseCommand
		
	

		environment.math = math
		environment.print = essentials.Console.info
		environment.warn = essentials.Console.warn
		environment.error = essentials.Console.error

		environment.wait = task.wait
		environment.bit32 = bit32
		environment.string = string

		environment.Xinu = essentials
		environment.pCsi = pCsi

		environment.table = table
		environment.pcall = pcall
		environment.task = task
		environment.spawn = task.spawn

		local tbl = {}
		local exited = false
		local osmt = {
				__index = function(t, i)
					if i == "exit" then
						return function(...)
							pCsi.parseCommand = oldparse
							exited = true
							return
						end
					elseif i == "getenv" then
						return function(k)
							return environment[k]
						end
					elseif i == "execute" then
						return function(k)
							oldparse(k)
						end
					elseif i == "tempname" then
						return function() 
							local prefix = "lua_"
							local rand = tostring(math.random(1111,99999))
							
							return prefix..(rand:gsub('.', function (c)
								return string.format('%02X', string.byte(c))
							end))
						end
					else
						return os[i]
					end
				end
		}


		environment.os = setmetatable(tbl, osmt)
		environment.tick = tick
		environment.utf8 = utf8
		environment._G = essentials.Freestore
		environment._VERSION = LUA_RELEASE
		environment.tonumber = tonumber

		-- Use external functions, if available
		local lua_stdin_is_tty = function()
			return true
		end
		local setsignal = function() end

		local function print_usage()
			pCsi.io.write(
				string_format(
					"usage: %s [options] [script [args]].\n"
						.. "Available options are:\n"
						.. "  -e stat  execute string "
						.. LUA_QL("stat")
						.. "\n"
						.. "  -l name  require library "
						.. LUA_QL("name")
						.. "\n"
						.. "  -i       enter interactive mode after executing "
						.. LUA_QL("script")
						.. "\n"
						.. "  -v       show version information\n"
						.. "  --       stop handling options\n"
						.. "  -        execute stdin and stop handling options\n",
					progname
				)
			)
		end

		local function l_message(isErr, pname, msg)
			if pname then
				if isErr then
					essentials.Console.error(string_format("%s: ", pname))
				else
					pCsi.io.write(string_format("%s: ", pname))
				end
			end
			if isErr then
				essentials.Console.error(string_format("%s\n", msg))
			else
				pCsi.io.write(string_format("%s\n", msg))
			end

		end

		local function report(status, msg)
			if not status and msg ~= nil then
				msg = (type(msg) == "string" or type(msg) == "number") and tostring(msg)
					or "(error object is not a string)"
				msg = msg:gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;"):gsub('"', "&quot;"):gsub("'", "&apos;")
				l_message(true, progname, msg)
			end
			return status
		end

		local function tuple(...)
			return { n = select("#", ...), ... }
		end

		local function traceback(message)
			local tp = type(message)
			if tp ~= "string" and tp ~= "number" then
				return message
			end
			local debug = _G.debug
			if type(debug) ~= "table" then
				return message
			end
			local tb = debug.traceback
			if type(tb) ~= "function" then
				return message
			end
			return tb(message, 2)
		end

		local function docall(f, ...)
			local tp = { ... } -- no need in tuple (string arguments only)
			local F = function()
				--print("1"..type(f),unpack(tp))
				local res = type(f) == "function" and f(unpack(tp))--type(f) == "function" and f(unpack(tp)) or f
				--print("2"..type(res), tostring(res))
				return res
			end
			setsignal(true)
			local result = tuple(xpcall(F, traceback))
			setsignal(false)
			-- force a complete garbage collection in case of errors
			if not result[1] then
				result[1] = nil
			end
			return unpack(result, 1, result.n)
		end


		local function dostring(s, name, isbc)
			local bytecode, err = isbc and s or luac(s, name)
			
			local f, msg = fione(bytecode, nil, environment)
			
			if type(f) == "function" then
				f, msg = docall(f)
			end
			return report(f, msg)
		end

		
		local function dofile(name)
			if not name then return nil end
			local hj = pCsi.xfs:fileType(name) == "application/x-lua-bytecode"
			local s = pCsi.xfs.read(name)
			local f, msg = dostring(s, name, hj)
			if type(f) == "function" then
				f, msg = docall(f)
			end
			return report(f, msg)
		end

		local function dolibrary(name)
			return report(docall(_G.require, name))
		end

		local function print_version()
			l_message(false, nil, LUA_RELEASE .. "  " .. LUA_COPYRIGHT)
		end

		local function getargs(argv, n)
			local arg = {}
			for i = 1, #argv do
				arg[i - n] = argv[i]
			end
			if _G.arg then
				local i = 0
				while _G.arg[i] do
					arg[i - n] = _G.arg[i]
					i = i - 1
				end
			end
			return arg
		end

		--FIX? readline support
		local history = {}
		local function saveline(s)
			--  if #s > 0 then
			--    history[#history+1] = s
			--  end
		end

		local function get_prompt(firstline)
			-- use rawget to play fine with require 'strict'
			local pmt = rawget(_G, firstline and "_PROMPT" or "_PROMPT2")
			local tp = type(pmt)
			if tp == "string" or tp == "number" then
				return tostring(pmt)
			end
			return firstline and LUA_PROMPT or LUA_PROMPT2
		end

		local function incomplete(msg)
			if msg then
				local ender = LUA_QL("<eof>")
				if string_sub(msg, -#ender) == ender then
					return true
				end
			end
			return false
		end

		local function pushline(firstline)
			local prmt = get_prompt(firstline)
			local b = pCsi.io.read()
			pCsi.io.write(prmt.." "..b)

			if firstline and string_sub(b, 1, 1) == "=" then
				return "return " .. string_sub(b, 2) -- change '=' to `return'
			else
				return b
			end
		end

		local function loadline()
			local b = pushline(true)
			if not b then
				return -1
			end -- no input
			local f, msg
			while true do -- repeat until gets a complete line
				
				local s,em = pcall(function()
					f, msg = fione(luac(b, "stdin"), nil, environment)
				end)
				if not s and em then error(em) break end
				if not incomplete(msg) then
					break
				end -- cannot try to add lines?
				local b2 = pushline(false)
				if not b2 then -- no more input?
					return -1
				end
				b = b .. "\n" .. b2 -- join them
			end

			saveline(b)

			return f, msg
		end

		local function dotty()
			local oldprogname = progname
			progname = nil
			while not exited do
				local result
				local status, msg = loadline()
				if status == -1 then
					break
				end
				if status then
					result = tuple(docall(status))
					status, msg = result[1], result[2]
				end
				report(status, msg)
				if status and result.n > 1 then -- any result to print?
					status, msg = pcall(essentials.Console.info, unpack(result, 2, result.n))
					if not status then
						l_message(true, progname, string_format("error calling %s (%s)", LUA_QL("print"), msg))
					end
				end
			end
			pCsi.io.write("\n")
			progname = oldprogname
		end

		local function handle_script(argv, n)
			_G.arg = getargs(argv, n) -- collect arguments
			local fname = argv[n]
			if fname == "-" and argv[n - 1] ~= "--" then
				fname = nil -- stdin
			end
			local status, msg = dofile(fname)
			if status then
				status, msg = docall(status, unpack(_G.arg))
			end
			return report(status, msg)
		end

		local function collectargs(argv, p)
			local i = 1
			while i <= #argv do
				if #argv == 0 then return #argv end
				if string_sub(argv[i], 1, 1) ~= "-" then -- not an option?
					return i
				end
				local prefix = string_sub(argv[i], 1, 2)
				if prefix == "--" then
					if #argv[i] > 2 then
						return -1
					end
					return argv[i + 1] and i + 1 or 0
				elseif prefix == "-" then
					return i
				elseif prefix == "-i" then
					if #argv[i] > 2 then
						return -1
					end
					p.i = true
					p.v = true
				elseif prefix == "-v" then
					if #argv[i] > 2 then
						return -1
					end
					p.v = true
				elseif prefix == "-e" then
					p.e = true
					if #argv[i] == 2 then
						i = i + 1
						if argv[i] == nil then
							return -1
						end
					end
				elseif prefix == "-l" then
					if #argv[i] == 2 then
						i = i + 1
						if argv[i] == nil then
							return -1
						end
					end
				else
					return -1 -- invalid option
				end
				i = i + 1
			end
			return 0
		end

		local function runargs(argv, n)
			local i = 1
			while i <= n do
				if argv[i] then
					assert(string_sub(argv[i], 1, 1) == "-")
					local c = string_sub(argv[i], 2, 2) -- option
					if c == "e" then
						local chunk = string_sub(argv[i], 3)
						if chunk == "" then
							i = i + 1
							chunk = argv[i]
						end
						assert(chunk)
						if not dostring(chunk, "=(command line)") then
							return false
						end
					elseif c == "l" then
						local filename = string_sub(argv[i], 3)
						if filename == "" then
							i = i + 1
							filename = argv[i]
						end
						assert(filename)
						if not dolibrary(filename) then
							return false
						end
					end
					i = i + 1
				end
			end
			return true
		end

		local function handle_luainit()
			local init = osenv["LUA_INIT"]
			if init == nil then
				return -- status OK
			elseif string_sub(init, 1, 1) == "@" then
				dofile(string_sub(init, 2))
			else
				dostring(init, "=" .. LUA_INIT)
			end
		end

		local import = _G.import
		if import then
			lua_stdin_is_tty = import.lua_stdin_is_tty or lua_stdin_is_tty
			setsignal = import.setsignal or setsignal
			LUA_RELEASE = import.LUA_RELEASE or LUA_RELEASE
			LUA_COPYRIGHT = import.LUA_COPYRIGHT or LUA_COPYRIGHT
			_G.import = nil
		end

		if _G.arg and _G.arg[0] and #_G.arg[0] > 0 then
			progname = _G.arg[0]
		end
		local argv = args
		handle_luainit()
		local has = { i = false, v = false, e = false }
		local script = collectargs(argv, has)
		if script < 0 then -- invalid args?
			print_usage()
		return
		end
		if has.v then
			print_version()
		end
		local status = runargs(argv, (script > 0) and script - 1 or #argv)
		if not status then
			return
		end
		if script ~= 0 then
			status = handle_script(argv, script)
			if not status then
				return
			end
		else
			_G.arg = nil
		end
		if has.i then
			dotty()
		elseif script == 0 and not has.e and not has.v then
			if lua_stdin_is_tty() then
				print_version()
				dotty()
			else

			end
		end
	end,
}

return cmd

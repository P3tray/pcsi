local cmd = {
	name = script.Name,
	desc = [[Conway's game of life, 40x20]],
	usage = [[]], --TO REDO
	displayOutput = false,
	fn = function(plr, pCsi, essentials, args)
		math.randomseed(os.time())
		-- life.lua
		-- original by Dave Bollinger <DBollinger@compuserve.com> posted to lua-l
		-- modified to use ANSI terminal escape sequences
		-- modified to use for instead of while

		local write = pCsi.io.write

		local ALIVE = "▉"
		local DEAD = " "

		function delay() -- NOTE: SYSTEM-DEPENDENT, adjust as necessary
			for i = 1, 10000 do
			end
			-- local i=os.clock()+1 while(os.clock()<i) do end
            task.wait()
		end

		local function ARRAY2D(w, h)
			local t = { w = w, h = h }
			for y = 1, h do
				t[y] = {}
				for x = 1, w do
					t[y][x] = 0
				end
			end
			return t
		end

		local _CELLS = {}

		-- give birth to a "shape" within the cell array
		function _CELLS:spawn(shape, left, top)
			for y = 0, shape.h - 1 do
				for x = 0, shape.w - 1 do
					self[top + y][left + x] = shape[y * shape.w + x + 1]
				end
			end
		end

		-- run the CA and produce the next generation
		function _CELLS:evolve(next)
			local ym1, y, yp1, yi = self.h - 1, self.h, 1, self.h
			while yi > 0 do
				local xm1, x, xp1, xi = self.w - 1, self.w, 1, self.w
				while xi > 0 do
					local sum = self[ym1][xm1]
						+ self[ym1][x]
						+ self[ym1][xp1]
						+ self[y][xm1]
						+ self[y][xp1]
						+ self[yp1][xm1]
						+ self[yp1][x]
						+ self[yp1][xp1]
					next[y][x] = ((sum == 2) and self[y][x]) or ((sum == 3) and 1) or 0
					xm1, x, xp1, xi = x, xp1, xp1 + 1, xi - 1
				end
				ym1, y, yp1, yi = y, yp1, yp1 + 1, yi - 1
			end
		end

		-- output the array to screen
		function _CELLS:draw()
			local out = "" -- accumulate to reduce flicker
			for y = 1, self.h do
				for x = 1, self.w do
					out = out .. (((self[y][x] > 0) and ALIVE) or DEAD)
				end
				out = out .. "\n"
			end
			write(out)
		end

		-- constructor
		local function CELLS(w, h)
			local c = ARRAY2D(w, h)
			c.spawn = _CELLS.spawn
			c.evolve = _CELLS.evolve
			c.draw = _CELLS.draw
			return c
		end

		--
		-- shapes suitable for use with spawn() above
		--
		local HEART = { 1, 0, 1, 1, 0, 1, 1, 1, 1, w = 3, h = 3 }
		local GLIDER = { 0, 0, 1, 1, 0, 1, 0, 1, 1, w = 3, h = 3 }
		local EXPLODE = { 0, 1, 0, 1, 1, 1, 1, 0, 1, 0, 1, 0, w = 3, h = 4 }
		local FISH = { 0, 1, 1, 1, 1, 1, 0, 0, 0, 1, 0, 0, 0, 0, 1, 1, 0, 0, 1, 0, w = 5, h = 4 }
		local BUTTERFLY = { 1, 0, 0, 0, 1, 0, 1, 1, 1, 0, 1, 0, 0, 0, 1, 1, 0, 1, 0, 1, 1, 0, 0, 0, 1, w = 5, h = 5 }

		-- the main routine
		local function LIFE(w, h)
			-- create two arrays
			local thisgen = CELLS(w, h)
			local nextgen = CELLS(w, h)

			-- create some life
			-- about 1000 generations of fun, then a glider steady-state
			thisgen:spawn(GLIDER, 5, 4)
			thisgen:spawn(EXPLODE, 25, 10)
			thisgen:spawn(FISH, 4, 12)

			-- run until break
			local gen = 1
            local run = true
            local oldparse = pCsi.parseCommand
            function pCsi:parseCommand(plr, args)
                run = false
                pCsi.parseCommand = oldparse
                write("Ended Conway's game of life")
            end
            essentials.Output:OutputToAll("ClearScreen")
			while run do
				thisgen:evolve(nextgen)
				thisgen, nextgen = nextgen, thisgen
                essentials.Output:OutputToAll("ClearScreen")
                write("Conway's Game of Life (any to quit) - Gen ", gen, "\n")
				thisgen:draw()
				gen = gen + 1
				if gen > 2000 then
					break
				end
				--delay()		-- no delay
			end
		end

		LIFE(40, 20)
	end,
}

return cmd

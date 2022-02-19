local cmd = {
	name = script.Name,
	desc = [[Manage execution files]],
	usage = [[$ efile start|stop|track|list template.efile]],
	fn = function(plr, pCsi, essentials, args)
		assert(args[1],"First argument/mode not specified")
		if args[1] == "start" then
			local program = args[2]
			if essentials.Efile:GetEfileByName(program) then
				pname = program
				program = essentials.Efile:GetEfileByName(program)
				--essentials.Console.info("Starting '"..pname.."' ("..program.index..")")
				program:start()

			else
				essentials.Console.warn("Program '"..program.."' not found")
			end
		elseif args[1] == "stop" then
			local program = args[2]
			if essentials.Efile:GetEfileByName(program) then
				pname = program
				program = essentials.Efile:GetEfileByName(program)
				essentials.Console.info("Stopping '"..pname.."' ("..program.index..")")
				program:interrupt()
			else
				essentials.Console.warn("Program '"..program.."' not found")
			end
		elseif args[1] == "list" then
			local buffer = "\n| i | Name | ID | Functions | Status | Start Time | Duration |"
			for i,v in pairs(essentials.Efile:GetAllEfiles()) do
				local cstat = coroutine.status(v.coroutine)
				local cdate = os.date("%Y%m%d %H:%M:%S",v.startTime)
				local cdur = math.round((v.endTime and v.endTime-v.startTime or 0)*10)/10
				buffer = buffer.."\n".."| "..v.index.."° | "..v.component.Name.."| ID"..v.id.." | "..#v.innerFunctions.."fns | "..cstat.." | "..cdate.." | "..cdur.." |"
			end
			essentials.Console.info(buffer)
		elseif args[1] == "track" then
			local program = args[2]
			if essentials.Efile:GetEfileByName(program) then
				pname = program
				program = essentials.Efile:GetEfileByName(program)
				local str = "-- "..pname.." --\n"
				for i, v in pairs(program) do
					if type(v) == "thread" then
						v = ("co, ") .. (coroutine.status(v) or "?")
					elseif  type(v) == "function" then
						v = "fn"
					elseif type(v) == "table" then
						v = game:GetService("HttpService"):JSONEncode(v)
					end
					if v == nil then continue end
					
					str = str..i..": "..tostring(v).."\n"
				end
				essentials.Console.info(str)
			else
				essentials.Console.warn("Program '"..program.."' not found")
			end
		end
	end,
}

return cmd

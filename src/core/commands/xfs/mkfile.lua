local xfs = require(script.Parent.Parent.Parent.fs:WaitForChild("xfsm",12))

local cmd = {
	name = script.Name,
	desc = [[]],
	usage = [[$ ]],
	fn = function(pCsi, essentials,args)
		xfs.mkfile(args[1])
		essentials.Console.info("Created file named "..args[1])

	end,
}

return cmd
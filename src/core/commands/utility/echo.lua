local cmd = {
	name = script.Name,
	desc = [[Output the input]],
	usage = [[$ info]],
	fn = function(pCsi, essentials,args)
		return table.concat(args, " ")
	end,
}

return cmd
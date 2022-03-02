local cmd = {
	name = script.Name,
	desc = [[Displays info about Xinu]],
	usage = [[$ info]],
	fn = function(plr, pCsi, essentials, args)
		--edit to behave more like uname command?
		essentials.Console.info("-- System Information --\n"..
			"Manufacturer: "..essentials.Identification.ProductInfo.Product.Manufacturer.."\n"..
			"Name: "..essentials.Identification.ProductInfo.Software.Name.."\n"..
			"Version: "..essentials.Identification.ProductInfo.Software.Version.."\n"..
			"Serial Identification Number: "..essentials.Identification.SERIAL.."\n"..
			"Hardware Id: "..essentials.Identification.HWID.."\n"..
			"-- End of System Info --"
		)
	end,
}

return cmd
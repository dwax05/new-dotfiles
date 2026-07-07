M = {
	"catgoose/nvim-colorizer.lua",
	event = "BufReadPre",
	config = function()
		require("colorizer").setup({
			filetypes = { "*" },
			user_default_options = {
				RGB = true,
				RRGGBB = true,
				names = true,
				RRGGBBAA = true,
				AARRGGBB = false,
				rgb_fn = false,
				hsl_fn = false,
				css = false,
				css_fn = false,
				mode = "background",
				tailwind = false,
				sass = { enable = false, parsers = { "css" } },
				virtualtext = "■",
				always_update = false,
			},
		})
	end,
}

return M

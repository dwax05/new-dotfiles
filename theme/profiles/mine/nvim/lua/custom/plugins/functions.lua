vim.api.nvim_create_user_command("SmartScratch", function()
	-- Step 1: Open a vertical scratch buffer
	vim.cmd("vnew")

	-- Step 2: Prompt for filetype
	vim.ui.input({ prompt = "Enter filetype (leave blank for unsaved scratch): " }, function(input)
		if input and input ~= "" then
			-- Step 3a: Set filetype
			vim.bo.filetype = input

			-- Step 3b: Generate timestamped filename
			local timestamp = os.date("%d%m%Y-%H%M")
			local filename = string.format("%s/Documents/scratchfiles/%s.%s", os.getenv("HOME"), timestamp, input)

			-- Ensure directory exists
			vim.fn.mkdir(vim.fn.fnamemodify(filename, ":h"), "p")

			-- Step 3c: Save buffer with name
			vim.cmd("file " .. filename)
			vim.cmd("write")
			print("Scratch saved as: " .. filename)
		else
			-- Step 4: Ephemeral buffer (no filetype or save)
			vim.bo.buftype = "nofile"
			vim.bo.bufhidden = "hide"
			vim.bo.swapfile = false
			print("Unsaved scratch buffer created.")
		end
	end)
end, {})

return {}

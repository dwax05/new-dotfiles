vim.keymap.set("n", "<leader>.", ":Ex<CR>", { desc = "Browse Folder" })
vim.keymap.set("n", "<C-w>t", ":split term://zsh<cr>i", { desc = "Terminal" })
vim.keymap.set("n", "<C-s>", ":SmartScratch<CR>", { desc = "Terminal" })

vim.keymap.set("n", "<leader>sS", function()
	local search_dirs = {}
	local common_srcs = { "src", "source", "sources", "lib", "app", "server", "client" }

	-- Find which of these directories exist in the cwd
	for _, dir in ipairs(common_srcs) do
		if vim.fn.isdirectory(dir) == 1 then
			table.insert(search_dirs, dir)
		end
	end

	if #search_dirs == 0 then
		vim.notify("No source directories found in " .. vim.fn.getcwd(), vim.log.levels.WARN)
		return
	end

	-- Try telescope first, fallback to vimgrep
	local ok, telescope = pcall(require, "telescope.builtin")
	if ok then
		telescope.live_grep({ search_dirs = search_dirs })
	else
		-- fallback if telescope not installed
		vim.cmd("vimgrep //gj " .. table.concat(search_dirs, " "))
		vim.cmd("copen")
	end
end, { desc = "Search all common src folders" })

return {}

-- vim: ts=2 sts=2 sw=2 et
-- oo

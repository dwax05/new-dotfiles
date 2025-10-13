return {
	vim.keymap.set("n", "<leader>.", ":Ex<CR>", { desc = "Browse Folder" }),
	vim.keymap.set("n", "<C-w>t", ":split term://zsh<cr>i", { desc = "Terminal" }),
	vim.keymap.set("n", "<C-s>", ":SmartScratch<CR>", { desc = "Terminal" }),
}

-- vim: ts=2 sts=2 sw=2 et
-- oo

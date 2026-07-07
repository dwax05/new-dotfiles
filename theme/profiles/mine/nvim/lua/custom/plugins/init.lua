-- You can add your own plugins here or in other files in this directory!
--  I promise not to create any merge conflicts in this directory :)
--
-- See the kickstart.nvim README for more information
vim.o.shiftwidth = 2
vim.o.softtabstop = 2
vim.o.tabstop = 2
vim.o.et = true
vim.o.swapfile = false
vim.o.termguicolors = true

-- autochdir alternative
-- vim.api.nvim_create_autocmd("BufEnter", {
-- 	pattern = "*",
-- 	callback = function()
-- 		-- Only run for normal file buffers
-- 		if vim.bo.buftype == "" then
-- 			local path = vim.fn.expand("%:p:h")
-- 			if vim.fn.isdirectory(path) == 1 then
-- 				vim.cmd("lcd " .. path)
-- 			end
-- 		end
-- 	end,
-- })

return {}

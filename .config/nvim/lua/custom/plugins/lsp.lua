vim.api.nvim_create_autocmd('FileType', {
  pattern = 'markdown',
  callback = function()
    vim.diagnostic.enable(false)
  end,
})

return {}

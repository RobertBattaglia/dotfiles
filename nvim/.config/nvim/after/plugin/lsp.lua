local lsp = require('lsp-zero').preset({
	name = 'recommended',
	set_lsp_keymaps = true,
	manage_nvim_cmp = true,
})

lsp.on_attach(function(_, bufnr)
  lsp.default_keymaps({buffer = bufnr})
end)

local lspconfig = require('lspconfig')
lspconfig.lua_ls.setup(lsp.nvim_lua_ls())

lsp.setup()


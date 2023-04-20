-- Only required if you have packer configured as `opt`
vim.cmd [[packadd packer.nvim]]

return require('packer').startup(function(use)
	-- Packer can manage itself
	use 'wbthomason/packer.nvim'

	-- Navigation
	use { 'nvim-telescope/telescope.nvim', tag = '0.1.1', requires = { {'nvim-lua/plenary.nvim'} } }

	-- Theme
	use({ 'rose-pine/neovim', as = 'rose-pine' })

	-- Parser
	use ('nvim-treesitter/nvim-treesitter', {run = ':TSUpdate'})
	use 'nvim-treesitter/playground'

	-- Visual Undo stack as tree
	use 'mbbill/undotree'

	-- Git Superpowers
	use 'tpope/vim-fugitive'

	-- lsp
	use {
		'VonHeikemen/lsp-zero.nvim',
		branch = 'v1.x',
		requires = {
			-- LSP Support
			'neovim/nvim-lspconfig',  -- Required
			'williamboman/mason.nvim',
			'williamboman/mason-lspconfig.nvim',

		-- Autocompletion
		{'hrsh7th/nvim-cmp'},     -- Required
		{'hrsh7th/cmp-nvim-lsp'}, -- Required
		{'L3MON4D3/LuaSnip'},     -- Required
	};


	-- Buffers
	use {'akinsho/bufferline.nvim', tag = "v3.*", requires = 'nvim-tree/nvim-web-devicons'},

	-- Status Bar
	use {'nvim-lualine/lualine.nvim', requires = { 'nvim-tree/nvim-web-devicons', opt = true}},
}

end)



vim.opt.termguicolors = true
require("bufferline").setup({
	highlights = {
		buffer_selected = { bold = true },
		diagnostic_selected = { bold = true },
		info_selected = { bold = true },
		info_diagnostic_selected = { bold = true },
		warning_selected = { bold = true },
		warning_diagnostic_selected = { bold = true },
		error_selected = { bold = true },
		error_diagnostic_selected = { bold = true },
	},
	options = {
		numbers = "buffer_id",
		show_buffer_close_icons = false,
	}
})


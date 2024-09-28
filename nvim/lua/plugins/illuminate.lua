return {
	"RRethy/vim-illuminate",
	config = function()
		require("illuminate").configure({
			under_cursor = true,
			providers = {
				"lsp",
				"treesitter",
				"regex",
			},
			filetypes_denylist = {
				"neo-tree",
				"dirvish",
				"fugitive",
				"alpha",
				"lazy",
				"neogitstatus",
				"Trouble",
				"lir",
				"Outline",
				"spectre_panel",
				"toggleterm",
				"DressingSelect",
				"TelescopePrompt",
			},
		})
	end,
}

-- BOOTSTRAP the plugin manager `lazy.nvim` https://lazy.folke.io/installation
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
local lazyLocallyAvailable = vim.uv.fs_stat(lazypath) ~= nil
if not lazyLocallyAvailable then
	local lazyrepo = "https://github.com/folke/lazy.nvim.git"
	local out = vim.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath }):wait()
	if out.code ~= 0 then
		vim.api.nvim_echo({
			{ "Failed to clone lazy.nvim:\n", "ErrorMsg" },
			{ out, "WarningMsg" },
			{ "\nPress any key to exit..." },
		}, true, {})
		vim.fn.getchar()
		os.exit(1)
	end
end
vim.opt.rtp:prepend(lazypath)

--------------------------------------------------------------------------------

-- define what key is used for `<leader>`. Here, we use `,`.
-- (`:help mapleader` for information what the leader key is)
vim.g.mapleader = " "

vim.g.clipboard = "xclip"
vim.o.clipboard = "unnamedplus"
vim.opt.undofile = true

vim.keymap.set("i", "jj", "<C-c>", { desc = "Fast Escape" })
vim.keymap.set("t", "jj", "<C-\\><C-n>", { desc = "Fast Escape" })

vim.keymap.set("n", "<leader><space>", "i<space><Esc>", { desc = "Insert Space" })

vim.keymap.set("i", "<C-h>", "<Left>", { desc = "move left" })
vim.keymap.set("i", "<C-l>", "<Right>", { desc = "move right" })
vim.keymap.set("i", "<C-j>", "<Down>", { desc = "move down" })
vim.keymap.set("i", "<C-k>", "<Up>", { desc = "move up" })

vim.keymap.set("n", "<C-h>", "<C-w>h", { desc = "switch window left" })
vim.keymap.set("n", "<C-l>", "<C-w>l", { desc = "switch window right" })
vim.keymap.set("n", "<C-j>", "<C-w>j", { desc = "switch window down" })
vim.keymap.set("n", "<C-k>", "<C-w>k", { desc = "switch window up" })

vim.keymap.set("n", "U", "<cmd>Lazy update<CR>", { desc = "update plugins" })

local plugins = {
	-- TOOLING: COMPLETION, DIAGNOSTICS, FORMATTING

	checker = { enabled = true },
	-- MASON
	-- * Manager for external tools (LSPs, linters, debuggers, formatters)
	-- * auto-install those external tools
	{
		"WhoIsSethDaniel/mason-tool-installer.nvim",
		dependencies = {
			{ "williamboman/mason.nvim", opts = true },
			{ "williamboman/mason-lspconfig.nvim", opts = true },
		},
		opts = {
			ensure_installed = {
				"pyright", -- LSP for python
				"pylint", -- linter
				"ruff", -- linter & formatter (includes flake8, pep8, black, isort, etc.)
				"debugpy", -- debugger
				"taplo", -- LSP for toml (e.g., for pyproject.toml files)
				"lua-language-server", -- LSP for lua
				"luacheck", -- linter
				"stylua", -- formatter
			},
		},
	},
	{
		"mfussenegger/nvim-lint",
		config = function()
			local lint = require("lint")
			lint.linters_by_ft = {
				python = { "pylint" },
			}

			vim.api.nvim_create_autocmd({ "BufWritePost" }, {
				callback = function()
					lint.try_lint()
				end,
			})
		end,
	},

	-- Setup the LSPs
	-- `gd` and `gr` for goto definition / references
	-- `<C-f>` for formatting
	-- `<leader>c` for code actions (organize imports, etc.)
	{
		"neovim/nvim-lspconfig",
		keys = {
			{ "gd", vim.lsp.buf.definition, desc = "Goto Definition" },
			{ "gr", vim.lsp.buf.references, desc = "Goto References" },
			-- { "<leader>c", vim.lsp.buf.code_action, desc = "Code Action" },
			{ "<C-f>", vim.lsp.buf.format, desc = "Format File" },
		},
		dependencies = { "saghen/blink.cmp" },
		lazy = false,
		init = function()
			local capabilities = require("blink.cmp").get_lsp_capabilities()

			-- setup pyright with completion capabilities
			vim.lsp.config("pyright", {
				capabilities = capabilities,
			})
			vim.lsp.enable("pyright")

			-- setup taplo with completion capabilities
			vim.lsp.config("taplo", {
				capabilities = capabilities,
			})
			vim.lsp.enable("taplo")

			vim.lsp.config("lua_ls", {
				capabilities = capabilities,
			})
			vim.lsp.enable("lua_ls")
		end,
	},

	-- COMPLETION
	{
		"saghen/blink.cmp",
		version = "v0.*", -- blink.cmp requires a release tag for its rust binary

		opts = {
			-- 'default' for mappings similar to built-in vim completion
			-- 'super-tab' for mappings similar to vscode (tab to accept, arrow keys to navigate)
			-- 'enter' for mappings similar to 'super-tab' but with 'enter' to accept
			keymap = { preset = "enter" },
			-- set to 'mono' for 'Nerd Font Mono' or 'normal' for 'Nerd Font'
			-- adjusts spacing to ensure icons are aligned
			appearance = {
				nerd_font_variant = "JetBrainsMono Nerd Font",
			},
		},
	},

	-----------------------------------------------------------------------------
	-- PYTHON REPL
	-- A basic REPL that opens up as a horizontal split
	-- * use `<leader>i` to toggle the REPL
	-- * use `<leader>I` to restart the REPL
	-- * `+` serves as the "send to REPL" operator. That means we can use `++`
	-- to send the current line to the REPL, and `+j` to send the current and the
	-- following line to the REPL, like we would do with other vim operators.
	-- {
	-- 	"Vigemus/iron.nvim",
	-- 	keys = {
	-- 		{ "<leader>i", vim.cmd.IronRepl, desc = "󱠤 Toggle REPL" },
	-- 		{ "<leader>I", vim.cmd.IronRestart, desc = "󱠤 Restart REPL" },
	--
	-- 		-- these keymaps need no right-hand-side, since that is defined by the
	-- 		-- plugin config further below
	-- 		{ "+", mode = { "n", "x" }, desc = "󱠤 Send-to-REPL Operator" },
	-- 		{ "++", desc = "󱠤 Send Line to REPL" },
	-- 	},
	--
	-- 	-- since irons's setup call is `require("iron.core").setup`, instead of
	-- 	-- `require("iron").setup` like other plugins would do, we need to tell
	-- 	-- lazy.nvim which module to via the `main` key
	-- 	main = "iron.core",
	--
	-- 	opts = {
	-- 		keymaps = {
	-- 			send_line = "++",
	-- 			visual_send = "+",
	-- 			send_motion = "+",
	-- 		},
	-- 		config = {
	-- 			-- This defines how the repl is opened. Here, we set the REPL window
	-- 			-- to open in a horizontal split to the bottom, with a height of 10.
	-- 			repl_open_cmd = "horizontal bot 10 split",
	--
	-- 			-- This defines which binary to use for the REPL. If `ipython` is
	-- 			-- available, it will use `ipython`, otherwise it will use `python3`.
	-- 			-- since the python repl does not play well with indents, it's
	-- 			-- preferable to use `ipython` or `bypython` here.
	-- 			-- (see: https://github.com/Vigemus/iron.nvim/issues/348)
	-- 			repl_definition = {
	-- 				python = {
	-- 					command = function()
	-- 						local ipythonAvailable = vim.fn.executable("ipython") == 1
	-- 						local binary = ipythonAvailable and "ipython" or "python3"
	-- 						return { binary }
	-- 					end,
	-- 				},
	-- 			},
	-- 		},
	-- 	},
	-- },

	-----------------------------------------------------------------------------
	-- SYNTAX HIGHLIGHTING & COLORSCHEME

	-- treesitter for syntax highlighting
	-- * auto-installs the parser for python
	{
		"nvim-treesitter/nvim-treesitter",
		-- automatically update the parsers with every new release of treesitter
		build = ":TSUpdate",

		-- since treesitter's setup call is `require("nvim-treesitter.configs").setup`,
		-- instead of `require("nvim-treesitter").setup` like other plugins do, we
		-- need to tell lazy.nvim which module to via the `main` key
		main = "nvim-treesitter.configs",

		opts = {
			highlight = { enable = true }, -- enable treesitter syntax highlighting
			indent = { enable = true }, -- better indentation behavior
			ensure_installed = {
				-- auto-install the Treesitter parser for python and related languages
				"python",
				"toml",
				"rst",
				"ninja",
				"markdown",
				"markdown_inline",
				"lua",
				"luadoc",
			},
		},
	},

	-- COLORSCHEME
	-- In neovim, the choice of color schemes is unfortunately not purely
	-- aesthetic – treesitter-based highlighting or newer features like semantic
	-- highlighting are not always supported by a color scheme. It's therefore
	-- recommended to use one of the popular, and actively maintained ones to get
	-- the best syntax highlighting experience:
	-- https://dotfyle.com/neovim/colorscheme/top
	{
		"navarasu/onedark.nvim",
		-- ensure that the color scheme is loaded at the very beginning
		priority = 1000,
		-- enable the colorscheme
		config = function()
			-- require('onedark').setup {
			--   style = 'darker'
			-- }
			-- Enable theme
			require("onedark").load()
		end,
	},

	-----------------------------------------------------------------------------
	-- DEBUGGING

	-- DAP Client for nvim
	-- * start the debugger with `<leader>dc`
	-- * add breakpoints with `<leader>db`
	-- * terminate the debugger `<leader>dt`
	{
		"mfussenegger/nvim-dap",
		keys = {
			{
				"<leader>dc",
				function()
					require("dap").continue()
				end,
				desc = "Start/Continue Debugger",
			},
			{
				"<leader>db",
				function()
					require("dap").toggle_breakpoint()
				end,
				desc = "Add Breakpoint",
			},
			{
				"<leader>dt",
				function()
					require("dap").terminate()
				end,
				desc = "Terminate Debugger",
			},
			{
				"<Up>",
				function()
					require("dap").continue()
				end,
			},
			{
				"<Down>",
				function()
					require("dap").step_over()
				end,
			},
			{
				"<Right>",
				function()
					require("dap").step_into()
				end,
			},
			{
				"<Left>",
				function()
					require("dap").step_out()
				end,
			},
		},
	},

	-- UI for the debugger
	-- * the debugger UI is also automatically opened when starting/stopping the debugger
	-- * toggle debugger UI manually with `<leader>du`
	{
		"rcarriga/nvim-dap-ui",
		dependencies = { "mfussenegger/nvim-dap", "nvim-neotest/nvim-nio" },
		keys = {
			{
				"<leader>du",
				function()
					require("dapui").toggle()
				end,
				desc = "Toggle Debugger UI",
			},
		},
		-- automatically open/close the DAP UI when starting/stopping the debugger
		config = function()
			local listener = require("dap").listeners
			listener.after.event_initialized["dapui_config"] = function()
				require("dapui").open()
			end
			listener.before.event_terminated["dapui_config"] = function()
				require("dapui").close()
			end
			listener.before.event_exited["dapui_config"] = function()
				require("dapui").close()
			end
		end,
	},

	-- Configuration for the python debugger
	-- * configures debugpy for us
	-- * uses the debugpy installation from mason
	{
		"mfussenegger/nvim-dap-python",
		dependencies = "mfussenegger/nvim-dap",
		config = function()
			-- fix: E5108: Error executing lua .../Local/nvim-data/lazy/nvim-dap-ui/lua/dapui/controls.lua:14: attempt to index local 'element' (a nil value)
			-- see: https://github.com/rcarriga/nvim-dap-ui/issues/279#issuecomment-1596258077
			require("dapui").setup()
			-- uses the debugypy installation by mason
			require("dap-python").setup("uv") ---@diagnostic disable-line: missing-fields
		end,
	},

	-----------------------------------------------------------------------------
	-- EDITING SUPPORT PLUGINS
	-- some plugins that help with python-specific editing operations

	-- Docstring creation
	-- * quickly create docstrings via `<leader>a`
	{
		"danymat/neogen",
		opts = true,
		keys = {
			{
				"<leader>a",
				function()
					require("neogen").generate()
				end,
				desc = "Add Docstring",
			},
		},
	},

	-- f-strings
	-- * auto-convert strings to f-strings when typing `{}` in a string
	-- * also auto-converts f-strings back to regular strings when removing `{}`
	-- {
	-- 	"chrisgrieser/nvim-puppeteer",
	-- 	dependencies = "nvim-treesitter/nvim-treesitter",
	-- },
	{
		"folke/flash.nvim",
		event = "VeryLazy",
		---@type Flash.Config
		opts = {},
    -- stylua: ignore
    keys = {
      { "s", mode = { "n", "x", "o" }, function() require("flash").jump() end,       desc = "Flash" },
      { "S", mode = { "n", "x", "o" }, function() require("flash").treesitter() end, desc = "Flash Treesitter" },
      -- { "r", mode = "o", function() require("flash").remote() end, desc = "Remote Flash" },
      -- { "R", mode = { "o", "x" }, function() require("flash").treesitter_search() end, desc = "Treesitter Search" },
      -- { "<c-s>", mode = { "c" }, function() require("flash").toggle() end, desc = "Toggle Flash Search" },
    },
	},

	{
		"nvim-telescope/telescope.nvim",
		tag = "0.1.8",
		dependencies = { "nvim-lua/plenary.nvim" },
		config = function()
			require("telescope").load_extension("file_browser")
			local builtin = require("telescope.builtin")
			vim.keymap.set("n", "<leader>ff", builtin.find_files, { desc = "[S]earch [F]iles" })
			vim.keymap.set("n", "<leader>fw", builtin.grep_string, { desc = "[S]earch current [W]ord" })
			vim.keymap.set("n", "<leader>fb", builtin.buffers, { desc = "[S]earch existing [B]uffers" })
			vim.keymap.set(
				"n",
				"<leader>fc",
				builtin.current_buffer_fuzzy_find,
				{ desc = "[S]earch in [C]urrent buffer" }
			)
		end,
	},

	{
		"nvim-telescope/telescope-file-browser.nvim",
		dependencies = { "nvim-telescope/telescope.nvim", "nvim-lua/plenary.nvim" },
		config = function()
			local file_browser = require("telescope").extensions.file_browser
			vim.keymap.set("n", "<leader>fa", function()
				file_browser.file_browser({ hidden = true })
			end, { desc = "[F]ile [B]rowser" })
		end,
	},
	{
		"folke/which-key.nvim",
		event = "VeryLazy",
		opts = {},
		keys = {
			{
				"<leader>?",
				function()
					require("which-key").show({ global = false })
				end,
				desc = "Buffer Local Keymaps (which-key)",
			},
		},
	},
	{
		"jiaoshijie/undotree",
		dependencies = { "nvim-lua/plenary.nvim" },
		---@module 'undotree.collector'
		---@type UndoTreeCollector.Opts
		opts = {},
		keys = { -- load the plugin only when using it's keybinding:
			{ "<leader>u", "<cmd>lua require('undotree').toggle()<cr>" },
		},
	},
	-- {
	-- 	{
	-- 		"lukas-reineke/indent-blankline.nvim",
	-- 		main = "ibl",
	-- 		---@module "ibl"
	-- 		---@type ibl.config
	-- 		opts = {},
	-- 	},
	-- },
	{
		"windwp/nvim-autopairs",
		event = "InsertEnter",
		config = true,
	},
	{
		{
			"nvim-lualine/lualine.nvim",
			dependencies = { "nvim-tree/nvim-web-devicons" },
			opts = {
				options = {
					theme = "onedark",
					component_separators = "",
					section_separators = { left = "", right = "" },
				},
				sections = {
					lualine_a = { { "mode", separator = { left = "" }, right_padding = 2 } },
					lualine_b = { "filename", "branch" },
					lualine_c = {
						"%=",
						"lsp_status",
					},
					lualine_x = {},
					lualine_y = { "filetype", "progress" },
					lualine_z = {
						{ "location", separator = { right = "" }, left_padding = 2 },
					},
				},
				inactive_sections = {
					lualine_a = { "filename" },
					lualine_b = {},
					lualine_c = {},
					lualine_x = {},
					lualine_y = {},
					lualine_z = { "location" },
				},
				tabline = {},
				extensions = {},
			},
		},
	},
	{
		"folke/trouble.nvim",
		opts = {}, -- for default options, refer to the configuration section for custom setup.
		cmd = "Trouble",
		keys = {
			{
				"<leader>xx",
				"<cmd>Trouble diagnostics toggle<cr>",
				desc = "Diagnostics (Trouble)",
			},
			{
				"<leader>xX",
				"<cmd>Trouble diagnostics toggle filter.buf=0<cr>",
				desc = "Buffer Diagnostics (Trouble)",
			},
			{
				"<leader>cs",
				"<cmd>Trouble symbols toggle focus=false<cr>",
				desc = "Symbols (Trouble)",
			},
			{
				"<leader>cl",
				"<cmd>Trouble lsp toggle focus=false win.position=right<cr>",
				desc = "LSP Definitions / references / ... (Trouble)",
			},
			{
				"<leader>xL",
				"<cmd>Trouble loclist toggle<cr>",
				desc = "Location List (Trouble)",
			},
			{
				"<leader>xQ",
				"<cmd>Trouble qflist toggle<cr>",
				desc = "Quickfix List (Trouble)",
			},
		},
	},
}

--------------------------------------------------------------------------------

-- tell lazy.nvim to load and configure all the plugins
require("lazy").setup(plugins)

--------------------------------------------------------------------------------
-- SETUP BASIC PYTHON-RELATED OPTIONS

-- The filetype-autocmd runs a function when opening a file with the filetype
-- "python". This method allows you to make filetype-specific configurations. In
-- there, you have to use `opt_local` instead of `opt` to limit the changes to
-- just that buffer. (As an alternative to using an autocmd, you can also put those
-- configurations into a file `/after/ftplugin/{filetype}.lua` in your
-- nvim-directory.)
vim.api.nvim_create_autocmd("FileType", {
	pattern = "python", -- filetype for which to run the autocmd
	callback = function()
		-- use pep8 standards
		vim.opt_local.expandtab = true
		vim.opt_local.shiftwidth = 4
		vim.opt_local.tabstop = 4
		vim.opt_local.softtabstop = 4

		-- folds based on indentation https://neovim.io/doc/user/fold.html#fold-indent
		-- if you are a heavy user of folds, consider using `nvim-ufo`
		-- vim.opt_local.foldmethod = "indent"

		local iabbrev = function(lhs, rhs)
			vim.keymap.set("ia", lhs, rhs, { buffer = true })
		end
		-- automatically capitalize boolean values. Useful if you come from a
		-- different language, and lowercase them out of habit.
		iabbrev("true", "True")
		iabbrev("false", "False")

		-- we can also fix other habits we might have from other languages
		iabbrev("--", "#")
		iabbrev("null", "None")
		iabbrev("none", "None")
		iabbrev("nil", "None")
		iabbrev("function", "def")
	end,
})

vim.api.nvim_create_autocmd("FileType", {
	pattern = "lua", -- filetype for which to run the autocmd
	callback = function()
		-- use pep8 standards
		vim.opt_local.expandtab = true
		vim.opt_local.shiftwidth = 2
		vim.opt_local.tabstop = 2
		vim.opt_local.softtabstop = 2
	end,
})

------------------------------------------------------------------------------

-- Example init file showing how to use the buffer tracker plugin
local samsara = require("samsara")

-- Initialize the plugin
samsara.setup()

vim.keymap.set("n", "<leader>h", ":Groups<CR>", { desc = "Print Groups" })
vim.keymap.set("n", "<leader>n", samsara.bnext, { desc = "Next Buffer" })
vim.keymap.set("n", "<leader>p", samsara.bprev, { desc = "Previous Buffer" })
vim.keymap.set("n", "<leader>t", ":tabnew<CR>", { desc = "New Tab" })
vim.keymap.set("n", "<Tab>", ":tabnext<CR>", { desc = "Next Tab" })
vim.keymap.set("n", "<S-Tab>", ":tabprev<CR>", { desc = "Previous Tab" })
vim.keymap.set("n", "<leader>T", ":terminal<CR>", { desc = "New Terminal" })

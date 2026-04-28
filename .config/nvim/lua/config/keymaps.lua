-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here
--
-- In your keymaps configuration file
vim.keymap.set("n", "<leader>tn", function()
  require("neotest").run.run()
end, { desc = "Run nearest test" })

vim.keymap.set("n", "<leader>tf", function()
  require("neotest").run.run(vim.fn.expand("%"))
end, { desc = "Run file tests" })

vim.keymap.set("n", "<leader>tA", function()
  require("neotest").run.run(vim.uv.cwd())
end, { desc = "Run all tests in project" })

vim.keymap.set("n", "<leader>tl", function()
  require("neotest").run.run_last()
end, { desc = "Run last test" })

vim.keymap.set("n", "<leader>to", function()
  require("neotest").output.open()
end, { desc = "Open test output" })

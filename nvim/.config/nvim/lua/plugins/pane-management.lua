-- inside herdr-app (and not tmux), herdr owns ctrl-hjkl for its panes, so nvim's own windows
-- move with <leader>d + hjkl instead (handing ctrl-hjkl through herdr to nvim took ~2s)
local in_herdr = vim.env.HC_TERMINAL_ID ~= nil and vim.env.TMUX == nil

if in_herdr then
  vim.keymap.set("n", "<leader>dh", "<cmd>wincmd h<cr>", { desc = "Move to left window" })
  vim.keymap.set("n", "<leader>dj", "<cmd>wincmd j<cr>", { desc = "Move to bottom window" })
  vim.keymap.set("n", "<leader>dk", "<cmd>wincmd k<cr>", { desc = "Move to top window" })
  vim.keymap.set("n", "<leader>dl", "<cmd>wincmd l<cr>", { desc = "Move to right window" })
end

return {
  {
    "szw/vim-maximizer",
  },
  {
    "christoomey/vim-tmux-navigator",
    cond = not in_herdr,
    cmd = {
      "TmuxNavigateLeft",
      "TmuxNavigateDown",
      "TmuxNavigateUp",
      "TmuxNavigateRight",
      "TmuxNavigatePrevious",
    },
    keys = {
      { "<c-h>", "<cmd><C-U>TmuxNavigateLeft<cr>", desc = "Move to left window"},
      { "<c-j>", "<cmd><C-U>TmuxNavigateDown<cr>", desc = "Move to bottom window"},
      { "<c-k>", "<cmd><C-U>TmuxNavigateUp<cr>", desc = "Move to top window"},
      { "<c-l>", "<cmd><C-U>TmuxNavigateRight<cr>", desc = "Move to right window"},
      { "<c-\\>", "<cmd><C-U>TmuxNavigatePrevious<cr>", desc = "Move to previous window"},
    },
  }
}

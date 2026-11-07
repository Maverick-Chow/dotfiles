-- inside herdr-app (and not tmux), ctrl-hjkl moves between nvim windows and,
-- at the edge, hands off to herdr's pane-nav mod, like vim-tmux-navigator does with tmux
local in_herdr = vim.env.HC_TERMINAL_ID ~= nil and vim.env.TMUX == nil

if in_herdr then
  local function navigate(wincmd, dir)
    return function()
      local win = vim.api.nvim_get_current_win()
      vim.cmd("wincmd " .. wincmd)
      if vim.api.nvim_get_current_win() == win then
        vim.system({ "herdr-app", "do", "pane-nav.go-" .. dir })
      end
    end
  end
  vim.keymap.set("n", "<c-h>", navigate("h", "left"), { desc = "Move to left window" })
  vim.keymap.set("n", "<c-j>", navigate("j", "down"), { desc = "Move to bottom window" })
  vim.keymap.set("n", "<c-k>", navigate("k", "up"), { desc = "Move to top window" })
  vim.keymap.set("n", "<c-l>", navigate("l", "right"), { desc = "Move to right window" })
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

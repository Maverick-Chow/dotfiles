return {
  {
    "szw/vim-maximizer",
  },
  {
    "christoomey/vim-tmux-navigator",
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

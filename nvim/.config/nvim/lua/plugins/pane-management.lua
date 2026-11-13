-- inside herdr-app (and not tmux), herdr owns ctrl-hjkl for its panes, so nvim's own windows
-- move with <leader>d + hjkl instead (handing ctrl-hjkl through herdr to nvim took ~2s)
local in_herdr = vim.env.HC_TERMINAL_ID ~= nil and vim.env.TMUX == nil

if in_herdr then
  vim.keymap.set("n", "<leader>dh", "<cmd>wincmd h<cr>", { desc = "Move to left window" })
  vim.keymap.set("n", "<leader>dj", "<cmd>wincmd j<cr>", { desc = "Move to bottom window" })
  vim.keymap.set("n", "<leader>dk", "<cmd>wincmd k<cr>", { desc = "Move to top window" })
  vim.keymap.set("n", "<leader>dl", "<cmd>wincmd l<cr>", { desc = "Move to right window" })
end

-- inside Rex (and not tmux), Rex passes ctrl-hjkl to nvim; at nvim's edge, hand focus back to Rex
local in_rex = vim.env.REX_SESSION ~= nil and vim.env.TMUX == nil

if in_rex then
  local function nav(wincmd, dir)
    return function()
      local win = vim.fn.winnr()
      vim.cmd("wincmd " .. wincmd)
      if vim.fn.winnr() == win then
        vim.fn.jobstart({ "rex", "focus", dir }, { detach = true })
      end
    end
  end
  vim.keymap.set("n", "<c-h>", nav("h", "left"), { desc = "Move to left window" })
  vim.keymap.set("n", "<c-j>", nav("j", "down"), { desc = "Move to bottom window" })
  vim.keymap.set("n", "<c-k>", nav("k", "up"), { desc = "Move to top window" })
  vim.keymap.set("n", "<c-l>", nav("l", "right"), { desc = "Move to right window" })
end

return {
  {
    "szw/vim-maximizer",
  },
  {
    "christoomey/vim-tmux-navigator",
    cond = not in_herdr and not in_rex,
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

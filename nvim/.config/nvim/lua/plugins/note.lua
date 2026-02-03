return {
  "epwalsh/obsidian.nvim",
  version = "*",
  lazy = true,
  event = {
    "BufReadPre " .. os.getenv("OBSIDIAN_PATH") .. "/*.md",
    "BufNewFile " .. os.getenv("OBSIDIAN_PATH") .. "/*.md",
  },
  dependencies = {
    "nvim-lua/plenary.nvim",
  },
  opts = {
    workspaces = {
      {
        name = "vault",
        path = os.getenv("OBSIDIAN_PATH"),
      },
    },
    -- note_id_func = function(title)
    --   -- Create note IDs in a Zettelkasten format with a timestamp and a suffix.
    --   -- In this case a note with the title 'My new note' will be given an ID that looks
    --   -- like '1657296016-my-new-note', and therefore the file name '1657296016-my-new-note.md'
    --   local suffix = ""
    --   if title ~= nil then
    --     -- If title is given, transform it into valid file name.
    --     suffix = title:gsub(" ", "-"):gsub("[^A-Za-z0-9-]", ""):lower()
    --   else
    --     -- If title is nil, just add 4 random uppercase letters to the suffix.
    --     for _ = 1, 4 do
    --       suffix = suffix .. string.char(math.random(65, 90))
    --     end
    --   end
    --   return tostring(os.time()) .. "-" .. suffix
    -- end,
    -- ---@param url string
    -- follow_url_func = function(url)
    --   vim.ui.open(url) -- need Neovim 0.10.0+
    -- end,
  },
  keys = {
    { "<leader>ob", "<cmd>ObsidianBacklinks<cr>", desc = "Obsidian Backlinks" },
    { "<leader>ol", "<cmd>ObsidianLink<cr>", desc = "Obsidian Link" },
    { "<leader>on", "<cmd>ObsidianNew<cr>", desc = "Obsidian New" },
    { "<leader>oe", "<cmd>ObsidianExtractNote<cr>", desc = "Obsidian Extract" },
    { "<leader>oq", "<cmd>ObsidianQuickSwitch<cr>", desc = "Obsidian QuickSwitch" },
    { "<leader>os", "<cmd>ObsidianSearch<cr>", desc = "Obsidian Search" },
    { "<leader>ot", "<cmd>ObsidianTags<cr>", desc = "Obsidian Tags" },
    { "<leader>op", "<cmd>ObsidianPasteImg<cr>", desc = "Obsidian Paste Image" },
  }
}

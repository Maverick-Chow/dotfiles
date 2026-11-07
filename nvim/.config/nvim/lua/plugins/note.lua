return {
  {
    "MeanderingProgrammer/render-markdown.nvim",
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
      "nvim-tree/nvim-web-devicons", -- optional, for icons
    },
    opts = {
      latex = {
        enabled = true,
        converter = "latex2text",
        highlight = "RenderMarkdownMath",
        top_pad = 0,
        bottom_pad = 0,
      },
    },
  },
  {
    "obsidian-nvim/obsidian.nvim",
    version = "*",
    lazy = true,
    event = {
      "BufReadPre " .. os.getenv("OBSIDIAN_PATH") .. "/*.md",
      "BufNewFile " .. os.getenv("OBSIDIAN_PATH") .. "/*.md",
    },
    opts = {
      legacy_commands = false, -- use :Obsidian <subcommand> instead of :ObsidianX
      picker = { name = "snacks.picker" },
      workspaces = {
        {
          name = "vault",
          path = os.getenv("OBSIDIAN_PATH"),
        },
      },
      ui = { enable = false }, -- render-markdown.nvim handles rendering
      attachments = { folder = "assets/imgs" }, -- same folder as the Obsidian app's attachmentFolderPath
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
    },
    keys = {
      { "<leader>ob", "<cmd>Obsidian backlinks<cr>", desc = "Obsidian Backlinks" },
      { "<leader>ol", ":Obsidian link<cr>", mode = "v", desc = "Obsidian Link" },
      { "<leader>on", "<cmd>Obsidian new<cr>", desc = "Obsidian New" },
      { "<leader>oe", ":Obsidian extract_note<cr>", mode = "v", desc = "Obsidian Extract" },
      { "<leader>oq", "<cmd>Obsidian quick_switch<cr>", desc = "Obsidian QuickSwitch" },
      { "<leader>os", "<cmd>Obsidian search<cr>", desc = "Obsidian Search" },
      { "<leader>ot", "<cmd>Obsidian tags<cr>", desc = "Obsidian Tags" },
      { "<leader>op", "<cmd>Obsidian paste_img<cr>", desc = "Obsidian Paste Image" },
    }
  },
  {
    "shortcuts/no-neck-pain.nvim",
    version = "*",
    opts = { width = 80 },
    keys = {
      { "<leader>z", "<cmd>NoNeckPain<cr>", desc = "Toggle centred mode" },
    },
  }
}


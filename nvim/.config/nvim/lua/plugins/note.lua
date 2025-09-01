return {
  "epwalsh/obsidian.nvim",
  version = "*",  -- recommended, use latest release instead of latest commit
  lazy = true,
  ft = "markdown",
  -- Replace the above line with this if you only want to load obsidian.nvim for markdown files in your vault:
  -- event = {
  --   -- If you want to use the home shortcut '~' here you need to call 'vim.fn.expand'.
  --   -- E.g. "BufReadPre " .. vim.fn.expand "~" .. "/my-vault/*.md"
  --   -- refer to `:h file-pattern` for more examples
  --   "BufReadPre path/to/my-vault/*.md",
  --   "BufNewFile path/to/my-vault/*.md",
  -- },
  dependencies = {
    -- Required.
    "nvim-lua/plenary.nvim",

    -- see below for full list of optional dependencies 👇
  },
  config = function()
    require("obsidian").setup({
      workspaces = {
        {
          name = "vault",
          path = os.getenv("OBSIDIAN_PATH"),
        },
      },
      -- Optional, customize how note IDs are generated given an optional title.
      ---@param title string|?
      ---@return string
      note_id_func = function(title)
        -- Create note IDs in a Zettelkasten format with a timestamp and a suffix.
        -- In this case a note with the title 'My new note' will be given an ID that looks
        -- like '1657296016-my-new-note', and therefore the file name '1657296016-my-new-note.md'
        local suffix = ""
        if title ~= nil then
          -- If title is given, transform it into valid file name.
          suffix = title:gsub(" ", "-"):gsub("[^A-Za-z0-9-]", ""):lower()
        else
          -- If title is nil, just add 4 random uppercase letters to the suffix.
          for _ = 1, 4 do
            suffix = suffix .. string.char(math.random(65, 90))
          end
        end
        return tostring(os.time()) .. "-" .. suffix
      end,
      ---@param url string
      follow_url_func = function(url)
        -- Open the URL in the default web browser.
        -- vim.fn.jobstart({"open", url})  -- Mac OS
        -- vim.fn.jobstart({"xdg-open", url})  -- linux
        -- vim.cmd(':silent exec "!start ' .. url .. '"') -- Windows
        vim.ui.open(url) -- need Neovim 0.10.0+
      end,
    })
    vim.keymap.set("n", "<leader>ob", ":ObsidianBacklinks<cr>", {desc = "Obsidian Backlinks"})
    vim.keymap.set("n", "<leader>ol", ":ObsidianLinks<cr>", {desc = "Obsidian Links"})
    vim.keymap.set("n", "<leader>on", ":ObsidianNew<cr>", {desc = "Obsidian New"})
    vim.keymap.set("n", "<leader>oe", ":ObsidianExtractNote<cr>", {desc = "Obsidian Extract"})
    vim.keymap.set("n", "<leader>oq", ":ObsidianQuickSwitch<cr>", {desc = "Obsidian QuickSwitch"})
    vim.keymap.set("n", "<leader>os", ":ObsidianSearch<cr>", {desc = "Obsidian Search"})
    vim.keymap.set("n", "<leader>ot", ":ObsidianTags<cr>", {desc = "Obsidian Tags"})
  end
}

return {
  "folke/snacks.nvim",
  priority = 1000,
  lazy = false,
  ---@type snacks.Config
  opts = {
    bigfile = { enabled = true },
    dashboard = {
      sections = {
        { section = "header" },
        { section = "keys", gap = 0.5, padding = 1 },
        { icon = " ", title = "Recent Files", section = "recent_files", indent = 2, padding = 1 },
        { icon = " ", title = "Projects", section = "projects", indent = 2, padding = 1 },
        { section = "startup" },
      },
    },
    notifier = {
      enabled = true,
      timeout = 3000,
    },
    quickfile = { enabled = true },
    -- statuscolumn = { enabled = true },
    words = { enabled = true },
    styles = {
      notification = {
        wo = { wrap = true } -- Wrap notifications
      }
    },
    image = {
      enabled = true,
      -- vault images: try the note's folder, then the vault root (![](assets/imgs/img.png)),
      -- then the attachments folder (![[img.png]]); nil falls back to snacks' default
      resolve = function(path, src)
        if not package.loaded["obsidian"] or src:match("^%a[%w+.-]*://") then
          return
        end
        local api = require("obsidian.api")
        if not api.path_is_note(path) then
          return
        end
        src = vim.uri_decode(src)
        for _, candidate in ipairs({
          vim.fs.joinpath(vim.fs.dirname(path), src),
          vim.fs.joinpath(tostring(api.resolve_workspace_dir(path)), src),
          api.resolve_attachment_path(src, path),
        }) do
          if vim.uv.fs_stat(candidate) then
            return vim.fs.normalize(candidate)
          end
        end
      end,
      doc = {
        max_width = 80,
        max_height = 15,
      }
    },
    indent = { enabled = true },
    scroll = {
      animate = {
        duration = { step = 5, total = 150},
      },
    },
    input = { enabled = true},
  },
  keys = {
    { "<leader>n",  function() Snacks.notifier.show_history() end, desc = "Notification History" },
    { "<leader>bd", function() Snacks.bufdelete() end, desc = "Delete Buffer" },
    { "<leader>cR", function() Snacks.rename.rename_file() end, desc = "Rename File" },
    { "<leader>gB", function() Snacks.gitbrowse() end, desc = "Git Browse" },
    { "<leader>gb", function() Snacks.git.blame_line() end, desc = "Git Blame Line" },
    { "<leader>gf", function() Snacks.lazygit.log_file() end, desc = "Lazygit Current File History" },
    { "<leader>gg", function() Snacks.lazygit() end, desc = "Lazygit" },
    { "<leader>gl", function() Snacks.lazygit.log() end, desc = "Lazygit Log (cwd)" },
    { "<leader>un", function() Snacks.notifier.hide() end, desc = "Dismiss All Notifications" },
    { "<leader>ui", function() Snacks.image.hover() end, desc = "Dismiss All Notifications" },
    { "]]",         function() Snacks.words.jump(vim.v.count1) end, desc = "Next Reference", mode = { "n", "t" } },
    { "[[",         function() Snacks.words.jump(-vim.v.count1) end, desc = "Prev Reference", mode = { "n", "t" } },
  },
  config = function(_, opts)
    -- herdr-app speaks kitty graphics with unicode placeholders, like ghostty; say so instead of
    -- relying on ghostty's env vars leaking in from wherever herdr-core was started.
    -- it doesn't read images from file paths (t=f), so send the data inline as over ssh
    if vim.env.HC_TERMINAL_ID and not vim.env.TMUX then
      vim.env.SNACKS_GHOSTTY = "1"
      vim.env.SNACKS_SSH = "1"
    end
    require("snacks").setup(opts)
    -- herdr-app reports the terminal size in cells but 0x0 pixels, which leaves snacks.image
    -- with 0px cells (images get divided by zero); fall back to snacks' default 9x18 cells
    local terminal = require("snacks.image.terminal")
    if vim.env.HC_TERMINAL_ID and not vim.env.TMUX then
      -- the TUI makes the shared tty non-blocking, so io.stdout:write drops whatever doesn't fit
      -- (image chunks got cut at 1024 bytes); keep writing until every byte is out
      terminal.write = function(data)
        io.stdout:flush()
        local done = 0
        while done < #data do
          local n, err = vim.uv.fs_write(1, done == 0 and data or data:sub(done + 1))
          if n and n > 0 then
            done = done + n
          elseif err and not err:find("EAGAIN") then
            return
          else
            vim.uv.sleep(1)
          end
        end
      end
    end
    local size = terminal.size
    terminal.size = function()
      local s = size()
      if s.cell_width > 0 and s.cell_height > 0 then
        return s
      end
      local dw, dh = 9, 18
      return vim.tbl_extend("force", s, {
        width = s.columns * dw,
        height = s.rows * dh,
        cell_width = dw,
        cell_height = dh,
        scale = dw / 8,
      })
    end
  end,
  init = function()
    vim.api.nvim_create_autocmd("User", {
      pattern = "VeryLazy",
      callback = function()
        -- Setup some globals for debugging (lazy-loaded)
        _G.dd = function(...)
          Snacks.debug.inspect(...)
        end
        _G.bt = function()
          Snacks.debug.backtrace()
        end
        vim.print = _G.dd -- Override print to use snacks for `:=` command

        -- Create some toggle mappings
        Snacks.toggle.option("spell", { name = "Spelling" }):map("<leader>us")
        Snacks.toggle.option("wrap", { name = "Wrap" }):map("<leader>uw")
        Snacks.toggle.option("relativenumber", { name = "Relative Number" }):map("<leader>uL")
        Snacks.toggle.diagnostics():map("<leader>ud")
        Snacks.toggle.line_number():map("<leader>ul")
        Snacks.toggle.option("conceallevel", { off = 0, on = vim.o.conceallevel > 0 and vim.o.conceallevel or 2 }):map("<leader>uc")
        Snacks.toggle.treesitter():map("<leader>uT")
        Snacks.toggle.inlay_hints():map("<leader>uh")
        Snacks.toggle.dim():map("<leader>uD")
        Snacks.toggle.zen():map("<leader>uf")
      end,
    })
end,
}

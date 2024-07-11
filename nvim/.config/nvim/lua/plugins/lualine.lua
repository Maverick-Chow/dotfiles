return {
  "nvim-lualine/lualine.nvim",
  config = function()
    require('lualine').setup({
      option = {
        -- theme = 'dracula'
        theme = 'ayu_light'
      }
    })
  end
}

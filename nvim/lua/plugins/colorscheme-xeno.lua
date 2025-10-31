return {
  "kyza0d/xeno.nvim",
  enabled = vim.g.theme == "xeno-pink" or vim.g.theme == "xeno-mononoke",
  lazy = false,
  priority = 1000, -- Load colorscheme early
  config = function()
    -- Create your custom theme here

    if vim.g.theme == "xeno-pink" then
      require("xeno").new_theme("xeno-pink", {
        base = "#0f0c0e",
        accent = "#D19EBC",
        contrast = 0.1,
      })

      vim.cmd("colorscheme xeno-pink")
    end

    if vim.g.theme == "xeno-mononoke" then
      require("xeno").new_theme("xeno-mononoke", {
        base = "#242822",
        accent = "#84A07C",
        contrast = 0.1,
      })

      vim.cmd("colorscheme xeno-mononoke")
    end
  end,
}

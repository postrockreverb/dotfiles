return {
  "kyza0d/xeno.nvim",
  enabled = vim.g.theme == "xeno-pink",
  lazy = false,
  priority = 1000, -- Load colorscheme early
  config = function()
    -- Create your custom theme here
    require("xeno").new_theme("xeno-pink", {
      base = "#0f0c0e",
      accent = "#D19EBC",
      contrast = 0.1,
    })
    vim.cmd("colorscheme xeno-pink")
  end,
}

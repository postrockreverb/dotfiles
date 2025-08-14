return {
  "kevinhwang91/nvim-ufo",
  dependencies = {
    "kevinhwang91/promise-async",
  },
  opts = {
    open_fold_hl_timeout = 0,
    provider_selector = function(_, filetype, _)
      if filetype == "templ" then
        return { "treesitter", "indent" }
      end
      return nil
    end,
  },
  config = function(_, opts)
    require("ufo").setup(opts)
  end,
}

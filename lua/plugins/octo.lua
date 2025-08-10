---@type LazySpec
return {

  "pwntester/octo.nvim",
  optional = true,
  opts = {
    use_local_fs = false, -- use local files on right side of reviews
    enable_builtin = true, -- shows a list of builtin actions when no action is provided
    ssh_aliases = {},
  },
}

---@type LazySpec
return {
  "Davidyz/VectorCode",
  optional = true,
  cli_cmds = {
    vectorcode = os.getenv "HOME" .. "/.local/bin/vectorcode",
  },
}

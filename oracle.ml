open Type


let notimplemented =
  Runtime (
      fun
      (_ : t)
      (_ : string) ->
    Error (RTError, "Not implemented")
  )
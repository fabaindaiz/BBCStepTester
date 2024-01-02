open Type


let handle_exception error func =
  try Ok (func ())
  with e -> Error (error, Printexc.to_string e)

let handle_result result =
  match result with
  | Ok out -> NoError, out
  | Error err -> err


(** Helper functions on strings and processes *)
let filter_lines pred s =
  CCString.split ~by:"\n" s
  |> List.filter pred
  |> String.concat "\n"

let is_comment_line s =
  not (CCString.prefix ~pre:"|" s)

let process_output out =
  String.trim out |> filter_lines is_comment_line


let process_out_channel error file channel =
  try Ok (CCIO.with_out file channel)
  with e -> Error (error, Printexc.to_string e)

let write_file error file string =
  try Ok (CCIO.with_out file (fun o -> output_string o string))
  with e -> Error (error, Printexc.to_string e)

let read_file error file =
  try Ok (process_output (CCIO.with_in file CCIO.read_all))
  with e -> Error (error, Printexc.to_string e)

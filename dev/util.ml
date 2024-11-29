open Type


(** Helper functions on strings and processes *)
let filter_lines pred s =
  CCString.split ~by:"\n" s
  |> List.filter pred
  |> String.concat "\n"

let is_comment_line s =
  not (CCString.prefix ~pre:"|" s)

let process_string out =
  String.trim out |> filter_lines is_comment_line


(* Produce a result out of the return data from the compiler/assembler *)
let wrap_result ?(warning = false) error (out, err, retcode) =
  if retcode = 0 && (warning || String.equal "" err)
  then Ok out
  else Error (error, out ^ err)

let print_output out =
  let* out = out in
  print_string out; Ok ()

let process_output out =
  let* out = out in
  Ok (process_string out)


(** extract values from result *)
let handle_result result =
  match result with
  | Ok out -> NoError, out
  | Error err -> err


let process_out_channel error file channel =
  try Ok (CCIO.with_out file channel)
  with e -> Error (error, Printexc.to_string e)

let write_file error file string =
  try Ok (CCIO.with_out file (fun o -> output_string o string))
  with e -> Error (error, Printexc.to_string e)

let read_file error file =
  try Ok (process_string @@ (CCIO.with_in file CCIO.read_all))
  with e -> Error (error, Printexc.to_string e)

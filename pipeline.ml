open Type
open Util


let compile compiler test =
  match compiler with
    | Compiler compiler ->
      compiler test test.src
    | OCompiler compiler ->
      let file = Filename.chop_extension test.file ^ ".s" in

      let* () = process_out_channel CTError file (compiler test test.src) in
      let* out = read_file CTError file in
      Ok out
    | SCompiler compiler ->
      try Ok (compiler test test.src)
      with e -> Error (CTError, Printexc.to_string e)


let runtime runtime test input =
  match runtime with
  | Runtime runtime -> runtime test input


let oracle runtime test =
  let interp = CCString.find ~sub:"|ORACLE" test.expected in
  match runtime with
  | Runtime oracle when test.status = NoError && interp <> -1 ->
    let prefix = CCString.sub test.expected 0 (max (interp - 1) 0) in
    
    let* out = (oracle test test.src) in
    Ok (prefix ^ out)
  | _ ->
    (match test.status with
    | NoError -> Ok test.expected
    | _ -> Error (test.status, test.expected))


let test testeable test =
  match testeable with
  | Testeable testeable -> testeable test

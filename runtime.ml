open Type
open Util


(* Produce a result out of the return data from the compiler/assembler *)
let wrap_result (out, err, retcode) =
  if retcode = 0 && String.equal "" err
  then (print_string out ; Ok ())
  else Error (CTError, out ^ err)

(* Find out current architecture (only supporting Linux/OS X for now) *)
let bin_format =
  let out, _ , _ = CCUnix.call "uname -s" in
  let arch = String.trim out in
  match arch with
  | "Linux" -> "elf64"
  | "Darwin" -> "macho64"
  | _ -> Fmt.failwith "Unknown architecture %s" arch


let nasm basefile =
  wrap_result @@ CCUnix.call "nasm -f %s -o %s.o %s.s" bin_format basefile basefile

let clang ~compile_flags runtime basefile =
  wrap_result @@ CCUnix.call "clang %s -o %s.run %s %s.o" compile_flags basefile runtime basefile


(** Calling the compiler (clang) and assembler (nasm) *)
let clangruntime
    ?(compile_flags: string ="-g")
    (runtime : string) =
  Runtime (
      fun
      (test : t)
      (input : string) ->
    let base = Filename.chop_extension test.file in
    let file = base ^ ".s" in
    let exe = base ^ ".run" in
    
    let* () = write_file file input RTError in
    let* () = nasm base in
    let* () = clang ~compile_flags runtime base in
    let out, err, retcode = CCUnix.call ~env:(Array.of_list test.params) "./%s" exe in
    if retcode = 0 then
      Ok (process_output out)
    else Error (RTError, out ^ err)
  )


(** Calling a unix command *)
let unixcommand
    (command) =
  Runtime (
      fun
      (test : t)
      (input : string) ->
    let base = Filename.chop_extension test.file in
    let file = base ^ ".s" in

    let* () = write_file file input RTError in
    let out, err, retcode = CCUnix.call ~env:(Array.of_list test.params) command file in
    if retcode = 0 then
      Ok (process_output out)
    else Error (RTError, out ^ err)
  )


(** Directly passing the compiled code *)
let compileout =
  Runtime (
      fun
      (test : t)
      (input : string) ->
    let base = Filename.chop_extension test.file in
    let file = base ^ ".s" in

    let* () = write_file file input RTError in
    Ok input
  )

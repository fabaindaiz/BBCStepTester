open Type
open Util


(** Calling the compiler (clang) and assembler (nasm) *)

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


let (let*) = Result.bind


let cruntime
    ?(compile_flags: string ="-g")
    (runtime : string) =
    fun
    (test : t)
    (filename : string) ->
  let base = Filename.chop_extension filename in
  let exe = base ^ ".run" in
  
  let* () = nasm base in
  let* () = clang ~compile_flags runtime base in
  let out, err, retcode = CCUnix.call ~env:(Array.of_list test.params) "./%s" exe in
  if retcode = 0 then
    Ok (process_output out)
  else Error (RTError, out ^ err)


let unixcommand
    (command : string -> string * string * int) =
    fun
    (_ : t)
    (filename : string) ->
  let base = Filename.chop_extension filename in
  let file = base ^ ".s" in

  let out, err, retcode = command file in
  if retcode = 0 then
    Ok (process_output out)
  else Error (RTError, out ^ err)


let compileout =
    fun
    (_ : t)
    (filename : string) ->
  let base = Filename.chop_extension filename in
  let file = base ^ ".s" in

  let out = CCIO.(with_in file read_all) in
  Ok (process_output out)

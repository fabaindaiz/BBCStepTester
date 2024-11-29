open Type
open Util


let has_pending_data fd =
  try
    let ready_fds, _, _ = Unix.select [fd] [] [] 0.0 in
    List.length ready_fds > 0
  with _ -> false

(* Función mejorada de captura que lee hasta completar *)
let capture_stdout_until_done (f : unit -> 'a) : string * 'a =
  (* Guardamos el stdout original y creamos el pipe *)
  let stdout_original = Unix.dup Unix.stdout in
  let (pipe_read, pipe_write) = Unix.pipe () in
  
  (* Configuramos el pipe como no bloqueante para lecturas seguras *)
  Unix.set_nonblock pipe_read;
  Unix.dup2 pipe_write Unix.stdout;
  Unix.close pipe_write;
  
  let buffer = Buffer.create 4096 in
  let string_buffer = Bytes.create 4096 in
  
  let result = 
    try 
      (* Ejecutamos la función principal *)
      let r = f () in
      flush stdout;
      
      (* Leemos datos mientras haya disponibles *)
      let rec read_remaining () =
        if has_pending_data pipe_read then
          match Unix.read pipe_read string_buffer 0 4096 with
          | 0 -> ()  (* EOF - terminamos *)
          | bytes_read -> 
              Buffer.add_subbytes buffer string_buffer 0 bytes_read;
              read_remaining ()
          | exception Unix.Unix_error(Unix.EAGAIN, _, _) -> 
              Unix.sleepf 0.001;  (* Pequeña pausa si el pipe está temporalmente vacío *)
              if has_pending_data pipe_read then read_remaining ()
      in
      read_remaining ();
      Ok r
    with e -> Error e
  in
  
  (* Limpieza y restauración *)
  Unix.dup2 stdout_original Unix.stdout;
  Unix.close stdout_original;
  Unix.close pipe_read;
  
  match result with
  | Ok v -> (Buffer.contents buffer, v)
  | Error e -> raise e


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

let oracle runtime test =
  let interp = CCString.find ~sub:"|ORACLE" test.expected in
  if test.status = NoError && interp <> -1 then
    let prefix = CCString.sub test.expected 0 (max (interp - 1) 0) in
    try
      (* Usamos la nueva función que lee hasta completar *)
      let (stdout_output, runtime_result) = 
        capture_stdout_until_done (fun () -> runtime test test.src) in
      let* out = runtime_result in
      Ok (prefix ^ stdout_output ^ out)
    with e -> 
      Error (RTError, "Runtime error: " ^ Printexc.to_string e)
  else
    (match test.status with
    | NoError -> Ok test.expected
    | _ -> Error (test.status, test.expected))

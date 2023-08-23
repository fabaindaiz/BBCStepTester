

type status =
  | CTError
  | RTError
  | NoError

let status_of_string = function
  | "fail"
  | "RT error" -> RTError
  | "CT error" -> CTError
  | _ -> NoError

let string_of_status = function
  | RTError -> "RT error"
  | CTError -> "CT error"
  | NoError -> "No error"


(** Ocaml representation of test files *)
(* All strings are enforced to be trimmed. *)
(* The expected string *)
type t =
  { name : string
  ; description : string
  ; params : string list
  ; status : status
  ; src : string
  ; expected : string }


type runtime =
| CRuntime of (t -> string -> (string, status * string) result)

type compiler =
| CCompiler of (string -> out_channel -> unit)

type oracle =
| Interp of (string -> status * string)
| Expected

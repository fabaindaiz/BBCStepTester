

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


type compiler =
| Compiler of (string -> out_channel -> unit)

type runtime =
| Runtime of (t -> string -> (string, status * string) result)

type oracle =
| Interpreter of (string -> status * string)
| Expected

type action =
| CompareOutput
| IgnoreOutput

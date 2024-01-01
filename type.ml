type status =
  | CTError
  | RTError
  | NoError

let status_of_string = function
  | "CT error" -> CTError
  | "fail" | "RT error" -> RTError
  | _ -> NoError

let string_of_status = function
  | CTError -> "CT error"
  | RTError -> "RT error"
  | NoError -> "No error"


(** Ocaml representation of test files *)
(* All strings are enforced to be trimmed. *)
(* The expected string *)
type t =
  { file : string
  ; name : string
  ; description : string
  ; params : string list
  ; status : status
  ; src : string
  ; expected : string }


let (let*) = Result.bind

type compiler =
| Compiler of (t -> string -> (string, status * string) result)
| SCompiler of (t -> string -> string)

type runtime =
| Runtime of (t -> string -> (string, status * string) result)

type testeable =
| Testeable of (t -> (status * string) Alcotest.testable)

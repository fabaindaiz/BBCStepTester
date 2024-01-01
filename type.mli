

(** Expected status of a test *)
type status =
  | CTError
    (** Compile-time error *)
  | RTError
    (** Run-time error *)
  | NoError
    (** No error *)


(** Conversion functions between string and status *)

(** [status_of_string s] accepts the following strings s :
    - "fail", "RT error"  <-> RTError
    - "CT error"  <-> CTError
    - anything else correspond to NoError *)
val status_of_string : string -> status

val string_of_status : status -> string


(** Ocaml representation of test files
    All strings are enforced to be trimmed.
 *)
type t =
  { file : string
    (** Name of the test file *)
  ; name : string
    (** Name of the test *)
  ; description : string
    (** Description of the test *)
  ; params : string list
    (** Parameters passed to the test as environment variables *)
  ; status : status
    (** Expected status of the result *)
  ; src : string
    (** Source program for the test *)
  ; expected : string
    (** expected result of the test *) }


val ( let* ) : ('a, 'b) result -> ('a -> ('c, 'b) result) -> ('c, 'b) result


(** A compiler is a function that takes a source program as a string, and 
an output channel as a sink to output the compiled program  *)
type compiler =
| Compiler of (t -> string -> (string, status * string) result)
| SCompiler of (t -> string -> string)

type runtime =
| Runtime of (t -> string -> (string, status * string) result)

type testeable =
| Testeable of (t -> (status * string) Alcotest.testable)

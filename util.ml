open Type


(** Helper functions on strings and processes *)
let filter_lines pred s =
  CCString.split ~by:"\n" s
  |> List.filter pred
  |> String.concat "\n"

let is_comment_line s =
  not (CCString.prefix ~pre:"|" s)

let process_output out =
  String.trim out |> filter_lines is_comment_line


let string_match =
  let open Alcotest in
  let matches pat s =
    try let _ = Str.(search_forward (regexp pat) s 0) in true
    with Not_found -> false
  in
  testable (pp string) matches

let status_match =
  let open Alcotest in
  let matches _ _ = true in
  testable (pp string) matches


let status =
  let open Alcotest in
  testable Fmt.(using string_of_status string) (=)


(** Test pairs giving access to the first component when testing the second component *)
let dep_pair : type a b. a Alcotest.testable -> (a -> b Alcotest.testable) -> (a * b) Alcotest.testable =
  fun cmp1 cmp2 ->
  let open Alcotest in
  let cmp_pair (x1, x2) (y1, y2) = equal cmp1 x1 y1 && equal (cmp2 x1) x2 y2 in
  testable (fun fmt p -> pp (pair cmp1 (cmp2 (fst p))) fmt p) cmp_pair


(* Testing the result of running a test *)
let compare_results =
  let cmp_res = function
    | NoError -> Alcotest.string
    | _ -> string_match
  in
  dep_pair status cmp_res

let execute_results =
  let exe_res = function
    | _ -> status_match
in
  dep_pair status exe_res

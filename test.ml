open Type
open Util


let test_regexp =
  Str.regexp "NAME:\\|DESCRIPTION:\\|PARAMS:\\|STATUS:\\|SRC:\\|EXPECTED:\\|END"

let read_test filename =
  if Sys.file_exists filename
  then
    let content = CCIO.(with_in filename read_all) in
    let open Str in
    let get_opt s dflt = function
      | Delim s' :: Text content :: rest when s = s' ->
        String.trim content, rest
      | all -> dflt, all
    in
    let toks = full_split test_regexp content in
    let name, toks = get_opt "NAME:" Filename.(chop_extension @@ basename filename) toks in
    let description, toks = get_opt "DESCRIPTION:" "" toks in
    let params, toks =
      let params_string, toks = get_opt "PARAMS:" "" toks in
      String.(List.map trim @@ split_on_char ',' params_string), toks
    in
    let status, toks = get_opt "STATUS:" "ok" toks in
    match toks with
    | Delim "SRC:" :: Text src ::
      Delim "EXPECTED:" :: Text expected :: ( [] | Delim "END" :: _ ) ->
      Some { name ; description ; params ; status = status_of_string status ;
           src ; expected = String.trim expected }
    | _ ->
      (Printf.fprintf stderr "Wrong format in test file %s" filename ; None)
  else
    (Printf.fprintf stderr "Test file %s not found." filename ; None)


let (let*) = Result.bind


let make_test
    ~(compiler : compiler)
    ~(oracle : oracle)
    ~(runtime : runtime)
    ~(action : action)
    (filename : string) =
  match read_test filename with
  | None -> Alcotest.failf "Could not open or parse test %s" filename
  | Some test ->
    let exec () =
      let base = Filename.chop_extension filename in

      let res =
        let* () =
          match compiler with
          | Compiler compiler ->
            try Ok (CCIO.with_out (base ^ ".s") (compiler test.src))
            with e -> Error (CTError, Printexc.to_string e)
        in
        match runtime with
        | Runtime runtime -> (runtime test filename)
      in

      let res = 
        match res with
        | Ok out -> NoError, out
        | Error err -> err
      in

      let expected =
        let i_interp = CCString.find ~sub:"|INTERP" test.expected in
        match oracle with
        | Interp oracle when test.status = NoError && i_interp <> -1 ->
          let prefix = CCString.sub test.expected 0 (max (i_interp - 1) 0) in
          let status , output = oracle test.src in
          status , prefix ^ output
        | _ -> test.status, test.expected
      in

      let check_fun =
        match action with
        | Compare -> compare_results
        | Execute -> execute_results
      in

      let open Alcotest in
      check check_fun test.name expected res

    in test.name, exec


let testfiles_in_dir dir =
  CCUnix.with_process_in ("find " ^ dir ^ " -name '*.bbc'") ~f:CCIO.read_lines_l

let name_from_file filename =
  let open Filename in
  dirname filename ^ "::" ^ basename (chop_extension filename)


let tests_from_dir ~name ~compiler ~oracle ~runtime ~action dir =
  let open Alcotest in
  let to_test testfile =
    let testname, exec_test = make_test ~compiler ~oracle ~runtime ~action testfile in
    name_from_file (name ^ "::" ^ testfile), [test_case testname `Quick exec_test]
  in
  List.map to_test @@ testfiles_in_dir dir
  |> CCList.sort (fun (s1,_) (s2,_) -> String.compare s1 s2)

(* Use as follow: *)
(* run "Tests" @@ List.map tests_from_dir [ "failing"; "tests"] *)

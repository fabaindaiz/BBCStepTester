open Type


let make_test
    ~(compiler : compiler)
    ~(runtime : runtime)
    ~(oracle : runtime)
    ~(testeable : testeable)
    (filename : string) =
  match Test.read_test filename with
  | None -> Alcotest.failf "Could not open or parse test %s" filename
  | Some test ->
    let exec () =
      let res =
        Util.handle_result @@
        let* out = Pipeline.compile compiler test in
        let* out = Pipeline.runtime runtime test out in
        Ok out
      in

      let exp =
        Util.handle_result @@
        let* out = Pipeline.oracle oracle test in
        Ok out
      in

      let testing = Pipeline.test testeable test in

      let open Alcotest in
      check testing test.name exp res

    in test.name, exec


  let testfiles_in_dir dir =
    CCUnix.with_process_in ("find " ^ dir ^ " -name '*.bbc'") ~f:CCIO.read_lines_l
  
  let name_from_file filename =
    let open Filename in
    dirname filename ^ "::" ^ basename (chop_extension filename)
  
  
  let tests_from_dir ~name ~compiler ~runtime ~oracle ~testeable dir =
    let open Alcotest in
    let to_test testfile =
      let testname, exec_test = make_test ~compiler ~runtime ~oracle ~testeable testfile in
      name_from_file (name ^ "::" ^ testfile), [test_case testname `Quick exec_test]
    in
    List.map to_test @@ testfiles_in_dir dir
    |> CCList.sort (fun (s1,_) (s2,_) -> String.compare s1 s2)
  
  (* Use as follow: *)
  (* run "Tests" @@ List.map tests_from_dir [ "failing"; "tests"] *)
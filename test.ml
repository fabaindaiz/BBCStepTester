open Type


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
      Some { file=filename ; name ; description ; params ; status = status_of_string status ;
           src ; expected = String.trim expected }
    | _ ->
      (Printf.fprintf stderr "Wrong format in test file %s" filename ; None)
  else
    (Printf.fprintf stderr "Test file %s not found." filename ; None)

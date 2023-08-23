open Type


(** [read_test s] parses the content of a test file provided in the string s
    returns None if any error occurred while reading the file (prints to stderr)

    The file format is composed of a few sections that appear in the following order:
    - `NAME:` [optional, default empty] : the name of the test
    - `DESCRIPTION:` [optional, default empty] : a longer description of the content of the test
    - `PARAMS:` [optional, default empty] : a `,`-separated list of pairs `VAR=VAL` that are adde to the environment variables of the compiled executable
    - `STATUS:` [optional, default `No error`] : either `CT error` (compile time error), `RT error` (runtime error) or `No error`/ Needs to be set to the appropriate error if the program is expected to fail either at compile time or at runtime. In that case the content of `EXPECTED:` is interpreted as a pattern (see [Str](https://caml.inria.fr/pub/docs/manual-ocaml/libref/Str.html)) matched against the output of the failing phase.
    - `SRC:` : the source of the program def to the compiler
    - `EXPECTED:` : the expected result of the program (note that debugging messages starting by `|` are ignored and shouldn't be part of the expected result). If the expected result ends with the message `|INTERPRET` then the expected result is obtained by subsituting `|INTERPRET` with the result of evaluating the interpreter on the source code.
 *)
val read_test : string -> t option


(** [testfiles_in_dir path] collects the content of all thet `*.bbc` files
    found at [path]; uses `find` (GNU findutils) *)
val testfiles_in_dir : string -> string list

(** [test_from_dir ~runtime ~compiler dir] generates alcotest tests
    for each test file present in [dir] and its subdirectories using
    [runtime] as path to a C runtime to be linked against and [compiler]
    to process the sources.
    [compile_flags] are passed to the C compiler (clang),
    defaulting to "-g".
    The optional [oracle] parameter is an oracle (eg. an interpreter, reference compiler) to be invoked on source files.
    It should return a result status together with the expected output of the corresponding program,
    that will be substituted in the first mention of `|ORACLE` in a test file, if any. *)
 val tests_from_dir :
  compiler:compiler ->
  oracle:oracle ->
  runtime:runtime ->
  string -> (string * unit Alcotest.test_case list) list

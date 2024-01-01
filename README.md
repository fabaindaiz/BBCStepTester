# BBCTester
Black-Box Compiler Tester

A simple library for black-box testing of compilers from the [Compiler Design and Implementation course at UChile](https://users.dcc.uchile.cl/~etanter/CC5116/).

## Fork goals
Original BBCTester runs a complete pipeline for an x86 assembly compiler and execution with a c runtime. This fork adds the possibility to configure or modify the steps that will be executed in the pipeline to be able to use BBCTester in other test pipelines for ocaml compilers.

## Future goals
- Improve pipeline & test configurations
- Add benchmarking capabilities to tests

## Dependencies
- dune (>= 3.10)
- ocaml (>= 4.08.0)
- alcotest (>= 1.2.2)
- containers (>= 3.0.1)

## Installation


Download the sources as a zip archive, unzip and install the package
```bash
$ unzip BBCStepTester-main.zip
Archive:  BBCStepTester-main.zip
0e3ce14f8587aafdcc6f64c07de0c2e3c2fde838
   creating: BBCStepTester-main/
  inflating: BBCStepTester-main/.gitignore  
  inflating: BBCStepTester-main/Makefile  
  inflating: BBCStepTester-main/README.md  
  inflating: BBCStepTester-main/dune  
  inflating: BBCStepTester-main/dune-project  
  inflating: BBCStepTester-main/main.ml  
  inflating: BBCStepTester-main/main.mli  
  inflating: BBCStepTester-main/pipeline.ml  
  inflating: BBCStepTester-main/runtime.ml  
  inflating: BBCStepTester-main/test.ml  
  inflating: BBCStepTester-main/test.mli  
  inflating: BBCStepTester-main/testeable.ml  
  inflating: BBCStepTester-main/type.ml  
  inflating: BBCStepTester-main/type.mli  
  inflating: BBCStepTester-main/util.ml

$ cd BBCStepTester-main

$ make install
dune build
dune install         
Installing ...
```

Alternatively, you can clone the repository and install
```bash
$ git clone https://github.com/fabaindaiz/BBCStepTester
Cloning into 'BBCStepTester'...
remote: Enumerating objects: 81, done.
remote: Counting objects: 100% (81/81), done.
remote: Compressing objects: 100% (55/55), done.
remote: Total 81 (delta 48), reused 51 (delta 25), pack-reused 0
Receiving objects: 100% (81/81), 17.79 KiB | 17.79 MiB/s, done.
Resolving deltas: 100% (48/48), done.

$ cd BBCStepTester

$ make install
dune build
dune install         
Installing ...

```


# Usage

## Entrypoint

This package contains a few helper functions to parse test files (see below for the format) and generate unit-tests for alcotest. The main entrypoint of the library is the following function (from `main.mli`).

```ocaml
(* Given a [name], a [compiler], a [runtime], a [oracle], a [action] and
  the path [dir] of a directory containing tests files, produces
  unit tests for each test files in [dir]. *)
val tests_from_dir :
  name:string ->
  compiler:compiler ->
  ?runtime:runtime ->
  ?oracle:runtime ->
  ?testeable:testeable ->
  string -> (string * unit Alcotest.test_case list) list
```

```ocaml
(* Example of using tests_from_dir *)
open Bbcsteptester.Type
open Bbcsteptester.Main
open Bbcsteptester.Runtime

(* .......... *)

(* Entry point of tester *)
let () =

  let compiler : compiler = 
    SCompiler ( fun _ s -> (compile_prog (parse_prog (sexp_from_string s))) ) in

  let compile_flags = Option.value (Sys.getenv_opt "CFLAGS") ~default: "-z noexecstack -g -m64 -fPIE -pie" in
  let runtime : runtime = (clangruntime ~compile_flags "rt/sys.c") in
  
  let oracle : runtime = 
    Runtime ( fun _ s -> (
      try Ok (string_of_val (interp_prog (parse_prog (sexp_from_string s)) empty_env))
      with
      | RTError msg -> Error (RTError, msg)
      | CTError msg -> Error (CTError, msg)
      | e -> Error (RTError, "Oracle raised an unknown error :" ^ Printexc.to_string e)
    ))
  in
  
  let bbc_tests =
    let name : string = "bbc" in
    tests_from_dir ~name ~compiler ~runtime ~oracle "bbctests" in
  
  run "Tests MiniCompiler" (ocaml_tests @ bbc_tests)
```


## Tests files (*.bbc)

A BBCTester test file contains both a source program to be fed to the compiler and various metadata to help testing the compiler.
Here is how it looks like:
```
NAME: add1
DESCRIPTION: increments a number

SRC:
(add1 20)

EXPECTED:
21
```


It uses the extension `.bbc` and is composed of a few sections that appear in the following order:
- `NAME:` [optional, default empty] : the name of the test
- `DESCRIPTION:` [optional, default empty] : a longer description of the content of the test
- `PARAMS:` [optional, default empty] : a `,`-separated list of pairs `VAR=VAL` that are added to the environment variables of the compiled executable
- `STATUS:` [optional, default `No error`] : either `CT error` (compile time error), `RT error` (runtime error) or `No error`/ Needs to be set to the appropriate error if the program is expected to fail either at compile time or at runtime. In that case the content of `EXPECTED:` is interpreted as a pattern (see [Str](https://caml.inria.fr/pub/docs/manual-ocaml/libref/Str.html)) matched against the output of the failing phase.
- `SRC:` : the source of the program fed to the compiler
- `EXPECTED:` : the expected result of the program (note that debugging messages starting by `|` are ignored and shouldn't be part of the expected result). If the expected result ends with the message `|ORACLE` then the expected result is obtained by substituting `|ORACLE` with the result of a provided oracle called on the source code.

(*s: parsing2.ml *)
(*s: Facebook copyright *)
(* Yoann Padioleau
 * 
 * Copyright (C) 2010-2012 Facebook
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public License
 * version 2.1 as published by the Free Software Foundation, with the
 * special exception on linking described in file license.txt.
 * 
 * This library is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the file
 * license.txt for more details.
 *)
(*e: Facebook copyright *)

open Common

module FT = File_type

module HC = Highlight_code
module Db = Database_code

open Highlight_code

module PI = Parse_info

(*****************************************************************************)
(* Prelude *)
(*****************************************************************************)

(*****************************************************************************)
(* Parsing helpers *)
(*****************************************************************************)

(* This type is needed if we want to use a single hashtbl to memoize
 * all the parsed file. Having a single hash helps for 
 * disable_file_in_cache below.
 *)
type ast = 
  | ML  of Parse_ml.program2
  | Hs  of Parse_hs.program2

  | Html of Parse_html.program2
  | Js  of Parse_js.program2
  | Php of Parse_php.program2

  | Opa of Parse_opa.program2

  | Cpp of Parse_cpp.program2

  | Csharp of Parse_csharp.program2
  | Java of Parse_java.program2

  | Lisp of Parse_lisp.program2
  | Erlang of Parse_erlang.program2

  | Python of Parse_python.program2

  | Noweb of Parse_nw.program2

  (* less? | Org of Org_mode.org ? *)

let _hmemo_file = Hashtbl.create 101

let parse_hs2 file = 
  Common.memoized _hmemo_file file (fun () -> 
    Hs (Parse_hs.parse file +> fst))
let parse_hs_cache a = 
  Common.profile_code "View.parse_hs_cache" (fun () -> 
    match parse_hs2 a with | Hs a -> a | _ -> raise Impossible
  )

let parse_nw2 file = 
  Common.memoized _hmemo_file file (fun () -> 
    Noweb (Parse_nw.parse file +> fst))
let parse_nw_cache a = 
  Common.profile_code "View.parse_nw_cache" (fun () -> 
    match parse_nw2 a with | Noweb a -> a | _ -> raise Impossible
  )

let parse_lisp2 file = 
  Common.memoized _hmemo_file file (fun () -> 
    Lisp (Parse_lisp.parse file +> fst))
let parse_lisp_cache a = 
  Common.profile_code "View.parse_lisp_cache" (fun () -> 
    match parse_lisp2 a with | Lisp a -> a | _ -> raise Impossible
  )


let parse_php2 file = 
  Common.memoized _hmemo_file file (fun () -> 
    Common.save_excursion Flag_parsing_php.error_recovery true (fun () ->
    let (ast2, stat) = Parse_php.parse file in
    let ast = 
      Parse_php.program_of_program2 ast2 in
    let find_entity = None in
    (* work by side effect on ast2 too *)
    Check_variables_php.check_and_annotate_program
      (* todo: use database_light if given? *)
      find_entity
      ast;
    Php ast2
    )
  )
let parse_php_cache a = 
  Common.profile_code "View.parse_php_cache" (fun () -> 
    match parse_php2 a with | Php a -> a | _ -> raise Impossible
  )

let parse_html2 file = 
  Common.memoized _hmemo_file file (fun () -> 
    Html (Parse_html.parse file))
let parse_html_cache a = 
  Common.profile_code "View.parse_html_cache" (fun () -> 
    match parse_html2 a with | Html a -> a | _ -> raise Impossible
  )

let parse_js2 file = 
  Common.memoized _hmemo_file file (fun () -> 
    Js (Parse_js.parse file +> fst))
let parse_js_cache a = 
  Common.profile_code "View.parse_js_cache" (fun () -> 
    match parse_js2 a with | Js a -> a | _ -> raise Impossible
  )

let parse_python2 file = 
  Common.memoized _hmemo_file file (fun () -> 
    Python (Parse_python.parse file +> fst))
let parse_python_cache a = 
  Common.profile_code "View.parse_python_cache" (fun () -> 
    match parse_python2 a with | Python a -> a | _ -> raise Impossible
  )

let parse_csharp2 file = 
  Common.memoized _hmemo_file file (fun () -> 
    Csharp (Parse_csharp.parse file +> fst))
let parse_csharp_cache a = 
  Common.profile_code "View.parse_csharp_cache" (fun () -> 
    match parse_csharp2 a with | Csharp a -> a | _ -> raise Impossible
  )

let parse_opa2 file = 
  Common.memoized _hmemo_file file (fun () -> 
    Opa (Parse_opa.parse file +> fst))
let parse_opa_cache a = 
  Common.profile_code "View.parse_opa_cache" (fun () -> 
    match parse_opa2 a with | Opa a -> a | _ -> raise Impossible
  )


let parse_erlang2 file = 
  Common.memoized _hmemo_file file (fun () -> 
    Erlang (Parse_erlang.parse file +> fst))
let parse_erlang_cache a = 
  Common.profile_code "View.parse_erlang_cache" (fun () -> 
    match parse_erlang2 a with | Erlang a -> a | _ -> raise Impossible
  )

let parse_java2 file = 
  Common.memoized _hmemo_file file (fun () -> 
    Java (Parse_java.parse file +> fst))
let parse_java_cache a = 
  Common.profile_code "View.parse_java_cache" (fun () -> 
    match parse_java2 a with | Java a -> a | _ -> raise Impossible
  )

let parse_cpp2 file = 
  Common.memoized _hmemo_file file (fun () -> 
    let (ast2, stat) = Parse_cpp.parse file in
    let ast = Parse_cpp.program_of_program2 ast2 in
    (* work by side effect on ast2 too *)
    Check_variables_cpp.check_and_annotate_program
      ast;
    Cpp ast2
  )
let parse_cpp_cache a = 
  Common.profile_code "View.parse_cpp_cache" (fun () -> 
    match parse_cpp2 a with | Cpp a -> a | _ -> raise Impossible
  )


let disable_file_in_cache file =
  Hashtbl.remove _hmemo_file file

let parse_cache parse_in extract file =
  Common.profile_code "View.parse_cache" (fun () ->
    let ast = Common.memoized _hmemo_file file (fun () -> parse_in file) in
    extract ast
  )

(*****************************************************************************)
(* Semantic ehancement *)
(*****************************************************************************)

let use_arity_of_use_count n =
  match () with
  (* note that because my PHP object analysis have some threshold
   * on the number of callers (see threshold_callers_indirect_db)
   * the number for HugeUse can not be more than this one otherwise
   * you will miss some cases
   *)
  | _ when n >= 100 -> HugeUse

  | _ when n > 20 -> LotsOfUse
  | _ when n >= 10  -> MultiUse
  | _ when n >= 2 -> SomeUse
  | _ when n = 1 -> UniqueUse
  | _ -> NoUse

let rewrite_categ_using_entities s categ file entities =

  let e_kind_opt = 
    try Some (Db.entity_kind_of_highlight_category_def categ)
    with _ -> None
  in
  match e_kind_opt with
  | None -> categ
  | Some e_kind ->

  
   let entities = 
    Hashtbl.find_all entities s +> List.filter (fun e ->
      (* we could have the full www dbcode but run the treemap on
       * a subdir in which case the root will not be the same.
       * It's a good approximation to just look at the basename.
       * The only false positive we will get if another file,
       * with the same name happened to also define entities
       * with the same name, which would be rare.
       * 
       * update: TODO use Model2.readable_to_absolute_filename_under_root ?
       *)
      Filename.basename e.Db.e_file =$= Filename.basename file &&
      (* some file have both a function and class with the same name *)
      e.Db.e_kind =*= e_kind
    )
  in
  match entities with
  | [] -> categ
  | [e] ->
      let use_cnt = e.Db.e_number_external_users in
      let arity = use_arity_of_use_count use_cnt in
      if HC.is_entity_def_category categ
      then HC.rewrap_arity_def2_category arity categ 
      else categ
  | x::y::xs ->
      (* TODO: handle __construct directly *)
      if not (List.mem s ["__construct"])
      then
        pr2_once (spf "multi def found for %s in %s" s file);
      categ

let tokens_with_categ_of_file_helper ~parse ~highlight_visit 
  ~info_of_tok ~str_of_tok file prefs hentities =
  
  let h = Hashtbl.create 101 in
  let ast2 = parse file in
  ast2 +> List.map (fun (ast, (_str, toks)) ->

    (* computing the token attributes *)
    highlight_visit ~tag_hook:(fun info categ -> Hashtbl.add h info categ)
      prefs (ast, toks);

    (* getting the text *)
    toks +> Common.map_filter (fun tok -> 
      let info = info_of_tok tok in
      let s = str_of_tok tok in
      if not (Parse_info.is_origintok info)
      then None
      else 
        let categ = Common.hfind_option info h +> Common.fmap (fun categ ->
          rewrite_categ_using_entities s categ file hentities
        ) in
        Some (s, categ,{ l = PI.line_of_info info; c = PI.col_of_info info; })
    )) +> List.flatten

(*****************************************************************************)
(* Main entry point *)
(*****************************************************************************)

(* coupling: right now if you add a language here, you need to whitelist it
 * also in draw_microlevel.draw_contents2.
 *)
let tokens_with_categ_of_file file hentities = 
  let ftype = FT.file_type_of_file file in
  let prefs = Highlight_code.default_highlighter_preferences in

  match ftype with
  | FT.PL (FT.Web (FT.Php _)) ->
      tokens_with_categ_of_file_helper 
        ~parse:parse_php_cache
        ~highlight_visit:(fun ~tag_hook prefs (ast, toks) ->
          Highlight_php.visit_toplevel ~tag:tag_hook prefs hentities (ast,toks))
        ~info_of_tok:Token_helpers_php.info_of_tok
        ~str_of_tok:Token_helpers_php.str_of_tok
        file prefs hentities

  | FT.PL (FT.ML _) ->
      tokens_with_categ_of_file_helper 
        ~parse:(parse_cache 
         (fun file -> 
           Common.save_excursion Flag_parsing_ml.error_recovery true (fun()->
             ML (Parse_ml.parse file +> fst))
         )
         (function ML x -> x | _ -> raise Impossible))
        ~highlight_visit:(fun ~tag_hook prefs (ast, toks) -> 
          Highlight_ml.visit_toplevel ~tag_hook prefs (ast, toks))
        ~info_of_tok:Token_helpers_ml.info_of_tok
        ~str_of_tok:Token_helpers_ml.str_of_tok
        file prefs hentities

  | FT.PL (FT.Haskell _) ->
      tokens_with_categ_of_file_helper 
        ~parse:parse_hs_cache
        ~highlight_visit:(fun ~tag_hook prefs (ast, toks) -> 
          Highlight_hs.visit_toplevel ~tag_hook prefs (ast, toks))
        ~info_of_tok:Parser_hs.info_of_tok
        ~str_of_tok:Parser_hs.str_of_tok
        file prefs hentities

  | FT.PL (FT.Python) ->
      tokens_with_categ_of_file_helper 
        ~parse:parse_python_cache
        ~highlight_visit:(fun ~tag_hook prefs (ast, toks) -> 
          Highlight_python.visit_toplevel ~tag_hook prefs (ast, toks))
        ~info_of_tok:Token_helpers_python.info_of_tok
        ~str_of_tok:Token_helpers_python.str_of_tok
        file prefs hentities

  | FT.PL (FT.Csharp) ->
      tokens_with_categ_of_file_helper 
        ~parse:parse_csharp_cache
        ~highlight_visit:(fun ~tag_hook prefs (ast, toks) -> 
          Highlight_csharp.visit_toplevel ~tag_hook prefs (ast, toks))
        ~info_of_tok:Token_helpers_csharp.info_of_tok
        ~str_of_tok:Token_helpers_csharp.str_of_tok
        file prefs hentities

  | FT.PL (FT.Opa) ->
      tokens_with_categ_of_file_helper 
        ~parse:parse_opa_cache
        ~highlight_visit:Highlight_opa.visit_toplevel
        ~info_of_tok:Token_helpers_opa.info_of_tok
        ~str_of_tok:Token_helpers_opa.str_of_tok
        file prefs hentities

  | FT.PL (FT.Erlang) ->
      tokens_with_categ_of_file_helper 
        ~parse:parse_erlang_cache
        ~highlight_visit:Highlight_erlang.visit_toplevel
        ~info_of_tok:Token_helpers_erlang.info_of_tok
        ~str_of_tok:Token_helpers_erlang.str_of_tok
        file prefs hentities

  | FT.PL (FT.Java) ->
      tokens_with_categ_of_file_helper 
        ~parse:parse_java_cache
        ~highlight_visit:Highlight_java.visit_toplevel
        ~info_of_tok:Token_helpers_java.info_of_tok
        ~str_of_tok:Token_helpers_java.str_of_tok
        file prefs hentities

  | FT.PL (FT.Lisp _) ->
      tokens_with_categ_of_file_helper 
        ~parse:parse_lisp_cache
        ~highlight_visit:Highlight_lisp.visit_toplevel
        ~info_of_tok:Parser_lisp.info_of_tok
        ~str_of_tok:Parser_lisp.str_of_tok
        file prefs hentities

  | FT.Text ("nw" | "tex" | "texi" | "web") ->
      tokens_with_categ_of_file_helper 
        ~parse:parse_nw_cache
        ~highlight_visit:Highlight_nw.visit_toplevel
        ~info_of_tok:Token_helpers_nw.info_of_tok
        ~str_of_tok:Token_helpers_nw.str_of_tok
        file prefs hentities

  | FT.PL (FT.Cplusplus _ | FT.C _ | FT.Thrift) ->
      tokens_with_categ_of_file_helper 
        ~parse:parse_cpp_cache
        ~highlight_visit:Highlight_cpp.visit_toplevel
        ~info_of_tok:Token_helpers_cpp.info_of_tok
        ~str_of_tok:Token_helpers_cpp.str_of_tok
        file prefs hentities

  | FT.PL (FT.Web (FT.Js _)) ->
      tokens_with_categ_of_file_helper 
        ~parse:parse_js_cache
        ~highlight_visit:Highlight_js.visit_toplevel
        ~info_of_tok:Token_helpers_js.info_of_tok
        ~str_of_tok:(fun tok -> 
          let s = Token_helpers_js.str_of_tok tok in
          Ast_js.remove_quotes_if_present s
        )
        file prefs hentities

  | FT.PL (FT.Web (FT.Html)) ->
      tokens_with_categ_of_file_helper 
        ~parse:(fun file -> 
          let (ast, toks) = parse_html_cache file in
          [ast, ("", toks)]
        )
        ~highlight_visit:Highlight_html.visit_toplevel
        ~info_of_tok:Token_helpers_html.info_of_tok
        ~str_of_tok:Token_helpers_html.str_of_tok
        file prefs hentities

  | FT.Text ("org") ->
      let org = Org_mode.parse file in
      Org_mode.highlight org

  | _ -> failwith 
      "impossible: should be called only when file has good file_kind"
(*e: parsing2.ml *)

(* 2015, Mike Shema <mps@yahoo-inc.com> *)

module J = Json_type

type metavar_match_t = {
  metavar: string;
  regex: Str.regexp;
}

type pattern_info_t = {
  name: string;
  version: string;
  langs: string list;
  pattern: string;
  pattern_reject: string;
  metavar_match: metavar_match_t list;
}

module Sgrep_args =
struct
  open Common
  open Json_type.Browse

  let empty_pattern =
    { name = ""; version = ""; langs = [];
      pattern = ""; pattern_reject = "";
      metavar_match = [] }

  let extract_langs json =
    match json with
    | J.Array _ ->
      let a = array json in
      List.map string a
    | J.String _ ->
      [string json]
    | _ ->
      failwith "expected an array"

  let extract_metavar_match mm =
    let mvars json =
      match json with
      | J.Object _ ->
        let tbl = make_table (objekt json) in
        let entries =
          Hashtbl.fold (fun k v acc -> (k, v) :: acc) tbl [] in
        entries +> List.map (fun (k, v) ->
          {
            metavar = k;
            regex = Str.regexp (string v);
          }
        )
      | _ ->
        failwith "expected an object of {\"X\": \"regex\"}"
    in
    match mm with
    | None -> []
    | Some mm -> mvars mm

  let rec extract_pattern json =
    match json with
    | J.Object _ ->
      let tbl = make_table (objekt json) in
      extract_pattern (field tbl "pattern")
    | J.String _ ->
      string json
    | J.Array a ->
      (* MPS: for now we only support an array of a single pattern *)
      string (List.hd a)
    | _ ->
      failwith "invalid pattern object"

  let extract_version json =
    match json with
    | J.String _ ->
      string json
    | J.Int _ ->
      string_of_int (int json)
    | _ ->
      failwith "invalid version"

  let langs_list_or_nothing s =
    let synonyms l =
      match l with
      | "javascript" -> "js"
      | _ -> l
    in
    match s with
    | None -> []
    | Some s -> List.map synonyms (extract_langs s)

  let string_or_nothing s =
    match s with
    | None -> ""
    | Some s -> string s

  let create_pattern_info json =
    match json with
    | J.Object _ ->
      let tbl = make_table (objekt json) in
      {
        name = string (field tbl "name");
        version = extract_version (field tbl "version");
        langs = langs_list_or_nothing (optfield tbl "lang");
        pattern = extract_pattern (field tbl "pattern");
        pattern_reject = string_or_nothing (optfield tbl "pattern_reject");
        metavar_match = extract_metavar_match (optfield tbl "metavar_match");
      }
    | _ ->
      failwith "invalid object"

  let extract_plugins json =
    match json with
    | J.Array _ ->
      let a = array json in
      List.map create_pattern_info a
    | J.Object _ ->
      [create_pattern_info json]
    | _ ->
      failwith "not an array or object"

  let rec print_patterns json =
    match json with
    | J.Array _ ->
      let a = array json in
      List.iter print_patterns a
    | J.Object _ ->
      pr ("pattern is " ^ (extract_pattern json))
    | _ ->
      failwith "no pattern"

  let read_json_plugins ?(verbose = false) file =
    let json = Json_in.load_json file in
    if verbose then (
      let s = Json_io.string_of_json json in
      pr s;
      print_patterns json;
    );
    extract_plugins json
end


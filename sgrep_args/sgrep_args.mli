(* 2015, Mike Shema <mps@yahoo-inc.com> *)

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

module Sgrep_args :
sig
  val empty_pattern: pattern_info_t

  val read_json_plugins: ?verbose:bool -> string -> pattern_info_t list
end


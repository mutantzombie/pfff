type match_format =
  (* ex: tests/misc/foo4.php:3
   *  foo(
   *   1,
   *   2);
   *)
  | Normal
  (* ex: tests/misc/foo4.php:3: foo( *)
  | Emacs
  (* ex: Normal as encoded in JSON *)
  | Json
  (* ex: tests/misc/foo4.php:3: foo(1,2) *)
  | OneLine

val print_match: ?format:match_format -> ?info:Sgrep_args.pattern_info_t -> Parse_info.info list -> unit
val join_with_space_if_needed: string list -> string

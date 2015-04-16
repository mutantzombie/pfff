Sgrep arguments in JSON format
----




Input
----
The input may be a single pattern blob or an array.

````json
{
  "name" : "foo",
  "lang": ["php"],
  "version": 1,
  "pattern": "foo"
}
````

As an array...
````json
[
  {
    "name" : "foo",
    "lang": ["php"],
    "version": 1,
    "pattern": "foo"
  },
  {
    "name" : "bar",
    "lang": ["php"],
    "version": "1.0",
    "pattern": "bar"
  }
]
````

With pattern matches against metavars...
````json
  {
    "name" : "bar",
    "lang": "php",
    "version": 1,
    "pattern": "X(bar)",
    "metavar_match": {"X": "urldecode"}
  }
````

Input Field Notes
----
`name` requires a string. This is the free-form name of the detection.

`lang` may be a string or an array of strings. Sgrep uses this to filter patterns to match the language of the target file. If this is omitted, then the pattern will be considered to match any langauge.

`version` may be a string or an integer.

`pattern` may be a string or a single-element array of strings. Multiple patterns are not currently supported. Create multiple objects to accommodate each desired pattern.

`metavar_match` is optional. It is an object of `{"metavar": "regex"}` in which the `regex` is to be applied to the metavar result that sgrep maps to `metavar`. Not that the regex must be compatible with Ocaml Regular expression syntax; it is not a full-fledged PCRE syntax.

Output
----
````json
{
  "name": "bar",
  "version": 1,
  "file": "/Users/mike/src/pfff/tests/php/unsugar/xhp.php",
  "linenum": 5,
  "start_column": 17,
  "end_column": 17,
  "linetext": [ "    return self::BAR;" ]
}
````


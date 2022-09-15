defmodule ScimParser do
  @external_resource "priv/scim.abnf"

  use AbnfParsec,
    abnf_file: "priv/scim.abnf",
    transform: %{
      "ATTRNAME" => {:reduce, {List, :to_string, []}},
      "string" => {:reduce, {List, :to_string, []}},
      "NOT" => {:reduce, {List, :to_string, []}},
      "AND-OR" => {:reduce, {List, :to_string, []}}
      #
    },
    ignore: [
      "quotation-mark"
    ],
    unbox: [
      "NOT",
      "AND-OR",
      "nameChar",
      "json-char",
      "unescaped",
      "string",
      "ATTRNAME",
      "subAttr",
      #
      "unreserved",
      "pchar"
    ]
end

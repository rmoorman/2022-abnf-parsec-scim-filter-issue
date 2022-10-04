defmodule ScimParser do
  @external_resource "priv/scim.abnf"

  use AbnfParsec,
    abnf_file: "priv/scim.abnf",
    transform: %{
      "string" => {:reduce, {List, :to_string, []}},
      "true" => {:replace, true},
      "false" => {:replace, false},
      "null" => {:replace, nil},
      "schema-uri" => [{:reduce, {List, :to_string, []}}, {:map, {String, :trim_trailing, [":"]}}],
      "ATTRNAME" => {:reduce, {List, :to_string, []}},
      "NOT" => {:reduce, {List, :to_string, []}},
      "AND-OR" => {:reduce, {List, :to_string, []}},
      "compKeyword" => {:reduce, {List, :to_string, []}},
      "subAttr" => {:post_traverse, {:extract_subname, []}}
    },
    ignore: [
      "ws",
      "quotation-mark",
      "grouping-start",
      "grouping-end",
      "attribute-filter-start",
      "attribute-filter-end"
    ],
    # convert values like `{:def, ["value"]}` to `"value"`
    # (removing the wrapping of the value in a list and a tagged tuple)
    unbox: [
      "string",
      "true",
      "false",
      "null",
      "nameChar",
      "json-char",
      "unescaped",
      "digit1-9",
      "zero",
      "decimal-point",
      "e",
      "schema-uri-part",
      "schema-uri-sep",
      "FILTER",
      "scim-rfc-path",
      "valFilter"
    ],
    # convert things like `{:def, ["value"]}` to `{:def, "value"}`
    # (removing the wrapping of the value in a list)
    unwrap: [
      "NOT",
      "AND-OR",
      "compKeyword",
      "compValue",
      "compareOp",
      "presentOp",
      "schema-uri",
      "ATTRNAME",
      "subAttr"
    ]

  # convert `{:subattr, [".", {:attrname, "familyName"}]}` to `{:subattr, ["familyName"]}`
  defp extract_subname(rest, [{:attrname, name}, "."], context, _line, _offset) do
    {rest, [name], context}
  end
end

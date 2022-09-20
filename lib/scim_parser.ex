defmodule ScimParser do
  @external_resource "priv/scim.abnf"

  use AbnfParsec,
    abnf_file: "priv/scim.abnf",
    transform: %{
      "schema-uri" => [{:reduce, {List, :to_string, []}}, {:map, {String, :trim_trailing, [":"]}}],
      "ATTRNAME" => {:reduce, {List, :to_string, []}},
      "string" => {:reduce, {List, :to_string, []}},
      "NOT" => {:reduce, {List, :to_string, []}},
      "AND-OR" => {:reduce, {List, :to_string, []}},
      "subAttr" => {:post_traverse, {:extract_subname, []}},
      "compareOp" => {:post_traverse, {:lc_compareop, []}},
      "number" => {:post_traverse, {:extract_number, []}},
      "attrExp" => {:post_traverse, {:clean_attrexp, []}},
      "FILTER" => {:post_traverse, {:clean_filter, []}}
    },
    ignore: [
      "quotation-mark"
    ],
    unbox: [
      # "NOT",
      # "AND-OR",
      "nameChar",
      "json-char",
      "unescaped",
      "string",
      "digit1-9",
      "decimal-point",
      "number",
      # flatten schema uri parts
      "schema-uri-part",
      "schema-uri-sep"
    ],
    unwrap: [
      "NOT",
      "AND-OR",
      "compValue",
      "compareOp",
      "attrExp",
      "FILTER",
      # convert `{:schema_uri, [""]}` to `{:schema_uri, ""}`
      "schema-uri",
      # convert `{:attrname, ["name"]}` to `{:attrname, "name"}`
      "ATTRNAME",
      # convert `{:subattr, ["familyName"]}` (result from the `:post_traverse`
      # on `subAttr`) to `{:subattr, "familyName"}`
      "subAttr"
    ]

  # convert `{:subattr, [".", {:attrname, "familyName"}]}` to `{:subattr, ["familyName"]}`
  defp extract_subname(rest, [{:attrname, name}, "."], context, _line, _offset) do
    {rest, [name], context}
  end

  # lowercase compareOp values
  defp lc_compareop(rest, [op], context, _line, _offset) do
    {rest, [String.downcase(op)], context}
  end

  # convert `{:number, [minus: '-', int: '1', frac: [{:decimal_point, '.'}, 52]]}` to `{:number, [-1.52]}`
  defp extract_number(rest, [frac: frac, int: int, minus: '-'], context, _line, _offset) do
    {rest, [Decimal.new("-#{int}#{frac}")], context}
  end

  defp extract_number(rest, [frac: frac, int: int], context, _line, _offset) do
    {rest, [Decimal.new("#{int}#{frac}")], context}
  end

  defp extract_number(rest, [int: int], context, _line, _offset) do
    {rest, [Decimal.new("#{int}")], context}
  end

  defp clean_attrexp(rest, attrexp, context, _line, _offset) do
    {rest, [attrexp |> Enum.reject(fn x -> x == " " end) |> Enum.reverse()], context}
  end

  defp clean_filter(rest, filter, context, _line, _offset) do
    {rest,
     [
       filter
       |> Enum.reject(fn x -> x in [" ", "(", ")"] end)
       |> Enum.reverse()
     ], context}
  end
end

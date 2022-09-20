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
      "compKeyword" => {:reduce, {List, :to_string, []}},
      "subAttr" => {:post_traverse, {:extract_subname, []}},
      "compareOp" => {:post_traverse, {:lc_compareop, []}},
      "number" => {:post_traverse, {:extract_decimal, []}}
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
      "nameChar",
      "json-char",
      "unescaped",
      "string",
      "digit1-9",
      "zero",
      "decimal-point",
      "e",
      "number",
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
      "schema-uri",
      "ATTRNAME",
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

  # convert `{:number, [minus: '-', int: '1', frac: '.52']]}` to `{:number, [-1.52]}`
  defp extract_decimal(rest, opts, context, _line, _offset) do
    int = Keyword.get(opts, :int)
    frac = Keyword.get(opts, :frac)
    minus = Keyword.get(opts, :minus)

    exp =
      Keyword.get(opts, :exp)
      |> case do
        [?e, {:minus, '-'} | rest] -> [?e, '-' | rest]
        [?e, {:plus, '+'} | rest] -> [?e, '+' | rest]
        other -> other
      end

    decimal = Decimal.new("#{minus}#{int}#{frac}#{exp}")

    {rest, [decimal], context}
  end
end

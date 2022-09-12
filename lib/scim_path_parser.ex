defmodule ScimPathParser do
  use AbnfParsec, [
    abnf_file: "priv/scim.abnf",
    #transform: %{
    #  "ATTRNAME" => {:reduce, {List, :to_string, []}},
    #  "string" => {:reduce, {List, :to_string, []}},
    #},
    #ignore: [
    #  "quotation-mark",
    #],
    #unbox: [
    #  "nameChar",
    #  "json-char",
    #  "unescaped",
    #  "string",
    #  "ATTRNAME",
    #  "subAttr",
    #],
    parse: :scim_path,
  ]
end

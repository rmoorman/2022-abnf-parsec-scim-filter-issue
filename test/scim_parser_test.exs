defmodule ScimParserTest do
  use ParserCase

  @filter_rules [
    # filter rules (from spec)
    ~s|userName Eq "john"|,
    ~s|Username eq "john"|,
    ~s|userName eq "bjensen"|,
    ~s|name.familyName co "O'Malley"|,
    ~s|userName sw "J"|,
    ~s|urn:ietf:params:scim:schemas:core:2.0:User:userName sw "J"|,
    ~s|title pr|,
    ~s|meta.lastModified gt "2011-05-13T04:42:34Z"|,
    ~s|meta.lastModified ge "2011-05-13T04:42:34Z"|,
    ~s|meta.lastModified lt "2011-05-13T04:42:34Z"|,
    ~s|meta.lastModified le "2011-05-13T04:42:34Z"|,
    ~s|title pr and userType eq "Employee"|,
    ~s|title pr or userType eq "Intern"|,
    ~s|schemas eq "urn:ietf:params:scim:schemas:extension:enterprise:2.0:User"|,
    ~s|userType eq "Employee" and (emails co "example.com" or emails.value co "example.org")|,
    ~s|userType ne "Employee" and not (emails co "example.com" or emails.value co "example.org")|,
    ~s|userType eq "Employee" and (emails.type eq "work")|,
    ~s|userType eq "Employee" and emails[type eq "work" and value co "@example.com"]|,
    ~s|emails[type eq "work" and value co "@example.com"] or ims[type eq "xmpp" and value co "@foo.com"]|,
    # filter rules (elsewhere, made up, intentionally different)
    ~s|userType eq "Employee" and (emails co "example.com" or emails co "example.org")|,
    ~s|urn:ietf:params:scim:schemas:extension:enterprise:2.0:User:employeeNumber pr|
  ]

  @tag :filter
  for rule <- @filter_rules do
    test "filter rule ~s|#{rule}|" do
      assert {:ok, _result, "" = _rest, _, _, _} = parser_result(:filter, unquote(rule))
    end
  end

  @path_rules [
    # path rules (from spec)
    ~s|members|,
    ~s|name.familyName|,
    ~s|addresses[type eq "work"]|,
    ~s|members[value eq "2819c223-7f76-453a-919d-413861904646"]|,
    ~s|members[value eq "2819c223-7f76-453a-919d-413861904646"].displayName|,
    ~s|emails[type eq "work" and value ew "example.com"]|,
    ~s|addresses[type eq "work"].streetAddress|,
    # other rules (elsewhere, made up, intentionally different)
    ~s|emails[type eq "work"].value|,
    ~s|urn:ietf:params:scim:schemas:extension:enterprise:2.0:User:employeeNumber|,
    ~s|addresses[foo pr]|
  ]

  @tag :path
  for rule <- @path_rules do
    test "path rule ~s|#{rule}|" do
      assert {:ok, _result, "" = _rest, _, _, _} = parser_result(:scim_rfc_path, unquote(rule))
    end
  end

  describe "result of parsing an invalid rule" do
    @rule ~s|urn:ietf:params:scim:schemas:extension:enterprise:2.0:User:employeeNumber|
    test "~s|#{@rule}| used as a filter causes an error" do
      rule = @rule

      assert {
               :error,
               "expected attrexp or valuepath or not, followed by core_sp or nothing, followed by string \"(\", followed by filter, followed by string \")\"",
               ^rule,
               _,
               _,
               _
             } = parser_result(:filter, @rule)
    end

    @rule ~s|adresses[foo]|
    test "~s|#{@rule}| has unparsed rest" do
      assert {:ok, _, "[foo]", _, _, _} = parser_result(:scim_rfc_path, @rule)
    end

    @rule ~s|adresses[zip sw "1234"|
    test "~s|#{@rule}| has unparsed rest" do
      assert {:ok, _, ~s|[zip sw "1234"|, _, _, _} = parser_result(:scim_rfc_path, @rule)
    end

    @rule ~s|(meta.resourceType eq User) or (meta.resourceType eq Group)|
    test "~s|#{@rule}| causes an error" do
      # Even though the spec mentions
      #
      # `(meta.resourceType eq User) or (meta.resourceType eq Group)`
      #
      # as a filter expression (https://www.rfc-editor.org/rfc/rfc7644#page-17)
      # that can be used to restrict resource types, it does not fit the ABNF
      # definition as the matching value (`User` or `Group` in the example)
      # needs to be a valid json string (i.e. quoted)
      #
      # So we expect the parser to return an error on this one.
      #
      # The code using the parser therefore must work around this (e.g.
      # special-casing filters with `meta.resourceType` in them and wrapping
      # the valid resource types in quotes before passing it to the parser)
      rule = @rule

      assert {
               :error,
               "expected ASCII character in the range 'A' to 'Z' or in the range 'a' to 'z'",
               ^rule,
               _,
               _,
               _
             } = parser_result(:scim_rfc_path, @rule)
    end
  end

  describe "result of parsing a valid rule" do
    @rule ~s|userName Eq "john"|
    test "~s|#{@rule}|" do
      expected = [
        filter: [
          attrexp: [
            {:attrpath, ["userName"]},
            " ",
            {:compareop, ["Eq"]},
            " ",
            {:compvalue, ["john"]}
          ]
        ]
      ]

      assert {:ok, ^expected, "", _, _, _} = parser_result(:filter, @rule)
    end

    @rule ~s|name.familyName co "O'Malley"|
    test "~s|#{@rule}|" do
      expected = [
        filter: [
          attrexp: [
            {:attrpath, ["name", ".", "familyName"]},
            " ",
            {:compareop, ["co"]},
            " ",
            {:compvalue, ["O'Malley"]}
          ]
        ]
      ]

      assert {:ok, ^expected, "", _, _, _} = parser_result(:filter, @rule)
    end

    @tag :dev
    @rule ~s|urn:ietf:params:scim:schemas:core:2.0:User:userName sw "J"|
    test "~s|#{@rule}|" do
      # parse
      result = parser_result(:filter, @rule)

      # extract value that I would like to reduce to a ":" seperated list or a
      # string (the segments of the uri)
      {:ok,
       [
         filter: [
           attrexp: [
             {:attrpath,
              [
                uri: [
                  _scheme,
                  ":",
                  {:hier_part,
                   [
                     path_rootless: [
                       segment_nz: segment_nz
                     ]
                   ]}
                ]
              ]},
             " ",
             _compareop,
             " ",
             _comvalue
           ]
         ]
       ], _, _, _, _} = result

      IO.inspect(segment_nz)
      IO.inspect(segment_nz |> List.to_string())

      # expected = [
      #  filter: [
      #    attrexp: [
      #      {:attrpath, [{:uri, ["urn", ":", "ietf", ":", "params", ":", "scim", ":", "schemas", ":", "core", ":", "2.0", ":", "User", ":", "userName"]}]},
      #      " ",
      #      {:compareop, ["sw"]},
      #      " ",
      #      {:compvalue, ["J"]},
      #    ]
      #  ]
      # ]
      # assert {:ok, ^expected, "", _, _, _} = result
    end
  end
end

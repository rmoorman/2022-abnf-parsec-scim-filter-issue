defmodule ScimParserTest do
  use ExUnit.Case

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
    ## filter rules (elsewhere, made up, intentionally different)
    ~s|userType eq "Employee" and (emails co "example.com" or emails co "example.org")|,
    ~s|urn:ietf:params:scim:schemas:extension:enterprise:2.0:User:employeeNumber pr|
  ]

  @tag :filter
  for rule <- @filter_rules do
    test "filter rule ~s|#{rule}|" do
      task = Task.async(fn -> ScimParser.filter(unquote(rule)) end)
      assert {:ok, result} = Task.yield(task, 2000) || Task.shutdown(task)
      assert {:ok, _result, "" = _rest, _, _, _} = result
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
      task = Task.async(fn -> ScimParser.scim_rfc_path(unquote(rule)) end)
      assert {:ok, result} = Task.yield(task, 200) || Task.shutdown(task)
      assert {:ok, _result, "" = _rest, _, _, _} = result
    end
  end
end

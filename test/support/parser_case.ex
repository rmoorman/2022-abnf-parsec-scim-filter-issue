defmodule ParserCase do
  use ExUnit.CaseTemplate

  using do
    quote do
      import ParserCase
    end
  end

  @doc """
  Call the given SCIM parser function and assert a timely response.
  """
  def parse(parser \\ ScimParser, fun, input)

  def parse(parser, fun, input) do
    task = Task.async(fn -> apply(parser, fun, [input]) end)
    assert {:ok, result} = Task.yield(task, 200) || Task.shutdown(task)
    result
  end
end

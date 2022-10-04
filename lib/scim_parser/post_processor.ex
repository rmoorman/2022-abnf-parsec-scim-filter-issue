defmodule ScimParser.PostProcessor do
  def process(data), do: convert(data)

  defp convert(list) when is_list(list), do: Enum.map(list, &convert/1)
  defp convert({:compareop, op}), do: {:compareop, String.downcase(op)}
  defp convert({:presentop, op}), do: {:presentop, String.downcase(op)}

  defp convert({:number, opts}) do
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

    {:number, Decimal.new("#{minus}#{int}#{frac}#{exp}")}
  end

  defp convert({tag, tagged}), do: {tag, convert(tagged)}
  defp convert(x), do: x
end

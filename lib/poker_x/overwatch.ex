defmodule PokerX.Overwatch do
  def tables do
    :global.registered_names()
    |> Enum.filter(fn
      {:table, _} -> true
      _ -> false
    end)
    |> Enum.map(fn {_, name} -> name end)
  end
end

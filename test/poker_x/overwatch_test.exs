defmodule PokerX.OverwatchTest do
  use ExUnit.Case, async: false
  alias PokerX.Table

  @num_seats 3

  setup do
    PokerX.Bank.start_link()
    players = :ets.new(:players, [:public])

    {:ok, [players: players]}
  end

  test "Testing overwatcher", %{players: players} do
    assert [] = PokerX.Overwatch.tables()
    {:ok, pid} = Table.start_link(:test_table, nil, players, @num_seats)
    assert [:test_table] = PokerX.Overwatch.tables()
    Process.unlink(pid)
    Process.exit(pid, :kill)
    Process.sleep(50)
    assert [] = PokerX.Overwatch.tables()
  end
end

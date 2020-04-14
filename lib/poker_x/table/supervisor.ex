defmodule PokerX.Table.Supervisor do
  use Supervisor

  def start_link([table_name, num_players]) do
    Supervisor.start_link(__MODULE__, [table_name, num_players], name: table_sup(table_name))
  end

  def start_link(table_name, num_players) do
    start_link([table_name, num_players])
  end

  def init([table_name, num_players]) do
    players = :ets.new(:players, [:public])

    children = [
      worker(PokerX.Table, [table_name, hand_supervisor(table_name), players, num_players]),
      supervisor(PokerX.Hand.Supervisor, [[name: hand_supervisor(table_name)]])
    ]

    supervise(children, strategy: :one_for_one)
  end

  defp table_sup(table_name), do: {:via, :global, {:table_sup, table_name}}
  defp hand_supervisor(table_name), do: {:via, :global, {:hand_supervisor, table_name}}
end

defmodule PokerX.Table.Supervisor do
  use Supervisor

  def start_link([table_name, num_players]) do
    Supervisor.start_link(__MODULE__, [table_name, num_players], name: table_sup(table_name))
  end

  def start_link(table_name, num_players) do
    start_link([table_name, num_players])
  end

  @impl true
  def init([table_name, num_players]) do
    players = :ets.new(:players, [:public])
    hand_name = Ecto.UUID.generate()

    children = [
      {PokerX.Table, [table_name, hand_name, players, num_players]},
      {PokerX.Hand, [hand_name, table_name, []]}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

  defp table_sup(table_name), do: {:via, :global, {:table_sup, table_name}}
end

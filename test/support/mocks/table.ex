defmodule Mocks.Table do
  use GenServer

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, self, opts)
  end

  def handle_call({:update_balance, _player, -500}, _from, state) do
    {:reply, {:error, %{reason: :insufficient_funds}}, state}
  end

  def handle_call(:get_state, _from, state) do
    players = [
      %{seat: 1, id: :one, balance: 200},
      %{seat: 3, id: :two, balance: 200},
      %{seat: 4, id: :three, balance: 200}
      #      %{seat: 6, id: :four, balance: 0},
    ]

    {:reply, %{hand: nil, players: players}, state}
  end

  def handle_call(_msg, _from, state) do
    {:reply, :ok, state}
  end

  def handle_cast({:notify_player, player, msg}, test_process) do
    send(test_process, {player, msg})
    {:noreply, test_process}
  end

  def handle_cast(:hand_finished, state) do
    {:noreply, state}
  end
end

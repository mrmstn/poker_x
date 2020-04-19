defmodule PokerX.Bank do
  use GenServer
  use PokerX.Subscribable

  @name __MODULE__

  def start_link(_ \\ []) do
    GenServer.start_link(__MODULE__, %{}, name: @name)
  end

  def deposit(player, amount) do
    GenServer.cast(@name, {:deposit, player, amount})
  end

  def withdraw(player, amount) do
    GenServer.call(@name, {:withdraw, player, amount})
  end

  def balance(player) do
    GenServer.call(@name, {:balance, player})
  end

  def init(init_arg) do
    {:ok, init_arg}
  end

  def handle_cast({:deposit, player, amount}, state) when amount >= 0 do
    state =
      Map.update(state, player, amount, fn current -> current + amount end)
      |> notify_subscribers({:deposit, player, amount}, player)

    {:noreply, state}
  end

  def handle_cast(_msg, state) do
    {:noreply, state}
  end

  def handle_call({:withdraw, player, amount}, _from, state) when amount >= 0 do
    case Map.fetch(state, player) do
      {:ok, current} when current >= amount ->
        state =
          state
          |> Map.put(player, current - amount)
          |> notify_subscribers({:withdraw, player, amount}, player)

        {:reply, :ok, state}

      _ ->
        {:reply, {:error, %{reason: :insufficient_funds}}, state}
    end
  end

  def handle_call({:balance, player}, _from, state) do
    case Map.fetch(state, player) do
      {:ok, balance} -> {:reply, balance, state}
      _ -> {:reply, 0, state}
    end
  end

  def handle_call(_msg, _from, state) do
    {:reply, :error, state}
  end
end

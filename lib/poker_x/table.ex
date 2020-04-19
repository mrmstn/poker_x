defmodule PokerX.Table do
  use GenServer
  use PokerX.Subscribable

  def start_link([table, sup, storage, num_seats]) do
    GenServer.start_link(__MODULE__, [table, sup, storage, num_seats], name: via_tuple(table))
  end

  def via_tuple(table), do: {:via, :global, {:table, table}}

  def whereis(table) do
    :global.whereis_name({:table, table})
  end

  def sit(table, player, seat) do
    GenServer.call(table, {:sit, player, seat})
  end

  def leave(table, player) do
    GenServer.call(table, {:leave, player})
  end

  def buy_in(table, player, amount) do
    GenServer.call(table, {:buy_in, player, amount})
  end

  def cash_out(table, player) do
    GenServer.call(table, {:cash_out, player})
  end

  def update_balance(table, player, delta) do
    GenServer.call(table, {:update_balance, player, delta})
  end

  def get_state(table) do
    GenServer.call(table, :get_state)
  end

  ### GenServer callbacks
  def init([table, hand, storage, num_seats]) do
    {:ok, %{table: table, storage: storage, num_seats: num_seats, hand: hand, dealer: nil}}
  end

  def handle_call({:sit, _, seat}, _from, state = %{num_seats: num_seats})
      when seat < 1 or seat > num_seats do
    {:reply, {:error, %{reason: :seat_unavailable}}, state}
  end

  def handle_call({:sit, player, seat}, _, state) when is_integer(seat) do
    case seat_player(state, player, seat) do
      :ok ->
        state =
          case state.dealer do
            nil -> %{state | dealer: player}
            _ -> state
          end

        state = notify_subscribers(state, {:sit, player, seat}, state.table)
        {:reply, :ok, state}

      {:error, reason} ->
        {:reply, {:error, reason}, state}
    end
  end

  def handle_call({:leave, player}, _, state) do
    case get_player(state, player) do
      {:ok, %{balance: 0}} ->
        unseat_player(state, player)
        state = notify_subscribers(state, {:leave, player}, state.table)
        {:reply, :ok, state}

      {:ok, %{balance: balance}} when balance > 0 ->
        {:reply, {:error, %{reason: :player_has_balance}}, state}

      error ->
        {:reply, error, state}
    end
  end

  def handle_call({:buy_in, player, amount}, _, state) when amount > 0 do
    case state |> get_player(player) |> withdraw_funds(amount) do
      :ok ->
        modify_balance(state, player, amount)
        state = notify_subscribers(state, {:buy_in, player, amount}, state.table)
        {:reply, :ok, state}

      error ->
        {:reply, error, state}
    end
  end

  def handle_call({:cash_out, player}, _, state) do
    case clear_balance(state, player) do
      {:ok, balance} ->
        PokerX.Bank.deposit(player, balance)
        state = notify_subscribers(state, {:cash_out, player}, state.table)
        {:reply, :ok, state}

      error ->
        {:reply, error, state}
    end
  end

  def handle_call(:get_state, _from, state) do
    return_state = Map.put(state, :players, get_players(state))

    {
      :reply,
      return_state,
      state
    }
  end

  def handle_call({:update_balance, player, delta}, _from, state) when delta >= 0 do
    case get_player(state, player) do
      {:ok, %{balance: _balance}} ->
        modify_balance(state, player, delta)
        state = notify_subscribers(state, {:update_balance, player, delta}, state.table)
        {:reply, :ok, state}

      error ->
        {:reply, error, state}
    end
  end

  def handle_call({:update_balance, player, delta}, _from, state) when delta < 0 do
    case get_player(state, player) do
      {:ok, %{balance: balance}} when balance + delta >= 0 ->
        modify_balance(state, player, delta)

        state = notify_subscribers(state, {:update_balance, player, delta}, state.table)
        {:reply, :ok, state}

      {:ok, _} ->
        {:reply, {:error, %{reason: :insufficient_funds}}, state}

      error ->
        {:reply, error, state}
    end
  end

  defp withdraw_funds({:ok, %{id: pid}}, amount), do: PokerX.Bank.withdraw(pid, amount)
  defp withdraw_funds(error, _amount), do: error

  defp seat_player(%{storage: storage}, player, seat) do
    case :ets.match_object(storage, {:_, seat, :_}) do
      [] ->
        :ets.insert(storage, {{:player, player}, seat, 0})
        :ok

      _ ->
        {:error, %{reason: :seat_taken}}
    end
  end

  defp unseat_player(state, player) do
    :ets.delete(state.storage, {:player, player})
  end

  defp modify_balance(state, player, delta) do
    :ets.update_counter(state.storage, {:player, player}, {3, delta})
  end

  defp clear_balance(state, player) do
    case get_player(state, player) do
      {:ok, %{balance: balance}} ->
        :ets.update_element(state.storage, {:player, player}, {3, 0})
        {:ok, balance}

      error ->
        error
    end
  end

  defp get_players(state) do
    state.storage
    |> :ets.select([{{{:player, :_}, :_, :_}, [], [:"$_"]}])
    |> Enum.sort_by(fn {_, seat, _} -> seat end)
    |> Enum.map(&player_to_map/1)
  end

  defp get_player(state, player) do
    case :ets.lookup(state.storage, {:player, player}) do
      [] -> {:error, %{reason: :not_at_table}}
      [tuple] -> {:ok, player_to_map(tuple)}
    end
  end

  defp player_to_map({{:player, id}, seat, balance}), do: %{id: id, seat: seat, balance: balance}
end

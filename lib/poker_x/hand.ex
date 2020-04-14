defmodule PokerX.Hand do
  use GenServer
  use PokerX.Subscribable

  defstruct hand: nil,
            table: nil,
            board: [],
            phase: :initial,
            players: [],
            pot: 0,
            blinds: {20, 40},
            posted_blinds: 0

  @phases [
    :initial,
    :blinds,
    :pre_flop,
    :flop,
    :turn,
    :river,
    :showdown
  ]

  def start_link(hand, table, config \\ []) do
    GenServer.start_link(__MODULE__, [hand, table, config], name: via_tuple(hand))
  end

  defp via_tuple(hand), do: {:via, :global, {:hand, hand}}

  def whereis(hand) do
    :global.whereis_name({:hand, hand})
  end

  # ----------------------------[ INITIAL PHASE ]----------------------------
  def start_game(hand) do
    GenServer.call(hand, :start_game)
  end

  # ----------------------------[ SHOWDOWN PHASE ]----------------------------
  def finish_game(hand) do
    GenServer.call(hand, :finish_game)
  end

  # ----------------------------[ PRE_FLOP - RIVER PHASE ]----------------------------
  def bet(hand, player, amount) do
    GenServer.call(hand, {:bet, player, amount})
  end

  def check(hand, player) do
    GenServer.call(hand, {:bet, player, 0})
  end

  def fold(hand, player) do
    GenServer.call(hand, {:fold, player, nil})
  end

  # ----------------------------[ ALWAYS ]----------------------------
  def get_state(hand) do
    GenServer.call(hand, :get_state)
  end

  def get_options(hand, player) do
    GenServer.call(hand, :get_options)
  end

  ### GenServer callbacks
  def init([hand, table, config]) do
    seed_random_number_generator

    {:ok,
     %__MODULE__{
       hand: hand,
       table: table,
       blinds: get_blinds(config)
     }}
  end

  # ----------------------------[ INITIAL PHASE ]----------------------------
  def handle_call(:start_game, _, %{phase: phase} = state) when phase != :initial do
    {:reply, {:error, %{reason: :phase_not_initial}}, state}
  end

  def handle_call(:start_game, _, state) do
    players = PokerX.Table.get_state(state.table).players |> Enum.map(& &1.id)

    state =
      %{state | players: players}
      |> track_initial_positions
      |> set_blinds
      |> advance_phase
      |> notify_subscribers(:game_started, state.hand)

    {:reply, :ok, state}
  end

  def handle_call(:finish_game, _, %{phase: :showdown} = state) do
    state =
      state
      |> advance_phase
      |> reset_game
      |> notify_subscribers(:finish_game, state.hand)

    {:reply, :ok, state}
  end

  def handle_call(:finish_game, _, %{finished: true} = state) do
    state =
      state
      |> reset_game
      |> notify_subscribers(:finish_game, state.hand)

    {:reply, :ok, state}
  end

  # ----------------------------[ GENERIC ACTION FILTER ]----------------------------
  def handle_call({_, player, _}, _, state = %{players: [%{id: another_player} | _]})
      when player != another_player do
    {:reply, {:error, %{reason: :not_active}}, state}
  end

  # ----------------------------[ PRE_FLOP - RIVER PHASE ]----------------------------
  def handle_call({:bet, _, amount}, _, state = %{players: [%{to_call: to_call} | _]})
      when amount < to_call do
    {:reply, {:error, %{reason: :not_enough}}, state}
  end

  # player calls
  def handle_call({:bet, player, amount}, _, state = %{players: [%{to_call: to_call} | _]})
      when amount == to_call do
    case PokerX.Table.update_balance(state.table, player, -amount) do
      :ok ->
        state =
          state
          |> call_bet
          |> increment_pot(amount)
          |> advance_action
          |> check_for_phase_end
          |> notify_subscribers({:bet, player, amount}, state.hand)

        {:reply, :ok, state}

      error ->
        {:reply, error, state}
    end
  end

  def handle_call(
        {:bet, _, amount},
        _,
        state = %{players: [%{to_call: to_call} | _], phase: phase}
      )
      when amount > to_call and phase == :blinds do
    {:reply, {:error, %{reason: :expected_blinds}}, state}
  end

  def handle_call({:bet, player, amount}, _, state = %{players: [%{to_call: to_call} | _]})
      when amount > to_call do
    case PokerX.Table.update_balance(state.table, player, -amount) do
      :ok ->
        state =
          state
          |> call_bet
          |> increment_pot(amount)
          |> raise_remaining_players(amount - to_call)
          |> advance_action
          |> check_for_phase_end
          |> notify_subscribers({:bet, player, amount}, state.hand)

        {:reply, :ok, state}

      error ->
        {:reply, error, state}
    end
  end

  def handle_call({:fold, player, _}, _, state = %{players: [_ | remaining_players]})
      when remaining_players != [] do
    state =
      %{state | players: remaining_players}
      |> check_for_phase_end
      |> notify_subscribers({:fold, player, nil}, state.hand)

    {:reply, :ok, state}
  end

  def handle_call(:get_state, _, state) do
    players_with_active_flag =
      state.players
      |> Enum.with_index()
      |> Enum.map(fn {player, index} ->
        active = index == 0 && Map.has_key?(player, :to_call)
        Map.put(player, :active, active)
      end)

    {:reply, %{state | players: players_with_active_flag}, state}
  end

  defp get_blinds(config) do
    big_blind = Keyword.get(config, :big_blind, 10)
    small_blind = Keyword.get(config, :small_blind, div(big_blind, 2))
    {small_blind, big_blind}
  end

  defp track_initial_positions(state) do
    players =
      Enum.with_index(state.players)
      |> Enum.map(fn {id, index} -> %{id: id, position: index} end)

    Map.put(state, :players, players)
  end

  defp set_blinds(state = %{players: [small | remaining]}) do
    {small_blind, big_blind} = state.blinds

    small = Map.put(small, :to_call, small_blind)
    remaining = Enum.map(remaining, &Map.put(&1, :to_call, big_blind))

    %{state | players: [small | remaining]}
  end

  defp start_game_hands(state, deck) do
    {players, deck} =
      Enum.map_reduce(state.players, deck, fn player, [card_one, card_two | deck] ->
        {Map.put(player, :hand, [card_one, card_two]), deck}
      end)

    state |> Map.put(:players, players) |> Map.put(:deck, deck)
  end

  defp increment_pot(state, amount) do
    case state.posted_blinds do
      i when i < 2 -> Map.update!(state, :posted_blinds, &(&1 + 1))
      2 -> state
    end
    |> Map.update!(:pot, &(&1 + amount))
  end

  defp advance_action(state = %{players: [active_player | remaining_players]}) do
    Map.put(state, :players, remaining_players ++ [active_player])
  end

  # Small Blind will remain
  defp call_bet(state = %{posted_blinds: 0}) do
    state
  end

  # Big Blind must check
  defp call_bet(state = %{posted_blinds: 1, players: [active_player | remaining_players]}) do
    %{state | players: [%{active_player | to_call: 0} | remaining_players]}
  end

  defp call_bet(state = %{players: [active_player | remaining_players]}) do
    Map.put(state, :players, [Map.delete(active_player, :to_call) | remaining_players])
  end

  defp raise_remaining_players(state = %{players: [active_player | remaining_players]}, amount) do
    raised_players =
      Enum.map(remaining_players, fn player ->
        Map.update(player, :to_call, amount, &(&1 + amount))
      end)

    Map.put(state, :players, [active_player | raised_players])
  end

  defp check_for_phase_end(state = %{players: [winner]}) do
    declare_winner(winner, state)
  end

  defp check_for_phase_end(state = %{posted_blinds: 2, phase: :blinds}) do
    advance_phase(state)
  end

  defp check_for_phase_end(state = %{posted_blinds: _, phase: :blinds}) do
    state
  end

  defp check_for_phase_end(state = %{players: [%{to_call: _} | _]}) do
    state
  end

  defp check_for_phase_end(state) do
    advance_phase(state)
  end

  defp advance_phase(state = %{players: [winner]}) do
    declare_winner(winner, state)
  end

  defp advance_phase(state = %{phase: :initial}) do
    %{state | phase: :blinds}
  end

  defp advance_phase(state = %{phase: :blinds}) do
    state = start_game_hands(state, PokerX.Deck.new())
    %{state | phase: :pre_flop}
  end

  defp advance_phase(state = %{phase: :pre_flop}) do
    advance_board(state, :flop, 3)
  end

  defp advance_phase(state = %{phase: :flop}) do
    advance_board(state, :turn, 1)
  end

  defp advance_phase(state = %{phase: :turn}) do
    advance_board(state, :river, 1)
  end

  defp advance_phase(state = %{phase: :river}) do
    ranked_players =
      [{winning_ranking, _, _, _} | _] =
      state.players
      |> Stream.map(fn player ->
        {ranking, hand} = PokerX.Ranking.best_possible_hand(state.board, player.hand)
        {ranking, hand, player}
      end)
      |> Enum.sort()
      |> Enum.reverse()
      |> Enum.map(fn {rank, cards, player} ->
        {rank, cards, player, PokerX.Ranking.evaluate(cards) |> PokerX.Ranking.description()}
      end)

    [{winning_ranking, _, _, _} | _] = ranked_players
    state = Map.put(state, :ranked_players, ranked_players)
    state = Map.put(state, :winning_rank, winning_ranking)
    %{state | phase: :showdown}
  end

  defp advance_phase(state = %{phase: :showdown, ranked_players: ranked_players}) do
    [{winning_ranking, _, _, _} | _] = ranked_players

    ranked_players
    |> Stream.take_while(fn {ranking, _, _, _} ->
      ranking == winning_ranking
    end)
    |> Enum.map(&elem(&1, 2))
    |> declare_winner(state)
  end

  defp advance_board(state, phase, num_cards) do
    players =
      state.players
      |> Enum.sort_by(& &1.position)
      |> Enum.map(fn player -> Map.put(player, :to_call, 0) end)

    {additional_cards, deck} = Enum.split(state.deck, num_cards)

    %{state | phase: phase, board: state.board ++ additional_cards, deck: deck, players: players}
  end

  defp declare_winner([winner], state),
    do: declare_winner(winner, state)

  defp declare_winner(winners, state) when is_list(winners) do
    IO.inspect("The winners are: #{inspect(winners)}")

    Map.put(state, :finished, true)
  end

  defp declare_winner(winner, state) do
    IO.inspect("The winner is: #{inspect(winner)}")

    PokerX.Table.update_balance(state.table, winner.id, state.pot)

    Map.put(state, :finished, true)
  end

  defp seed_random_number_generator do
    <<a::size(32), b::size(32), c::size(32)>> = :crypto.strong_rand_bytes(12)
    :random.seed({a, b, c})
  end

  defp deck do
    Application.get_env(:gen_poker, :deck)
  end

  defp reset_game(state) do
    %__MODULE__{
      hand: state.hand,
      table: state.table,
      blinds: state.blinds
    }
  end
end

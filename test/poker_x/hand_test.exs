defmodule PokerX.HandTest do
  use ExUnit.Case, async: false
  alias PokerX.Deck.Card

  defp cards do
    # player one's cards
    # player two's cards
    # player three's cards
    # the board
    ("As Jd " <>
       "Jc Tc " <>
       "Js Ts " <>
       "Ad 9h 8s Jh Qd")
    |> String.split()
    |> Enum.map(&Card.from_string/1)
  end

  setup do
    Mocks.StackedDeck.stack(cards)
    {:ok, table} = Mocks.Table.start_link()
    %{players: players} = PokerX.Table.get_state(table)
    {:ok, [players: players, table: table]}
  end

  test "betting, raising, and folding", %{players: players, table: table} do
    [player_one, player_two, player_thr] = players |> Enum.map(& &1.id)

    {:ok, hand} = PokerX.Hand.start_link("test_hand", table)
    %{phase: :initial} = PokerX.Hand.get_state(hand)
    :ok = PokerX.Hand.start_game(hand)

    # Blinds
    %{phase: :blinds} = PokerX.Hand.get_state(hand)

    :ok = PokerX.Hand.bet(hand, player_one, 5)
    {:error, %{reason: :not_enough}} = PokerX.Hand.bet(hand, player_two, 5)
    :ok = PokerX.Hand.bet(hand, player_two, 10)

    %{phase: :pre_flop, players: hand_players} = PokerX.Hand.get_state(hand)

    assert [
             %{active: true, id: :three, position: 2, to_call: 10},
             %{active: false, id: :one, position: 0, to_call: 5},
             %{active: false, id: :two, position: 1, to_call: 0}
           ] = hand_players

    # Pre-Flop
    %{phase: :pre_flop} = PokerX.Hand.get_state(hand)
    {:error, %{reason: :not_enough}} = PokerX.Hand.bet(hand, player_thr, 5)
    {:error, %{reason: :not_active}} = PokerX.Hand.bet(hand, player_one, 10)
    {:error, %{reason: :not_active}} = PokerX.Hand.bet(hand, player_two, 10)

    :ok = PokerX.Hand.bet(hand, player_thr, 10)

    {:error, %{reason: :not_enough}} = PokerX.Hand.check(hand, player_one)
    :ok = PokerX.Hand.bet(hand, player_one, 5)
    :ok = PokerX.Hand.check(hand, player_two)

    # Flop
    %{phase: :flop} = PokerX.Hand.get_state(hand)
    :ok = PokerX.Hand.check(hand, player_one)
    :ok = PokerX.Hand.bet(hand, player_two, 25)
    :ok = PokerX.Hand.bet(hand, player_thr, 50)
    :ok = PokerX.Hand.bet(hand, player_one, 50)
    :ok = PokerX.Hand.bet(hand, player_two, 25)

    # Turn
    %{phase: :turn} = PokerX.Hand.get_state(hand)
    :ok = PokerX.Hand.check(hand, player_one)
    :ok = PokerX.Hand.check(hand, player_two)
    {:error, %{reason: :not_active}} = PokerX.Hand.fold(hand, player_one)
    :ok = PokerX.Hand.bet(hand, player_thr, 50)
    :ok = PokerX.Hand.fold(hand, player_one)
    :ok = PokerX.Hand.bet(hand, player_two, 50)

    # River
    %{phase: :river} = PokerX.Hand.get_state(hand)
    :ok = PokerX.Hand.check(hand, player_two)
    {:error, %{reason: :insufficient_funds}} = PokerX.Hand.bet(hand, player_thr, 500)
    :ok = PokerX.Hand.bet(hand, player_thr, 50)
    :ok = PokerX.Hand.bet(hand, player_two, 100)
    :ok = PokerX.Hand.bet(hand, player_thr, 50)

    %{phase: :showdown, ranked_players: ranked_players} = PokerX.Hand.get_state(hand)
    :ok = PokerX.Hand.finish_game(hand)
  end
end

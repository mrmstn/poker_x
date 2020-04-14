defmodule PokerX.EndToEndTest do
  use ExUnit.Case, async: false

  defp cards do
    # player three's cards
    # player one's cards
    # player two's cards
    # the board
    ("As Jd " <>
       "Jc Tc " <>
       "Js Ts " <>
       "Ad 9h 8s Jh Qd")
    |> String.split()
    |> Enum.map(&PokerX.Deck.Card.from_string/1)
  end

  setup do
    Mocks.StackedDeck.stack(cards())
    PokerX.Bank.start_link()

    players =
      Enum.map(~w(player_one player_two player_three), fn player ->
        PokerX.Bank.deposit(player, 1000)
        player
      end)

    {:ok, _} = PokerX.Table.Supervisor.start_link("test_table", 6)

    {:ok, [table: PokerX.Table.whereis("test_table"), players: players]}
  end

  test "betting, raising, and folding", %{table: table, players: players} do
    [player_one, player_two, player_thr] = players

    PokerX.Table.sit(table, player_one, 1)
    PokerX.Table.sit(table, player_two, 2)
    PokerX.Table.sit(table, player_thr, 3)

    PokerX.Table.buy_in(table, player_one, 1000)
    PokerX.Table.buy_in(table, player_two, 1000)
    PokerX.Table.buy_in(table, player_thr, 800)

    Process.exit(table, :kill)

    :timer.sleep(100)
    table = PokerX.Table.whereis("test_table")

    :ok = PokerX.Table.deal(table)
    hand = PokerX.Table.get_state(table).hand |> PokerX.Hand.whereis()

    # :timer.sleep(500)

    # :global.whereis_name(elem(hand, 1)) |> Process.exit(:kill)
    # :timer.sleep(500)

    :ok = PokerX.Hand.bet(hand, player_thr, 10)
    :ok = PokerX.Hand.bet(hand, player_one, 5)
    :ok = PokerX.Hand.check(hand, player_two)

    # Flop
    :ok = PokerX.Hand.check(hand, player_one)
    :ok = PokerX.Hand.bet(hand, player_two, 25)
    :ok = PokerX.Hand.bet(hand, player_thr, 50)
    :ok = PokerX.Hand.bet(hand, player_one, 50)
    :ok = PokerX.Hand.bet(hand, player_two, 25)

    # Turn
    :ok = PokerX.Hand.check(hand, player_one)
    :ok = PokerX.Hand.check(hand, player_two)
    :ok = PokerX.Hand.bet(hand, player_thr, 50)
    :ok = PokerX.Hand.fold(hand, player_one)
    :ok = PokerX.Hand.bet(hand, player_two, 50)

    # River
    :ok = PokerX.Hand.check(hand, player_two)
    :ok = PokerX.Hand.bet(hand, player_thr, 50)
    :ok = PokerX.Hand.bet(hand, player_two, 100)
    :ok = PokerX.Hand.bet(hand, player_thr, 50)

    PokerX.Table.cash_out(table, player_one)
    PokerX.Table.cash_out(table, player_two)
    PokerX.Table.cash_out(table, player_thr)

    assert PokerX.Bank.balance(player_one) == 940
    assert PokerX.Bank.balance(player_two) == 1270
    assert PokerX.Bank.balance(player_thr) == 790
  end
end

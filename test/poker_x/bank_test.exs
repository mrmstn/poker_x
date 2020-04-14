defmodule PokerX.BankTest do
  use ExUnit.Case, async: false

  test "deposits and withdrawals" do
    PokerX.Bank.start_link()

    PokerX.Bank.deposit(:player_one, 100)

    assert PokerX.Bank.withdraw(:player_one, 75) == :ok
    assert PokerX.Bank.balance(:player_one) == 25
    assert PokerX.Bank.withdraw(:player_one, 75) == {:error, %{reason: :insufficient_funds}}
    assert PokerX.Bank.withdraw(:player_one, -75) == :error

    assert PokerX.Bank.withdraw(:player_two, 35) == {:error, %{reason: :insufficient_funds}}
    assert PokerX.Bank.balance(:player_two) == 0

    PokerX.Bank.deposit(:player_one, -100)
    assert PokerX.Bank.balance(:player_one) == 25
    assert PokerX.Bank.withdraw(:player_one, 25) == :ok
    assert PokerX.Bank.balance(:player_one) == 0
  end
end

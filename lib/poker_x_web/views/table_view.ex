defmodule PokerXWeb.TableView do
  use PokerXWeb, :view

  def card_to_class(card) do
    char_code = String.Chars.to_string(card)
    "card card-#{char_code}"
  end
end

defmodule PokerXWeb.TableView do
  use PokerXWeb, :view
  alias PokerXWeb.TableLive
  alias PokerXWeb.TableView

  def card_to_class(card) do
    char_code = String.Chars.to_string(card)
    "card card-#{char_code}"
  end
end

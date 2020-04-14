defmodule PokerXWeb.PageController do
  use PokerXWeb, :controller
  alias PokerXWeb.Router.Helpers, as: Helper

  def index(conn, _params) do
    if get_session(conn, :user_id) == nil do
      user_id = Ecto.UUID.generate()
      conn = put_session(conn, :user_id, user_id)
      PokerX.Bank.deposit(user_id, 1000)
    end

    conn
    |> redirect(to: Helper.live_path(conn, PokerXWeb.TableLive.Index))
  end
end

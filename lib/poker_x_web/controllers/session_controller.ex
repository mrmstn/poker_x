defmodule PokerXWeb.SessionController do
  use PokerXWeb, :controller
  alias PokerXWeb.Router.Helpers, as: Helper

  def login(conn, _params) do
    render(conn, "login.html", title: "Login")
  end

  def load_session(conn, %{"username" => username}) do
    if get_session(conn, :user_id) == nil do
      conn = put_session(conn, :user_id, username)
      PokerX.Bank.deposit(username, 1000)
    end

    conn
    |> put_session(:user_id, username)
    |> redirect(to: Helper.live_path(conn, PokerXWeb.TableLive.Index))
  end
end

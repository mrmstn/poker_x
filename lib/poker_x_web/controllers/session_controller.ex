defmodule PokerXWeb.SessionController do
  use PokerXWeb, :controller
  alias PokerXWeb.Router.Helpers, as: Helper

  @spec login(Plug.Conn.t(), any) :: Plug.Conn.t()
  def login(conn, _params) do
    render(conn, "login.html", title: "Login")
  end

  @spec load_session(Plug.Conn.t(), map) :: Plug.Conn.t()
  def load_session(conn, %{"username" => username}) do
    if get_session(conn, :user_id) == nil do
      PokerX.Bank.deposit(username, 1000)
    end

    conn
    |> put_session(:user_id, username)
    |> redirect(to: Helper.live_path(conn, PokerXWeb.TableLive.Index))
  end

  def unload_session(conn, _) do
    conn
    |> clear_session()
    |> redirect(to: Helper.session_path(conn, :login))
  end
end

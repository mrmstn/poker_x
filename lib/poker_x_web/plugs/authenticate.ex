defmodule PokerXWeb.Plugs.Authenticate do
  import Phoenix.Controller, only: [redirect: 2]
  import Plug.Conn, only: [halt: 1]
  import PokerXWeb.Helper
  alias PokerXWeb.Router.Helpers, as: Helper

  def init(default), do: default

  def call(conn, _opts) do
    if is_logged_in?(conn) do
      conn
    else
      conn
      |> redirect(to: Helper.session_path(conn, :login))
      |> halt()
    end
  end
end

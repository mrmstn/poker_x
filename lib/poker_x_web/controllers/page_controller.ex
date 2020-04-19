defmodule PokerXWeb.PageController do
  use PokerXWeb, :controller
  alias PokerXWeb.Router.Helpers, as: Helper

  def index(conn, _params) do
    conn
    |> redirect(to: Helper.live_path(conn, PokerXWeb.TableLive.Index))
  end
end

defmodule PokerXWeb.Helper do
  alias Plug.Conn

  def is_logged_in?(conn) do
    case Conn.get_session(conn, :user_id) do
      nil -> false
      user_id when is_binary(user_id) -> true
    end
  end
end

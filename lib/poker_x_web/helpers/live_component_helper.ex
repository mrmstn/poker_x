defmodule PokerXWeb.LiveComponentHelper do
  def handle_poker_response(:ok, socket) do
    send(self(), {__MODULE__, {:ok, :seat_changed}})

    {:noreply, socket}
  end

  def handle_poker_response({:error, %{reason: reason}}, socket) do
    IO.inspect({:error, %{reason: reason}})
    send(self(), {__MODULE__, {:error, %{reason: reason}}})

    {:noreply, socket}
  end
end

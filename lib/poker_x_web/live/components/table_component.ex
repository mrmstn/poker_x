defmodule PokerXWeb.TableComponent do
  use Phoenix.LiveComponent
  import PokerXWeb.LiveComponentHelper

  def mount(socket) do
    {:ok, socket}
  end

  def render(assigns), do: PokerXWeb.ComponentView.render("table_component.html", assigns)

  def update(%{id: hand_id, hand_state: hand_state, table_state: table_state}, socket) do
    {:ok, assign(socket, hand_id: hand_id, hand_state: hand_state, table_state: table_state)}
  end

  def handle_event("deal", _, %{assigns: %{hand_id: hand_id}} = socket) do
    hand_id
    |> PokerX.Hand.whereis()
    |> PokerX.Hand.start_game()
    |> handle_poker_response(socket)
  end

  def handle_event("hand_finished", _, %{assigns: %{hand_id: hand_id}} = socket) do
    hand_id
    |> PokerX.Hand.whereis()
    |> PokerX.Hand.finish_game()
    |> handle_poker_response(socket)
  end
end

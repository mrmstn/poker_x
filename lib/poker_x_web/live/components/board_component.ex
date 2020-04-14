defmodule PokerXWeb.BoardComponent do
  use Phoenix.LiveComponent
  import PokerXWeb.LiveComponentHelper

  def mount(socket) do
    {:ok, socket}
  end

  def render(assigns), do: PokerXWeb.ComponentView.render("board_component.html", assigns)

  def update(%{id: hand_id, hand: hand}, socket) do
    hand = hand || %{}

    assigns = [
      id: hand_id,
      hand_state: hand,
      board: Map.get(hand, :board, []),
      phase: Map.get(hand, :phase, :not_started),
      pot: Map.get(hand, :pot, nil)
    ]

    {:ok, assign(socket, assigns)}
  end
end

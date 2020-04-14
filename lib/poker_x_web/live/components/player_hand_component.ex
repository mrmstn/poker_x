defmodule PokerXWeb.PlayerHandComponent do
  use Phoenix.LiveComponent
  import PokerXWeb.LiveComponentHelper

  def mount(socket) do
    {:ok, socket}
  end

  def render(assigns), do: PokerXWeb.ComponentView.render("player_hand_component.html", assigns)

  def update(
        %{id: {hand_id, player}, player_hand: player_hand, table_pid: table_pid, phase: phase},
        socket
      ) do
    assigns = [
      id: player,
      hand_id: hand_id,
      hand_pid: PokerX.Hand.whereis(hand_id),
      hand_state: player_hand,
      table_pid: table_pid,
      player: player,
      hand: Map.get(player_hand, :hand, []),
      to_call: Map.get(player_hand, :to_call, 0),
      active?: Map.get(player_hand, :active, false),
      can_leave?: player_hand == %{},
      phase: phase
    ]

    {:ok, assign(socket, assigns)}
  end

  def handle_event("bet", %{"amount" => amount}, %{assigns: assigns} = socket) do
    {amount, ""} = Integer.parse(amount)

    assigns.hand_pid
    |> PokerX.Hand.bet(assigns.player, amount)
    |> handle_poker_response(socket)
  end

  def handle_event("check", _, %{assigns: assigns} = socket) do
    assigns.hand_pid
    |> PokerX.Hand.check(assigns.player)
    |> handle_poker_response(socket)
  end

  def handle_event("fold", _, %{assigns: assigns} = socket) do
    assigns.hand_pid
    |> PokerX.Hand.fold(assigns.player)
    |> handle_poker_response(socket)
  end

  def handle_event("leave", _, socket) do
    :ok =
      socket.assigns.table_pid
      |> PokerX.Table.cash_out(socket.assigns.id)

    socket.assigns.table_pid
    |> PokerX.Table.leave(socket.assigns.id)
    |> handle_poker_response(socket)
  end

  def handle_event("buy_in", %{"amount" => amount}, socket) do
    # TODO: Check phase for buy in

    {amount, ""} = Integer.parse(amount)

    socket.assigns.table_pid
    |> PokerX.Table.buy_in(socket.assigns.id, amount)
    |> handle_poker_response(socket)
  end
end

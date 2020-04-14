defmodule PokerXWeb.SeatComponent do
  use Phoenix.LiveComponent
  import PokerXWeb.LiveComponentHelper

  def mount(socket) do
    {:ok, socket}
  end

  def render(assigns), do: PokerXWeb.ComponentView.render("seat_component.html", assigns)

  def update(
        %{
          player: player,
          id: {seat, table_name},
          current_player: current_player,
          can_sit?: can_sit
        },
        socket
      ) do
    assigns = [
      free?: is_nil(player),
      own?: is_map(player) and player.id == current_player,
      can_sit?: can_sit,
      table_name: table_name,
      table_pid: PokerX.Table.whereis(table_name),
      player: player,
      current_player: current_player,
      id: seat
    ]

    {:ok, assign(socket, assigns)}
  end

  def handle_event("sit", %{"seat" => seat}, socket) do
    {seat, ""} = Integer.parse(seat)

    socket.assigns.table_pid
    |> PokerX.Table.sit(socket.assigns.current_player, socket.assigns.id)
    |> handle_poker_response(socket)
  end

  def handle_event("table-update_balance", %{"delta" => delta}, socket) do
    {delta, ""} = Integer.parse(delta)

    socket.assigns.table_pid
    |> PokerX.Table.update_balance(socket.assigns.player.id, delta)
    |> handle_poker_response(socket)
  end
end

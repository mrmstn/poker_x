defmodule PokerXWeb.TableLive.Show do
  use Phoenix.LiveView
  use Phoenix.HTML

  alias Phoenix.LiveView.Socket
  alias Phoenix.Socket.Broadcast
  alias PokerXWeb.Presence
  alias PokerXWeb.TableView

  @default_values [
    page_title: nil,
    table_id: nil,
    table_state: nil,
    table_pid: nil,
    table_subscribed: false,
    table_players: %{},
    hand_id: nil,
    hand_state: nil,
    hand_pid: nil,
    hand_subscribed: false,
    hand_players: %{},
    num_seats: nil,
    players: nil,
    count_players: nil,
    seats: nil,
    sitting?: nil
  ]

  def mount(_params, %{"user_id" => player_name}, socket) do
    socket =
      socket
      |> assign(@default_values)
      |> assign(player_name: player_name)

    {:ok, socket}
  end

  def render(assigns), do: TableView.render("show.html", assigns)

  def handle_params(%{"id" => id}, _url, socket) do
    if connected?(socket) do
      Presence.track(self(), "table_users:" <> id, socket.assigns.player_name, %{})
      Phoenix.PubSub.subscribe(PokerX.PubSub, "table_users:" <> id)
    end

    socket =
      socket
      |> assign(id: id)
      |> fetch()

    {:noreply, socket}
  end

  defp maybe_subscribe(%Socket{assigns: %{table_subscribed: false, table_id: id}} = socket)
       when not is_nil(id) do
    PokerX.Table.subscribe(id)

    socket
    |> assign(table_subscribed: true)
    |> maybe_subscribe
  end

  defp maybe_subscribe(%Socket{assigns: %{hand_subscribed: false, hand_id: id}} = socket)
       when not is_nil(id) do
    PokerX.Hand.subscribe(id)

    socket
    |> assign(hand_subscribed: true)
    |> maybe_subscribe
  end

  defp maybe_subscribe(socket) do
    socket
  end

  defp fetch(%Socket{} = socket) do
    socket
    |> fetch_presence
    |> fetch_table
    |> fetch_funds
    |> fetch_hand
    |> fetch_player_state
  end

  defp fetch_presence(%Socket{assigns: %{id: id}} = socket) do
    socket
    |> assign(on_site: PokerXWeb.Presence.list("table_users:" <> id) |> Map.keys())
  end

  defp fetch_table(%Socket{assigns: %{id: id}} = socket) do
    pid = PokerX.Table.whereis(id)
    table_state = PokerX.Table.get_state(pid)

    values = [
      page_title: "Table: " <> id,
      table_id: id,
      table_state: table_state,
      table_pid: pid,
      num_seats: table_state.num_seats,
      players: table_state.players,
      count_players: length(table_state.players),
      seats: Enum.map(table_state.players, fn player -> {player.seat, player} end) |> Map.new(),
      sitting?: Enum.any?(table_state.players, &(&1.id == socket.assigns.player_name)),
      hand_id: table_state.hand
    ]

    socket
    |> maybe_subscribe()
    |> assign(values)
  end

  defp fetch_hand(%{assigns: %{hand_id: nil}} = socket), do: socket

  defp fetch_hand(%{assigns: %{hand_id: hand_id}} = socket) do
    hand_pid = PokerX.Hand.whereis(hand_id)
    hand_state = PokerX.Hand.get_state(hand_pid)
    hand_players = Enum.map(hand_state.players, fn player -> {player.id, player} end) |> Map.new()

    assign(socket,
      hand_id: hand_id,
      hand_state: hand_state,
      hand_pid: hand_pid,
      hand_players: hand_players
    )
    |> maybe_subscribe()
  end

  defp fetch_funds(%Socket{assigns: %{player_name: player_name}} = socket) do
    bank_balance = PokerX.Bank.balance(player_name)
    assign(socket, bank_balance: bank_balance)
  end

  defp fetch_player_state(
         %Socket{
           assigns: %{player_name: player_name, table_state: table_state, hand_state: hand_state}
         } = socket
       ) do
    player_state =
      cond do
        Enum.any?(hand_state.players, &(&1.id == player_name)) -> :playing
        Enum.any?(table_state.players, &(&1.id == player_name)) -> :sitting
        true -> :watching
      end

    assign(socket, player_state: player_state)
  end

  def handle_event("sit", %{"seat" => seat}, socket) do
    {seat, ""} = Integer.parse(seat)
    amount = 400

    socket =
      with :ok <- PokerX.Table.sit(socket.assigns.table_pid, socket.assigns.player_name, seat),
           :ok <-
             PokerX.Table.buy_in(socket.assigns.table_pid, socket.assigns.player_name, amount) do
        clear_flash(socket)
      else
        {:error, %{reason: reason}} ->
          PokerX.Table.leave(socket.assigns.table_pid, socket.assigns.player_name)
          put_flash(socket, :error, reason)
      end
      |> fetch_table()
      |> fetch_funds()
      |> fetch_player_state()

    {:noreply, socket}
  end

  def handle_info(%Broadcast{event: "presence_diff"}, socket) do
    {:noreply, fetch_presence(socket)}
  end

  def handle_info({PokerX.Table, _, _}, socket) do
    #  def handle_info({PokerX.Table, {:sit, "asdf", 1}, _table_state }, state) do
    {:noreply, socket |> fetch_table()}
  end

  def handle_info({PokerX.Hand, _, _}, socket) do
    #  def handle_info({PokerX.Table, {:sit, "asdf", 1}, _table_state }, state) do
    {:noreply, socket |> fetch_hand}
  end

  def handle_info({PokerXWeb.LiveComponentHelper, {:ok, :seat_changed}}, socket) do
    {:noreply, clear_flash(socket) |> fetch()}
  end

  def handle_info({PokerXWeb.LiveComponentHelper, {:error, %{reason: reason}}}, socket) do
    {:noreply, put_flash(socket, :error, reason) |> fetch()}
  end
end

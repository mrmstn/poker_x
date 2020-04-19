defmodule PokerXWeb.TableLive.Index do
  use Phoenix.LiveView

  alias Phoenix.Socket.Broadcast
  alias PokerX.Overwatch
  alias PokerXWeb.Presence
  alias PokerXWeb.TableView

  def mount(_assigns, %{"user_id" => name}, socket) do
    Phoenix.PubSub.subscribe(PokerX.PubSub, "tables")
    Presence.track(self(), "lobby", name, %{})

    socket =
      socket
      |> assign(page_title: "Tables")
      |> fetch()

    {:ok, socket}
  end

  def render(assigns), do: TableView.render("index.html", assigns)

  defp fetch(socket) do
    assign(socket, show_modal: false)
    |> fetch_tables()
    |> fetch_presence()
    |> reset()
  end

  def fetch_tables(socket) do
    table_states =
      Overwatch.tables()
      |> Enum.map(fn table_id ->
        table_state =
          table_id
          |> PokerX.Table.whereis()
          |> PokerX.Table.get_state()

        hand_state =
          table_state.hand
          |> PokerX.Hand.whereis()
          |> PokerX.Hand.get_state()

        {table_state, hand_state}
      end)

    assign(socket, tables: table_states)
  end

  defp fetch_presence(socket) do
    assign(socket, online_users: PokerXWeb.Presence.list("lobby"))
  end

  def handle_info(%Broadcast{event: "presence_diff"}, socket) do
    {:noreply, socket |> fetch_presence()}
  end

  #  def handle_info({Accounts, [:user | _], _}, socket) do
  #    {:noreply, fetch(socket)}
  #  end
  #
  def handle_event("toggle_modal", _values, socket) do
    {:noreply, assign(socket, show_modal: !socket.assigns.show_modal)}
  end

  def handle_event("save", %{"player_count" => count, "table_name" => name}, socket) do
    Process.sleep(1_000)
    PokerX.Table.Supervisor.start_link(name, count)

    {:noreply, fetch(socket)}
  end

  def handle_event(_event, _id, socket) do
    {:noreply, socket}
  end

  def reset(socket) do
    assign(socket, new_table: %{name: "", player_count: 0})
  end

  def handle_params(_params, _uri, "confirm-boom", %{assigns: %{show_modal: _}} = socket) do
    {:noreply, assign(socket, show_modal: true)}
  end
end

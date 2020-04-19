defmodule PokerXWeb.BankComponent do
  use Phoenix.LiveComponent

  @impl true
  def mount(socket) do
    {:ok, socket}
  end

  @impl true
  def preload(player_assignes) do
    Enum.map(player_assignes, fn assigns ->
      player_name = assigns.id
      balance = PokerX.Bank.balance(player_name)
      Map.put(assigns, :balance, balance)
    end)
  end

  @impl true
  def render(assigns),
    do:
      PokerXWeb.ComponentView.render(
        "bank_component.html",
        assigns
      )

  @impl true
  def update(assigns, socket) do
    {:ok, assign(socket, assigns)}
  end

  @impl true
  def handle_event("bank_add_funds", %{"amount" => amount}, socket) do
    {amount, ""} = Integer.parse(amount)

    socket.assigns.id
    |> PokerX.Bank.deposit(amount)
    |> handle_poker_response(socket)
  end

  def handle_event("bank_remove_funds", %{"amount" => amount}, socket) do
    {amount, ""} = Integer.parse(amount)

    socket.assigns.id
    |> PokerX.Bank.withdraw(amount)
    |> handle_poker_response(socket)
  end

  defp handle_poker_response(:ok, socket), do: {:noreply, socket |> clear_flash |> fetch()}

  defp handle_poker_response({:error, %{reason: reason}}, socket) do
    {:noreply, put_flash(socket, :error, Atom.to_string(reason))}
  end

  def fetch(%{assigns: assigns} = socket) do
    player_name = assigns.id
    balance = PokerX.Bank.balance(player_name)
    assign(socket, balance: balance)
  end
end

defmodule DemoWeb.LiveComponent.TableModal do
  use Phoenix.LiveComponent

  def mount(socket) do
    {:ok, reset(socket)}
  end

  def render(assigns), do: PokerXWeb.ComponentView.render("table_modal.html", assigns)

  def update(_assigns, socket) do
    {:ok, socket}
  end

  def reset(socket) do
    assign(socket, new_table: %{name: "", player_count: 0})
  end
end

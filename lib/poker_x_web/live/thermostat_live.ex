defmodule PokerXWeb.ThermostatLive do
  use Phoenix.LiveView

  def render(assigns) do
    Phoenix.View.render(PokerXWeb.PageView, "page.html", assigns)
  end

  def mount(_params, data, socket) do
    if connected?(socket) do
      :timer.send_interval(1000, self(), :tick)
      PokerX.PlayerMapping.attach_browser(self())
    end

    {:ok, put_date(socket)}
  end

  def handle_info(:tick, socket) do
    {:noreply, put_date(socket)}
  end

  defp put_date(socket) do
    assign(socket,
      date: NaiveDateTime.local_now(),
      pids: PokerX.PlayerMapping.list_browser_sessions()
    )
  end
end

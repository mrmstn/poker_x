defmodule PokerX.PlayerMapping do
  use GenServer
  @name __MODULE__
  def start_link(default) when is_list(default) do
    GenServer.start_link(__MODULE__, default, name: @name)
  end

  @impl true
  def init(stack) do
    :timer.send_interval(1000, self(), {:check_alive})
    {:ok, stack}
  end

  def attach_browser(pid \\ nil) do
    pid = pid || self()
    GenServer.call(@name, {:attach_browser, pid})
  end

  def list_browser_sessions do
    GenServer.call(@name, {:list_sessions})
  end

  @impl true
  def handle_call({:attach_browser, pid}, _caller, state) do
    Process.monitor(pid)
    {:reply, :ok, [pid | state]}
  end

  def handle_call({:list_sessions}, _caller, state) do
    {:reply, state, state}
  end

  @impl true
  def handle_info({:DOWN, _ref, :process, pid, {:shutdown, :closed}}, state) do
    state = List.delete(state, pid)
    {:noreply, state}
  end

  def handle_info({:check_alive}, state) do
    state = Enum.filter(state, &Process.alive?/1)
    {:noreply, state}
  end

  def handle_info(_msg, state) do
    {:noreply, state}
  end
end

defmodule PokerX.Accounts.UserManager do
  use GenServer

  @name __MODULE__
  def start_link(default) when is_list(default) do
    GenServer.start_link(__MODULE__, default, name: @name)
  end

  def create(user) do
    GenServer.call(@name, {:create, user})
  end

  def list() do
    GenServer.call(@name, :list)
  end

  def insert(changeset) do
    item = Ecto.Changeset.apply_action!(changeset, :update)
    GenServer.call(@name, {:insert, item})
  end

  def insert(changeset) do
    item = Ecto.Changeset.apply_action!(changeset, :update)
    GenServer.call(@name, {:update, item})
  end

  def get(id) do
    GenServer.call(@name, {:get, id})
  end

  def delete(item) do
    GenServer.call(@name, {:delete, item})
  end

  # Server (callbacks)

  @impl true
  def init(stack) do
    {:ok, %{}}
  end

  def handle_call(:list, _, state) do
    reply = Enum.map(state, fn {key, value} -> value end)
    {:reply, reply, state}
  end

  def handle_call({:get, id}, _, state) do
    {:reply, Map.get(state, id), state}
  end

  def handle_call({:insert, item}, _, state) do
    id = Ecto.UUID.generate()
    item = %{item | id: id}
    state = Map.put(state, id, item)
    {:reply, {:ok, item}, state}
  end

  def handle_call({:update, item}, _, state) do
    state = Map.update(state, item.id, item)
    {:reply, {:ok, item}, state}
  end

  def handle_call({:delete, item}, _, state) do
    state = Map.delete(state, item.id)
    {:reply, {:ok, item}, state}
  end
end

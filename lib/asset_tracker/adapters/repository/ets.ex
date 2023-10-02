defmodule AssetTracker.Adapters.Repository.Ets do
  @moduledoc """
  Interface for interact with Repository providers
  """
  @behaviour AssetTracker.Ports.Repository
  @name :ets_repo
  use GenServer

  def start_link(_) do
    GenServer.start_link(__MODULE__, @name, name: @name)
  end

  def init(state) do
    Enum.each(tables(), &create_table/1)
    {:ok, state}
  end

  def insert(table, params), do: GenServer.call(@name, {:insert, table, params})
  def update(table, id, params), do: GenServer.call(@name, {:update, table, id, params})
  def get(table, id), do: GenServer.call(@name, {:get, table, id})

  def handle_call({:insert, table, params}, _from, state) do
    return = upsert(table, params.id, params)
    {:reply, return, state}
  end

  def handle_call({:update, table, id, params}, _from, state) do
    return = upsert(table, id, params)
    {:reply, return, state}
  end

  def handle_call({:get, table, id}, _from, state) do
    case :ets.lookup(table, id) do
      [] -> {:rply, {:error, :not_found}, state}
      [{_cart_id, value}] -> {:reply, {:ok, value}, state}
    end
  end

  def config do
    :asset_tracker
    |> Application.get_env(__MODULE__, [])
  end

  def tables do
    Keyword.fetch!(config(), :tables)
  end

  defp create_table(table_name) do
    :ets.new(table_name, [:set, :public, :named_table])
  end

  defp upsert(table, id, params) do
    :ets.insert(table, {id, params})
    {:ok, params}
  end
end

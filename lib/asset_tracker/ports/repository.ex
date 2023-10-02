defmodule AssetTracker.Ports.Repository do
  @adapter Application.compile_env!(:asset_tracker, [__MODULE__, :adapter])

  @type return :: {:ok, term()} | {:error, term()}

  @callback insert(table :: atom(), params :: any()) :: return()
  @callback update(table :: atom(), id :: binary(), params :: any()) :: return()
  @callback get(table :: atom(), id :: binary()) :: return()

  @spec insert(table :: atom(), params :: any()) :: return()
  defdelegate insert(table, params), to: @adapter

  @spec update(table :: atom(), id :: binary(), params :: any()) :: return()
  defdelegate update(table, id, params), to: @adapter

  @spec get(table :: atom(), id :: binary()) :: return()
  defdelegate get(table, id), to: @adapter
end

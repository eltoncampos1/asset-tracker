defmodule AssetTracker.Ports.Repository do
  @moduledoc """
  Interface for interacting with Repository Providers
  """
  @adapter Application.compile_env!(:asset_tracker, [__MODULE__, :adapter])

  @type return :: {:ok, term()} | {:error, term()}

  @callback insert(table :: atom(), params :: any()) :: return()
  @callback update(table :: atom(), id :: binary(), params :: any()) :: return()
  @callback get(table :: atom(), id :: binary()) :: return()
  @doc """
  Insert a new record

  ## Examples

      iex> AssetTracker.Ports.Repository.insert(table, params)
      {:ok, params}

  """
  @spec insert(table :: atom(), params :: any()) :: return()
  defdelegate insert(table, params), to: @adapter

  @doc """
  Update a existent record

  ## Examples

      iex> AssetTracker.Ports.Repository.update(table, id, new_params)
      {:ok, new_params}

  """
  @spec update(table :: atom(), id :: binary(), params :: any()) :: return()
  defdelegate update(table, id, params), to: @adapter

  @doc """
  get existent record

  ## Examples

      iex> AssetTracker.Ports.Repository.get(table, id)
      {:ok, record}

  """
  @spec get(table :: atom(), id :: binary()) :: return()
  defdelegate get(table, id), to: @adapter
end

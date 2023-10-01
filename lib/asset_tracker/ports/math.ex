defmodule AssetTracker.Ports.Math do
  @moduledoc """
  Interface for interacting with Math Providers
  """
  @adapter Application.compile_env!(:asset_tracker, [__MODULE__, :adapter])

  @type t :: @adapter.t()
  @type param :: integer() | @adapter.t()

  @callback add(x :: param(), y :: param()) :: t()
  @callback sub(x :: param(), y :: param()) :: t()
  @callback new(x :: param()) :: t()
  @callback mult(x :: param(), y :: param()) :: t()
  @callback divide(x :: param(), y :: param()) :: t()
  @callback to_integer(x :: t()) :: integer()

  @doc """
    Add two numbers x + y
  """
  @spec add(x :: param(), y :: param()) :: t()
  defdelegate add(x, y), to: @adapter

  @doc """
    Sub two numbers x - y
  """
  @spec sub(x :: param(), y :: param()) :: t()
  defdelegate sub(x, y), to: @adapter

  @doc """
    Creates a new instance of adapter type
  """
  @spec new(x :: param()) :: t()
  defdelegate new(x), to: @adapter

  @doc """
    Multiply two numbers x * y
  """
  @spec mult(x :: param(), y :: param()) :: t()
  defdelegate mult(x, y), to: @adapter

  @doc """
    Divide  two numbers x / y
  """
  @spec divide(x :: param(), y :: param()) :: t()
  defdelegate divide(x, y), to: @adapter

  @doc """
   Receives an input type t(), and turns into integer
  """
  @spec to_integer(x :: t()) :: integer()
  defdelegate to_integer(x), to: @adapter
end

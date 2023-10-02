defmodule AssetTracker.Adapters.Math.Decimal do
  @moduledoc """
  Decimal adapter for Math operations

  This was created because in the future we can change de Adapter for math / money operations
  for example using Money lib
  """

  # Why using genserver ? To set precision, needs to be set in each process where you want it to be in affect.

  @behaviour AssetTracker.Ports.Math

  @type t :: Decimal.t()

  @name :math_adapter
  use GenServer

  def start_link(_) do
    GenServer.start_link(__MODULE__, @name, name: @name)
  end

  def init(state) do
    Decimal.Context.set(%Decimal.Context{Decimal.Context.get() | precision: 5})
    {:ok, state}
  end

  def new(x) do
    GenServer.call(@name, {:new, x})
  end

  def add(x, y) do
    GenServer.call(@name, {:add, x, y})
  end

  def sub(x, y) do
    GenServer.call(@name, {:sub, x, y})
  end

  def divide(x, y) do
    GenServer.call(@name, {:divide, x, y})
  end

  def mult(x, y) do
    GenServer.call(@name, {:mult, x, y})
  end

  def to_integer(x) do
    GenServer.call(@name, {:to_integer, x})
  end

  def handle_call({:new, x}, _from, state) do
    result = Decimal.new(x)
    {:reply, result, state}
  end

  def handle_call({:divide, x, y}, _from, state) do
    result = Decimal.div(x, y)
    {:reply, result, state}
  end

  def handle_call({:mult, x, y}, _from, state) do
    result = Decimal.mult(x, y)
    {:reply, result, state}
  end

  def handle_call({:add, x, y}, _from, state) do
    result = Decimal.add(x, y)
    {:reply, result, state}
  end

  def handle_call({:sub, x, y}, _from, state) do
    result = Decimal.sub(x, y)
    {:reply, result, state}
  end

  def handle_call({:to_integer, x}, _from, state) do
    result = Decimal.to_integer(x)
    {:reply, result, state}
  end
end

defmodule AssetTracker.Core.Tracker do
  @moduledoc """
  Module to Asset_tracket
  """
  defstruct purchases: %{}, sales: %{}
  @type t :: %__MODULE__{}

  alias AssetTracker.Core.Asset

  @doc """
  Creates a new Tracker for assets

  ## Examples

      iex> AssetTracker.Core.Tracker.new()
      %AssetTracker.Core.Tracker{purchases: [], sales: []}

  """

  @spec new :: t()
  def new do
    %__MODULE__{}
  end

  @spec add_purchase(
          asset_tracker :: t(),
          asset_symbol :: String.t(),
          sell_date :: Date.t(),
          quantity :: integer(),
          unit_price :: integer()
        ) :: t()
  def add_purchase(asset_tracker, asset_symbol, sell_date, quantity, unit_price)
      when quantity > 0 and unit_price > 0 do
    purchase = Asset.new(asset_symbol, sell_date, quantity, Decimal.new(unit_price), :purchase)
    symbol = String.upcase(asset_symbol)

    %__MODULE__{
      purchases: Map.update(asset_tracker.purchases, symbol, [purchase], &(&1 ++ [purchase])),
      sales: asset_tracker.sales
    }
  end

  def add_purchase(_asset_tracker, _asset_symbol, _sell_date, _quantity, _unit_price),
    do: {:error, "The quantity and value must be grather than zero"}
end

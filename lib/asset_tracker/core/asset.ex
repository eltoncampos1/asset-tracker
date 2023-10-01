defmodule AssetTracker.Core.Asset do
  @moduledoc """
   Module to Asset Core
  """

  defstruct id: UUID.uuid4(),
            asset_symbol: nil,
            operation_date: nil,
            quantity: nil,
            unit_price: 0,
            operation_type: nil

  @type op :: :purchase | :sale

  @spec new(
          asset_symbol :: String.t(),
          settle_date :: Date.t(),
          quantity :: integer(),
          unit_price :: integer(),
          operation_type :: op
        ) :: %AssetTracker.Core.Asset{}
  def new(asset_simbol, settle_date, quantity, unit_price, operation) do
    %__MODULE__{
      asset_symbol: asset_simbol,
      operation_date: settle_date,
      quantity: quantity,
      unit_price: unit_price,
      operation_type: operation
    }
  end
end

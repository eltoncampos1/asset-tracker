defmodule AssetTracker.Core.Asset do
  @moduledoc """
   Module to Asset Core
  """

  defstruct id: nil,
            asset_symbol: nil,
            operation_date: nil,
            quantity: nil,
            unit_price: 0,
            operation_type: nil

  @type op :: :purchase | :sale

  @doc """
    Creates a new Asset

    ## Examples

        iex> AssetTracker.Core.Asset.new("APPL", Date.utc_today(), 10, 10, :purchase)
       %AssetTracker.Core.Asset{
          id: UUID.uuid4(),
          asset_symbol: "APPL",
          operation_date: ~D[2023-10-02],
          quantity: 10,
          unit_price: 10,
          operation_type: :purchase
        }

  """

  @spec new(
          asset_symbol :: String.t(),
          settle_date :: Date.t(),
          quantity :: integer(),
          unit_price :: integer(),
          operation_type :: op
        ) :: %AssetTracker.Core.Asset{}
  def new(asset_simbol, settle_date, quantity, unit_price, operation) do
    %__MODULE__{
      id: UUID.uuid4(),
      asset_symbol: asset_simbol,
      operation_date: settle_date,
      quantity: quantity,
      unit_price: unit_price,
      operation_type: operation
    }
  end
end

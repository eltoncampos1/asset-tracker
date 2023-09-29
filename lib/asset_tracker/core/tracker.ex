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
          settle :: Date.t(),
          quantity :: integer(),
          unit_price :: integer()
        ) :: t()
  def add_purchase(asset_tracker, asset_symbol, settle_date, quantity, unit_price)
      when quantity > 0 and unit_price > 0 do
    purchase = Asset.new(asset_symbol, settle_date, quantity, Decimal.new(unit_price), :purchase)
    symbol = String.upcase(asset_symbol)

    %__MODULE__{
      purchases: Map.update(asset_tracker.purchases, symbol, [purchase], &(&1 ++ [purchase])),
      sales: asset_tracker.sales
    }
  end

  def add_purchase(_asset_tracker, _asset_symbol, _sell_date, _quantity, _unit_price),
    do: {:error, "The quantity and value must be grather than zero"}

  @spec add_sale(
          asset_tracker :: t(),
          asset_symbol :: String.t(),
          seltle_date :: Date.t(),
          quantity :: integer(),
          unit_price :: integer()
        ) :: {t(), Decimal.t()}
  def add_sale(asset_tracker, asset_symbol, sell_date, quantity, unit_price)
      when quantity > 0 and unit_price > 0 do
    sale = Asset.new(asset_symbol, sell_date, quantity, Decimal.new(unit_price), :sale)
    symbol = String.upcase(asset_symbol)

    case update_inventory(asset_tracker, symbol, sale) do
      {:error, _reason} = error ->
        error

      {new_purchases, gain_or_loss} ->
        {%__MODULE__{
           purchases: Map.put(asset_tracker.purchases, symbol, new_purchases),
           sales: Map.update(asset_tracker.sales, symbol, [sale], &(&1 ++ [sale]))
         }, gain_or_loss}
    end
  end

  defp update_inventory(tracker, symbol, sale) do
    case Map.get(tracker.purchases, symbol) do
      nil ->
        {:error, :not_found}

      purchases when is_list(purchases) ->
        purchases
        |> find_earliest_purchase()
        |> calculate_purchases(sale)
    end
  end

  defp find_earliest_purchase([%Asset{quantity: quantity} | _purchases] = total)
       when quantity > 0,
       do: total

  defp find_earliest_purchase([_ | purchases]),
    do: find_earliest_purchase(purchases)

  defp calculate_purchases(
         [purchase | purchases] = total,
         %Asset{quantity: sale_qty} = sale
       ) do
    total_invetory = Enum.reduce(total, 0, &(&1.quantity + &2))

    if total_invetory < sale_qty do
      {:error, :insuficient_assets}
    else
      deduct_sold_quantity(purchase, purchases, sale, Decimal.new(0))
    end
  end

  defp deduct_sold_quantity(
         %Asset{quantity: pur_qty} = purchase,
         purchases,
         %Asset{quantity: sale_qty} = sale,
         gain_or_loss
       )
       when pur_qty > sale_qty do
    paid = Decimal.mult(sale_qty, sale.unit_price)
    value = Decimal.mult(sale_qty, purchase.unit_price)

    total =
      Decimal.sub(paid, value)
      |> Decimal.add(gain_or_loss)

    {[%Asset{purchase | quantity: pur_qty - sale_qty}] ++ purchases, total}
  end

  defp deduct_sold_quantity(%Asset{quantity: 0}, [purchase | purchases], sale, gain_or_loss) do
    deduct_sold_quantity(purchase, purchases, sale, gain_or_loss)
  end

  defp deduct_sold_quantity(
         %Asset{quantity: pur_qty} = purchase,
         purchases,
         %Asset{quantity: sale_qty} = sale,
         gain_or_loss
       ) do
    gain_or_loss =
      Decimal.sub(purchase.unit_price, sale.unit_price)
      |> Decimal.add(gain_or_loss)

    %{purchase | quantity: pur_qty - 1}
    |> deduct_sold_quantity(purchases, %{sale | quantity: sale_qty - 1}, gain_or_loss)
  end
end

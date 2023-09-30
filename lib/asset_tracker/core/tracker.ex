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

  @spec unrealized_gain_or_loss(tracker :: t(), symbol :: String.t(), market_price :: integer()) ::
          map()
  def unrealized_gain_or_loss(%__MODULE__{} = tracker, symbol, market_price) do
    %{
      sales: do_unrealized_gain_or_loss(tracker.sales, symbol, market_price),
      purchases: do_unrealized_gain_or_loss(tracker.purchases, symbol, market_price)
    }
  end

  defp do_unrealized_gain_or_loss(assets, symbol, market_price) do
    case get_assets_by_symbol(assets, symbol) do
      nil ->
        :not_found

      assets when is_list(assets) ->
        assets
        |> get_median_price()
        |> calculate_unrealized_gain_or_loss(market_price)
    end
  end

  defp calculate_unrealized_gain_or_loss({median, total_qty}, market_price) do
    market_price
    |> Decimal.add(median)
    |> Decimal.mult(total_qty)
  end

  defp get_median_price(assets) do
    %{price: price, qty: qty} =
      assets
      |> Enum.reduce(%{price: Decimal.new(0), qty: 0}, fn %{unit_price: price, quantity: qty},
                                                          acc ->
        %{price: Decimal.add(price, acc.price), qty: qty + acc.qty}
      end)

    {Decimal.div(price, qty), qty}
  end

  defp update_inventory(tracker, symbol, sale) do
    case get_assets_by_symbol(tracker.purchases, symbol) do
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

    total = calculate_gain_or_loss(paid, value, gain_or_loss)

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
    gain_or_loss = calculate_gain_or_loss(purchase.unit_price, sale.unit_price, gain_or_loss)

    %{purchase | quantity: pur_qty - 1}
    |> deduct_sold_quantity(purchases, %{sale | quantity: sale_qty - 1}, gain_or_loss)
  end

  defp calculate_gain_or_loss(paid, value, initial) do
    paid
    |> Decimal.sub(value)
    |> Decimal.add(initial)
  end

  defp get_assets_by_symbol(tracker, symbol), do: Map.get(tracker, symbol)
end

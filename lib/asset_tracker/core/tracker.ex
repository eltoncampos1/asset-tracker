defmodule AssetTracker.Core.Tracker do
  @moduledoc """
  Module to Asset_tracket
  """
  defstruct purchases: %{}, sales: %{}
  @type t :: %__MODULE__{}

  alias AssetTracker.Core.Asset

  alias AssetTracker.Ports.Math

  alias AssetTracker.Core.Errors

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
    purchase = Asset.new(asset_symbol, settle_date, quantity, unit_price, :purchase)
    symbol = String.upcase(asset_symbol)

    %__MODULE__{
      purchases: update_inventory(asset_tracker.purchases, symbol, purchase),
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
        ) :: {t(), integer()} | {:error, term()}
  def add_sale(asset_tracker, asset_symbol, sell_date, quantity, unit_price)
      when quantity > 0 and unit_price > 0 do
    sale = Asset.new(asset_symbol, sell_date, quantity, unit_price, :sale)
    symbol = String.upcase(asset_symbol)

    asset_tracker.purchases
    |> get_assets_by_symbol(symbol)
    |> find_earliest_purchase()
    |> calculate_purchases(sale)
    |> handle_add_sale(asset_tracker, symbol, sale)
  end

  def handle_add_sale({:error, _reason} = error, _asset, _symbol, _sale), do: error

  def handle_add_sale({new_purchases, gain_or_loss}, asset_tracker, symbol, sale) do
    {%__MODULE__{
       purchases: Map.put(asset_tracker.purchases, symbol, new_purchases),
       sales: update_inventory(asset_tracker.sales, symbol, sale)
     }, gain_or_loss}
  end

  defp update_inventory(inventory, symbol, item) do
    Map.update(inventory, symbol, :queue.from_list([item]), &:queue.in(item, &1))
  end

  @doc """
  Calculates the unrealized gain or loss using the base formula
  ` (market_price - unit_price_median) * quantity

  ## Examples
      iex> tracker = AssetTracker.Core.Tracker.new
      %AssetTracker.Core.Tracker{purchases: %{}, sales: %{}}
      iex> AssetTracker.Core.Tracker.add_purchase("GOOGL", Date.utc_today(), 10, 10)

      iex> AssetTracker.Core.Tracker.unrealized_gain_or_loss()
      %AssetTracker.Core.Tracker{purchases: [], sales: []}

  """

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

      assets ->
        assets
        |> :queue.to_list()
        |> get_median_price()
        |> calculate_gain_or_loss(market_price)
    end
  end

  defp get_median_price(assets) do
    %{price: price, qty: qty} =
      assets
      |> Enum.reduce(%{price: 0, qty: 0}, fn %{unit_price: price, quantity: qty}, acc ->
        %{price: Math.add(price, acc.price), qty: qty + acc.qty}
      end)

    {Math.divide(price, length(assets)), qty}
  end

  def find_earliest_purchase(nil), do: Errors.not_found()

  def find_earliest_purchase(purchases) do
    {{:value, %Asset{quantity: quantity} = purchase}, queue} = :queue.out(purchases)
    if quantity > 0, do: {purchase, :queue.to_list(queue)}, else: find_earliest_purchase(queue)
  end

  defp calculate_purchases(purchases, asset, gain_or_loss \\ 0)

  defp calculate_purchases(
         {%Asset{} = purchase, purchases},
         %Asset{quantity: sale_qty} = sale,
         gain_or_loss
       ) do
    total_invetory = Enum.reduce(purchases, 0, &(&1.quantity + &2)) + purchase.quantity

    if total_invetory < sale_qty do
      {:error, :insuficient_assets}
    else
      deduct_sold_quantity(purchase, purchases, sale, gain_or_loss)
    end
  end

  defp calculate_purchases({:error, _reason}, _, _), do: Errors.not_found()

  defp deduct_sold_quantity(
         %Asset{quantity: pur_qty} = purchase,
         purchases,
         %Asset{quantity: sale_qty} = sale,
         gain_or_loss
       )
       when pur_qty > sale_qty do
    total =
      calculate_gain_or_loss(sale.unit_price, purchase.unit_price, sale.quantity, gain_or_loss)

    {:queue.from_list(purchases ++ [%Asset{purchase | quantity: pur_qty - sale_qty}]), total}
  end

  defp deduct_sold_quantity(%Asset{quantity: 0}, purchases, sale, gain_or_loss) do
    purchases
    |> :queue.from_list()
    |> find_earliest_purchase()
    |> calculate_purchases(sale, gain_or_loss)
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

  defp calculate_gain_or_loss(paid, value, qty \\ 1, initial) do
    paid
    |> Math.sub(value)
    |> Math.mult(qty)
    |> Math.add(initial)
  end

  defp calculate_gain_or_loss({median, total_qty}, market_price) do
    market_price
    |> Math.sub(median)
    |> Math.mult(total_qty)
  end

  def get_assets_by_symbol(tracker, symbol), do: Map.get(tracker, symbol)
end

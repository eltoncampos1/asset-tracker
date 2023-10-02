defmodule AssetTracker.Core.Tracker do
  @moduledoc """
  Module to Asset_tracket
  """
  defstruct id: nil, purchases: %{}, sales: %{}
  @type t :: %__MODULE__{}

  alias AssetTracker.Core.Asset

  alias AssetTracker.Ports.Math
  alias AssetTracker.Tracker.Repository, as: TrackerRepo
  alias AssetTracker.Core.Errors

  @doc """
  Creates a new Tracker for assets

  ## Examples

      iex> AssetTracker.Core.Tracker.new()
      {:ok, %AssetTracker.Core.Tracker{id: UUID.uuid4(), purchases: [], sales: []}}

  """

  @spec new :: {:ok, t()}
  def new do
    %__MODULE__{
      id: UUID.uuid4()
    }
    |> TrackerRepo.insert()
  end

  @doc """
    Add new purchase to a asset tracker

    ## Examples

        iex> {:ok, tracker} = AssetTracker.Core.Tracker.new()
        {:ok, %AssetTracker.Core.Tracker{id: UUID.uuid4(), purchases: [], sales: []}}
        iex> AssetTracker.Core.Tracker.add_purchase(tracker, "GOOGL", Date.utc_today(), 10, 1000)
        %AssetTracker.Core.Tracker{
        id: UUID.uuid4(),
        purchases: %{
          "GOOGL" => {[
            %AssetTracker.Core.Asset{
              id: UUID.uuid4(),
              asset_symbol: "GOOGL",
              operation_date: ~D[2023-10-02],
              quantity: 10,
              unit_price: 1000,
              operation_type: :purchase
            }
          ], []}
        },
        sales: %{}
      }
  """

  @spec add_purchase(
          asset_tracker :: t(),
          asset_symbol :: String.t(),
          settle_date :: Date.t(),
          quantity :: integer(),
          unit_price :: integer()
        ) :: t()
  def add_purchase(asset_tracker, asset_symbol, settle_date, quantity, unit_price)
      when quantity > 0 and unit_price > 0 do
    purchase = Asset.new(asset_symbol, settle_date, quantity, unit_price, :purchase)
    symbol = String.upcase(asset_symbol)

    params = %__MODULE__{
      asset_tracker
      | purchases: update_inventory(asset_tracker.purchases, symbol, purchase),
        sales: asset_tracker.sales
    }

    case TrackerRepo.update(params.id, params) do
      {:ok, tracker} -> tracker
    end
  end

  def add_purchase(_asset_tracker, _asset_symbol, _sell_date, _quantity, _unit_price),
    do: {:error, "The quantity and value must be grather than zero"}

  @doc """
    Add new sale to a asset tracker and returns it with calculated gain or loss

    ## Examples

        iex> {:ok, tracker} = AssetTracker.Core.Tracker.new()
        {:ok, %AssetTracker.Core.Tracker{id: UUID.uuid4(), purchases: [], sales: []}}
        iex> tracker = AssetTracker.Core.Tracker.add_purchase(tracker, "GOOGL", Date.utc_today(), 10, 1000)
        %AssetTracker.Core.Tracker{
        id: UUID.uuid4(),
        purchases: %{
          "GOOGL" => {[
            %AssetTracker.Core.Asset{
              id: UUID.uuid4(),
              asset_symbol: "GOOGL",
              operation_date: ~D[2023-10-02],
              quantity: 10,
              unit_price: 1000,
              operation_type: :purchase
            }
          ], []}
        },
        sales: %{}
      }
      iex>AssetTracker.Core.Tracker.add_sale(tracker, "GOOGL", Date.utc_today(), 5, 1200)
      {%AssetTracker.Core.Tracker{
      id: UUID.uuid4(),
      purchases: %{
        "GOOGL" => {[
            %AssetTracker.Core.Asset{
              id: UUID.uuid4(),
              asset_symbol: "GOOGL",
              operation_date: ~D[2023-10-02],
              quantity: 5,
              unit_price: 1000,
              operation_type: :purchase
            }
          ], []}
      },
      sales: %{
        "GOOGL" => {[
            %AssetTracker.Core.Asset{
              id: UUID.uuid4(),
              asset_symbol: "GOOGL",
              operation_date: ~D[2023-10-02],
              quantity: 5,
              unit_price: 1200,
              operation_type: :sale
            }
          ], []}
      }
    }, Decimal.new("1000")}
  """

  @spec add_sale(
          asset_tracker :: t(),
          asset_symbol :: String.t(),
          sell_date :: Date.t(),
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
    |> update_repository(asset_tracker, symbol, sale)
  end

  defp update_repository({:error, _reason} = error, _asset, _symbol, _sale), do: error

  defp update_repository({new_purchases, gain_or_loss}, asset_tracker, symbol, sale) do
    params = %__MODULE__{
      asset_tracker
      | purchases: Map.put(asset_tracker.purchases, symbol, new_purchases),
        sales: update_inventory(asset_tracker.sales, symbol, sale)
    }

    case TrackerRepo.update(params.id, params) do
      {:ok, tracker} -> {tracker, gain_or_loss}
    end
  end

  defp update_inventory(inventory, symbol, item) do
    Map.update(inventory, symbol, :queue.from_list([item]), &:queue.in(item, &1))
  end

  @doc """
  Calculates the unrealized gain or loss using the base formula
  ` (market_price - unit_price_median) * quantity

  ## Examples
      iex> {:ok, tracker} = AssetTracker.Core.Tracker.new
      {:ok, %AssetTracker.Core.Tracker{purchases: %{}, sales: %{}}}
      iex> tracker= AssetTracker.Core.Tracker.add_purchase("GOOGL", Date.utc_today(), 10, 10)
      %AssetTracker.Core.Tracker{
      id: UUID.uuid4(),
      purchases: %{
        "GOOGL" => {[
          %AssetTracker.Core.Asset{
            id: UUID.uuid4(),
            asset_symbol: "GOOGL",
            operation_date: ~D[2023-10-02],
            quantity: 10,
            unit_price: 10,
            operation_type: :purchase
          }
        ], []}
      },
      sales: %{}
    }
    {tracker, gain} = AssetTracker.Core.add_sale(tracker, "GOOGL", Date.utc_today(), 5, 12)
    {%AssetTracker.Core.Tracker{
        id:  UUID.uuid4(),
        purchases: %{
          "GOOGL" => {[
              %AssetTracker.Core.Asset{
                id: UUID.uuid4(),
                asset_symbol: "GOOGL",
                operation_date: ~D[2023-10-02],
                quantity: 5,
                unit_price: 10,
                operation_type: :purchase
              }
            ], []}
        },
        sales: %{
          "GOOGL" => {[
              %AssetTracker.Core.Asset{
                id:  UUID.uuid4(),
                asset_symbol: "GOOGL",
                operation_date: ~D[2023-10-02],
                quantity: 5,
                unit_price: 12,
                operation_type: :sale
              }
            ], []}
        }
      }, Decimal.new("10")}
      iex> AssetTracker.Core.Tracker.unrealized_gain_or_loss(tracker, "GOOGL", 12)
      Decimal.new("10")
  """

  @spec unrealized_gain_or_loss(tracker :: t(), symbol :: String.t(), market_price :: integer()) ::
          Math.t()
  def unrealized_gain_or_loss(%__MODULE__{} = tracker, symbol, market_price) do
    case get_assets_by_symbol(tracker.purchases, symbol) do
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
       when pur_qty > sale_qty or pur_qty == sale_qty do
    total =
      calculate_gain_or_loss(sale.unit_price, purchase.unit_price, sale.quantity, gain_or_loss)

    if pur_qty - sale_qty == 0 do
      {:queue.from_list(purchases), total}
    else
      {:queue.from_list([%Asset{purchase | quantity: pur_qty - sale_qty}] ++ purchases), total}
    end
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

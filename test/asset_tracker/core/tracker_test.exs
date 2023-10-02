defmodule AssetTracker.Core.TrackerTest do
  use ExUnit.Case

  alias AssetTracker.Core.Tracker

  alias AssetTracker.Ports.Math

  describe "Core Asset Tracker" do
    setup do
      {:ok, tracker} = Tracker.new()
      %{tracker: tracker}
    end

    test "new/0" do
      assert {:ok, %Tracker{purchases: %{}, sales: %{}, id: _}} = Tracker.new()
    end

    test "add_purchase/5", %{tracker: tracker} do
      date = Date.utc_today()

      assert %AssetTracker.Core.Tracker{
               id: _,
               purchases: %{
                 "GOOGL" =>
                   {[
                      %AssetTracker.Core.Asset{
                        id: _,
                        asset_symbol: "GOOGL",
                        operation_date: ^date,
                        quantity: 10,
                        unit_price: price,
                        operation_type: :purchase
                      }
                    ], []}
               },
               sales: %{}
             } = Tracker.add_purchase(tracker, "GOOGL", date, 10, 19)

      assert ^price = 19
    end

    test "error on add purchases with invalid quantity", %{tracker: tracker} do
      date = Date.utc_today()

      assert {:error, "The quantity and value must be grather than zero"} =
               Tracker.add_purchase(tracker, "GOOGL", date, 0, 19)

      assert {:error, "The quantity and value must be grather than zero"} =
               Tracker.add_purchase(tracker, "GOOGL", date, 0, 19)

      assert {:error, "The quantity and value must be grather than zero"} =
               Tracker.add_purchase(tracker, "GOOGL", date, -1, 19)
    end

    test "add_sale/5", %{tracker: tracker} do
      symbol = "GOOGL"
      price_first = 5
      price_second = 10
      sold = 12

      assert {%AssetTracker.Core.Tracker{
                id: _,
                purchases: %{
                  "GOOGL" =>
                    {[
                       %AssetTracker.Core.Asset{
                         id: _,
                         asset_symbol: ^symbol,
                         operation_date: _,
                         quantity: 10,
                         unit_price: ^price_second,
                         operation_type: :purchase
                       }
                     ],
                     [
                       %AssetTracker.Core.Asset{
                         id: _,
                         asset_symbol: ^symbol,
                         operation_date: _,
                         quantity: 5,
                         unit_price: ^price_first,
                         operation_type: :purchase
                       }
                     ]}
                },
                sales: %{
                  "GOOGL" =>
                    {[
                       %AssetTracker.Core.Asset{
                         id: _,
                         asset_symbol: _,
                         operation_date: _,
                         quantity: 5,
                         unit_price: 12,
                         operation_type: :sale
                       }
                     ], []}
                }
              },
              gain_or_loss} =
               tracker
               |> Tracker.add_purchase("GOOGL", Date.utc_today(), 10, price_first)
               |> Tracker.add_purchase("GOOGL", Date.utc_today(), 10, price_second)
               |> Tracker.add_sale(symbol, Date.utc_today(), 5, sold)

      purchase = Math.mult(price_first, 5)
      paid = Math.mult(sold, 5)
      assert gain_or_loss == Math.sub(paid, purchase)
    end

    test "delete the purchase if qty  == 0", %{tracker: tracker} do
      tracker =
        tracker
        |> Tracker.add_purchase("GOOGL", Date.utc_today(), 10, 10)
        |> Tracker.add_purchase("GOOGL", Date.utc_today(), 10, 10)

      {tracker, _} =
        tracker
        |> Tracker.add_sale("GOOGL", Date.utc_today(), 5, 5)

      assert %AssetTracker.Core.Tracker{
               id: _,
               purchases: %{
                 "GOOGL" =>
                   {[
                      %AssetTracker.Core.Asset{
                        id: id_second,
                        asset_symbol: "GOOGL",
                        operation_date: _,
                        quantity: 10,
                        unit_price: 10,
                        operation_type: :purchase
                      }
                    ],
                    [
                      %AssetTracker.Core.Asset{
                        id: _,
                        asset_symbol: "GOOGL",
                        operation_date: _,
                        quantity: 5,
                        unit_price: 10,
                        operation_type: :purchase
                      }
                    ]}
               },
               sales: %{
                 "GOOGL" =>
                   {[
                      %AssetTracker.Core.Asset{
                        id: _,
                        asset_symbol: "GOOGL",
                        operation_date: _,
                        quantity: 5,
                        unit_price: 5,
                        operation_type: :sale
                      }
                    ], []}
               }
             } = tracker

      {tracker, _} =
        tracker
        |> Tracker.add_sale("GOOGL", Date.utc_today(), 10, 5)

      assert %AssetTracker.Core.Tracker{
               id: _,
               purchases: %{
                 "GOOGL" =>
                   {[
                      %AssetTracker.Core.Asset{
                        id: ^id_second,
                        asset_symbol: "GOOGL",
                        operation_date: _,
                        quantity: 5,
                        unit_price: 10,
                        operation_type: :purchase
                      }
                    ], []}
               },
               sales: %{
                 "GOOGL" =>
                   {[
                      %AssetTracker.Core.Asset{
                        id: _,
                        asset_symbol: "GOOGL",
                        operation_date: _,
                        quantity: 10,
                        unit_price: 5,
                        operation_type: :sale
                      }
                    ],
                    [
                      %AssetTracker.Core.Asset{
                        id: _,
                        asset_symbol: "GOOGL",
                        operation_date: _,
                        quantity: 5,
                        unit_price: 5,
                        operation_type: :sale
                      }
                    ]}
               }
             } = tracker
    end

    test "Always update inventory based on FIFO", %{tracker: tracker} do
      symbol = "GOOGL"
      first = 10
      second = 20

      tracker =
        tracker
        |> Tracker.add_purchase(symbol, Date.utc_today(), first, 10)

      assert %AssetTracker.Core.Tracker{
               id: tracker_id,
               purchases: %{
                 "GOOGL" =>
                   {[
                      %AssetTracker.Core.Asset{
                        id: first_id,
                        asset_symbol: "GOOGL",
                        operation_date: _,
                        quantity: 10,
                        unit_price: 10,
                        operation_type: :purchase
                      }
                    ], []}
               },
               sales: %{}
             } = tracker

      tracker =
        tracker
        |> Tracker.add_purchase(symbol, Date.utc_today(), second, 11)

      assert %AssetTracker.Core.Tracker{
               id: ^tracker_id,
               purchases: %{
                 "GOOGL" =>
                   {[
                      %AssetTracker.Core.Asset{
                        id: second_id,
                        asset_symbol: "GOOGL",
                        operation_date: _,
                        quantity: 20,
                        unit_price: 11,
                        operation_type: :purchase
                      }
                    ],
                    [
                      %AssetTracker.Core.Asset{
                        id: ^first_id,
                        asset_symbol: "GOOGL",
                        operation_date: _,
                        quantity: 10,
                        unit_price: 10,
                        operation_type: :purchase
                      }
                    ]}
               },
               sales: %{}
             } = tracker

      {tracker, _} =
        tracker
        |> Tracker.add_sale(symbol, Date.utc_today(), 2, 10)

      assert %AssetTracker.Core.Tracker{
               id: ^tracker_id,
               purchases: %{
                 "GOOGL" =>
                   {[
                      %AssetTracker.Core.Asset{
                        id: ^second_id,
                        asset_symbol: "GOOGL",
                        operation_date: _,
                        quantity: ^second,
                        unit_price: 11,
                        operation_type: :purchase
                      }
                    ],
                    [
                      %AssetTracker.Core.Asset{
                        id: ^first_id,
                        asset_symbol: "GOOGL",
                        operation_date: _,
                        quantity: new_first_qty,
                        unit_price: 10,
                        operation_type: :purchase
                      }
                    ]}
               },
               sales: %{
                 "GOOGL" =>
                   {[
                      %AssetTracker.Core.Asset{
                        id: _,
                        asset_symbol: "GOOGL",
                        operation_date: _,
                        quantity: 2,
                        unit_price: 10,
                        operation_type: :sale
                      }
                    ], []}
               }
             } = tracker

      assert new_first_qty == first - 2
    end

    test "returns error on sale if total invetory is less than sale qty", %{tracker: tracker} do
      assert {:error, :insuficient_assets} =
               tracker
               |> Tracker.add_purchase("GOOGL", Date.utc_today(), 5, 1000)
               |> Tracker.add_sale("GOOGL", Date.utc_today(), 15, 2000)
    end

    test "returns error on sale if does not have the asset on inventory", %{tracker: tracker} do
      assert {:error, :not_found} =
               tracker
               |> Tracker.add_purchase("GOOGL", Date.utc_today(), 5, 1000)
               |> Tracker.add_sale("APPL", Date.utc_today(), 15, 2000)
    end

    test "calculate unrealized gain or loss for sales and purchases", %{tracker: tracker} do
      symbol = "APPL"

      tracker =
        tracker
        |> Tracker.add_purchase(symbol, Date.utc_today(), 10, 10)
        |> Tracker.add_purchase(symbol, Date.utc_today(), 12, 11)

      {tracker, _} =
        tracker
        |> Tracker.add_sale(symbol, Date.utc_today(), 6, 10)

      assert p = Tracker.unrealized_gain_or_loss(tracker, symbol, 15)

      assert p == Math.new(p)
    end

    test "returns error if no has no asset in inventory on unrealized_gain_or_loss call", %{
      tracker: tracker
    } do
      assert :not_found = Tracker.unrealized_gain_or_loss(tracker, "ADDR", 15)
    end
  end
end

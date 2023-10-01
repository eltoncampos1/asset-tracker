defmodule AssetTracker do
  @moduledoc """
    Delegates funcions to core
  """

  alias AssetTracker.Core

  defdelegate new, to: Core.Tracker, as: :new

  defdelegate add_purchase(tracker, symbol, settle_date, quantity, unit_price),
    to: Core.Tracker,
    as: :add_purchase

  defdelegate add_sale(tracker, symbol, settle_date, quantity, unit_price),
    to: Core.Tracker,
    as: :add_sale

  defdelegate unrealized_gain_loss(tracker, symbol, market_price),
    to: Core.Tracker,
    as: :unrealized_gain_or_loss
end

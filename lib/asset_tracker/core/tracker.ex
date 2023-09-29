defmodule AssetTracker.Core.Tracker do
  @moduledoc """
  Module to Asset_tracket
  """
  defstruct purchases: %{}, sales: %{}
  @type t :: %__MODULE__{}
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
end

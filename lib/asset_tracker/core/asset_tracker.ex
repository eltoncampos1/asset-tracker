defmodule AssetTracker.Core.AssetTracker do
  @moduledoc """
  Module to Asset_tracket
  """
  defstruct purchases: [], sales: []
  @type t :: %__MODULE__{}

 @doc """
  Creates a new AssetTracker

  ## Examples

      iex> AssetTracker.Core.AssetTracker.new()
      %AssetTracker.Core.AssetTracker{purchases: [], sales: []}

  """

  @spec new :: t()
  def new do
    %__MODULE__{}
  end
end

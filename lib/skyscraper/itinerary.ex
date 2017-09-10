defmodule Skyscraper.Itinerary do
  def cheapest_price(%{ "pricing_options" => pricing_options }) do
    min_pricing_option = Enum.min_by(
      pricing_options,
      &get_price/1
    )

    get_price(min_pricing_option)
  end

  def duration_depart(%{ "legs" => [ %{ "duration" => duration }, _ ] }) do
    format_minutes_count(duration)
  end
  def duration_return(%{ "legs" => [ _, %{ "duration" => duration } ] }) do
    format_minutes_count(duration)
  end

  defp get_price(%{ "price" => %{ "amount" => amount }}), do: amount
  defp get_price(_other), do: nil

  defp format_minutes_count(minutes) do
    hours = div(minutes, 60)
    "#{hours}h#{rem(minutes, 60)}m"
  end
end

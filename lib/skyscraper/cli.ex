defmodule Skyscraper.CLI do
  @thread_count 3

  def main(args \\ []) do
    parse_args(args)
    |> process
  end

  defp parse_args(argv) do
    parse = OptionParser.parse(
      argv,
      switches: [
        from: :string,
        to: :string,
        depart: :string,
        return: :string
      ]
    )

    case parse do
      { [ from: from, to: to, depart: depart, return: return ], _, _ } ->
        { from, to, get_range(depart), get_range(return) }
    end
  end

  defp process({ from, to, depart_range, return_range }) do
    destinations = String.split(to, ",")

    combinations = for to <- destinations,
      depart <- Enum.to_list(depart_range),
      return <- Enum.to_list(return_range),
      do: %{ to: to, depart: depart, return: return }

    combinations
    |> Enum.chunk_every(@thread_count)
    |> Enum.map(
      fn (batch) ->
        batch
        |> process_batch(from)
      end
    )
    |> List.flatten
    |> compact
    |> Enum.sort_by(fn (%{ price: price }) -> price end)
    |> Enum.take(20)
    |> IO.inspect
  end

  defp get_range(date_range_as_cli_argument) do
    [ range_start, range_end ] = String.split(date_range_as_cli_argument, "..")
                                 |> Enum.map(
                                   fn (s) ->
                                     { :ok, s } = Date.from_iso8601(s)
                                     s
                                   end
                                 )

    Date.range(range_start, range_end)
  end

  defp process_batch(batch, from) do
    batch
    |> Enum.map(
      fn (%{ to: to, depart: depart, return: return }) ->
        Task.async(fn ->
          Skyscraper.Skyscanner.get_itineraries(from, to, depart, return)
        end)
      end
    )
    |> Enum.map(&Task.await/1)
  end

  defp compact([ nil | tail]), do: compact(tail)
  defp compact([ head | tail]), do: [ head | compact(tail) ]
  defp compact([]), do: []
end

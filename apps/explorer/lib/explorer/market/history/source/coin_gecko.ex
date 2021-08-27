defmodule Explorer.Market.History.Source.CoinGecko do
  @moduledoc """
  Adapter for fetching market history from https://cryptocompare.com.

  The history is fetched for the configured coin. You can specify a
  different coin by changing the targeted coin.

      # In config.exs
      config :explorer, coin: "POA"

  """

  alias Explorer.Market.History.Source
  alias HTTPoison.Response

  @behaviour Source

  @typep unix_timestamp :: non_neg_integer()

  @impl Source
  def fetch_history(previous_days) do
    url = history_url(previous_days)
    headers = [{"Content-Type", "application/json"}]

    case HTTPoison.get(url, headers) do
      {:ok, %Response{body: body, status_code: 200}} ->
        result =
          body
          |> format_data()
          |> reject_zeros()

        {:ok, result}

      _ ->
        :error
    end
  end

  @spec base_url :: String.t()
  defp base_url do
    configured_url = Application.get_env(:explorer, __MODULE__, [])[:base_url]
    configured_url || "https://api.coingecko.com/api/v3"
  end

  @spec date(unix_timestamp()) :: Date.t()
  defp date(unix_timestamp) do
    unix_timestamp
    |> DateTime.from_unix!()
    |> DateTime.to_date()
  end

  @spec format_data(String.t()) :: [Source.record()]
  defp format_data(data) do
    json = Jason.decode!(data)

    for item <- json["prices"] do
      %{
        closing_price: Decimal.new(to_string(item[1])),
        date: date(item[0]),
        opening_price: Decimal.new(to_string(item[1]))
      }
    end
  end

  @spec history_url(non_neg_integer()) :: String.t()
  defp history_url(previous_days) do
    query_params = %{
      "vs_currency" => "usd",
      "days" => previous_days,
      "interval" => "daily"
    }

    "#{base_url()}/coins/bitcoin/market_chart?#{URI.encode_query(query_params)}"
  end

  defp reject_zeros(items) do
    Enum.reject(items, fn item ->
      Decimal.equal?(item.closing_price, 0) && Decimal.equal?(item.opening_price, 0)
    end)
  end
end

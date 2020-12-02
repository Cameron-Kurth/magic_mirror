defmodule MagicMirrorWeb.WeatherLive do
  use MagicMirrorWeb, :live_view

  @location Application.get_env(:magic_mirror, :location)
  @key Application.get_env(:magic_mirror, :weatherbit_api_key)

  def mount(_params, _session, socket) do
    if connected?(socket), do: :timer.send_interval(1000 * 60 * 15, self(), :update)

    {:ok, put_weather(socket)}
  end

  def handle_info(:update, socket) do
    {:noreply, put_weather(socket)}
  end

  def render(assigns) do
    ~L"""
    <div id="top-right">
      <h1 id="location"><%= @location %></h1>
      <h1 id="temp"><span><image src="<%= get_weather_icon(@current["weather"]["code"], :current) %>" style="height: 87.5px"> <%= celsius_to_fahrenheit(@current["temp"]) %>º</h1></span>
      <h2 id="temp"
        <span id="high">H <%= celsius_to_fahrenheit(@today_forecast["high_temp"]) %></span>
        <span id="low">L <%= celsius_to_fahrenheit(@today_forecast["low_temp"]) %></span>
      </h2>
      <table id="forecasts">
        <%= for {day, index} <- Enum.with_index(@forecast) do %>
          <tr style="opacity: <%= 1 - (index * 0.1) %>">
          <td><%= get_day_of_week(day["datetime"]) %></td>
          <td><image src="<%= get_weather_icon(day["weather"]["code"]) %>" style="height: 37.5px"></td>
          <td id="forecast"><span id="high"><%= celsius_to_fahrenheit(day["high_temp"]) %></span><span id="low"><%= celsius_to_fahrenheit(day["low_temp"]) %></span></td>
          </tr>
        <% end %>
      </table>
    </div>
    """
  end

  defp put_weather(socket) do
    current = get_current_weather!(@location)
    forecast = get_forecasted_weather!(@location)

    city = forecast["city_name"]
    state = forecast["state_code"]

    assign(socket,
      location: "#{city}, #{state}",
      current: current["data"] |> List.first(),
      today_forecast: forecast["data"] |> List.first(),
      forecast: forecast["data"] |> Enum.slice(1..10)
    )
  end

  def get_current_weather!(location) do
    HTTPoison.get!("https://api.weatherbit.io/v2.0/current", [],
      params: %{key: @key, city: location}
    ).body
    |> Jason.decode!()
  end

  defp get_forecasted_weather!(location) do
    HTTPoison.get!("https://api.weatherbit.io/v2.0/forecast/daily", [],
      params: %{key: @key, city: location}
    ).body
    |> Jason.decode!()
  end

  defp celsius_to_fahrenheit(celsius) do
    fahrenheit = celsius * (9 / 5) + 32
    fahrenheit |> round()
  end

  defp get_day_of_week(date) do
    date |> Timex.parse!("{YYYY}-{M}-{D}") |> Timex.weekday() |> Timex.day_shortname()
  end

  defp day_or_night?(hour_of_day) when hour_of_day >= 6 and hour_of_day < 20, do: "day"
  defp day_or_night?(hour_of_day) when hour_of_day < 6 or hour_of_day >= 20, do: "night"

  defp get_weather_icon(code, opt \\ nil)

  defp get_weather_icon(code, :current) do
    current_hour = MagicMirrorWeb.ClockLive.get_current_hour()
    day_or_night = day_or_night?(current_hour)

    get_weather_icon(code, day_or_night)
  end

  defp get_weather_icon(code, opt) do
    icon_name =
      cond do
        code >= 200 && code < 300 -> "storm-#{opt}"
        code >= 300 && code < 400 -> "rain-#{opt}"
        code >= 500 && code < 600 -> "rain-#{opt}"
        code >= 600 && code < 700 -> "snow-#{opt}"
        code >= 700 && code < 800 -> "fog-#{opt}"
        code == 800 -> "clear-#{opt}"
        code == 801 -> "mostly-clear-#{opt}"
        code == 802 -> "partly-cloudy-#{opt}"
        code == 803 || code == 804 -> "cloudy-#{opt}"
        true -> "na"
      end
      |> String.trim_trailing("-")

    "/images/#{icon_name}.png"
  end
end

defmodule MagicMirrorWeb.ClockLive do
  use MagicMirrorWeb, :live_view

  def mount(_params, _session, socket) do
    if connected?(socket), do: :timer.send_interval(1000, self(), :tick)

    {:ok, put_time(socket)}
  end

  def handle_info(:tick, socket) do
    {:noreply, put_time(socket)}
  end

  def get_current_hour() do
    datetime = Timex.now("America/Chicago")
    datetime.hour
  end

  def get_current_meridiem_period() do
    datetime = Timex.now("America/Chicago")
    {_hour, period} = Timex.Time.to_12hour_clock(datetime.hour)
    period
  end

  defp put_time(socket) do
    datetime = Timex.now("America/Chicago")

    assign(socket,
      year: datetime.year,
      month: datetime.month |> Timex.month_shortname(),
      day: datetime.day,
      weekday: datetime |> Timex.weekday() |> Timex.day_name(),
      hour: datetime.hour |> to_string() |> String.pad_leading(2, "0"),
      minute: datetime.minute |> to_string() |> String.pad_leading(2, "0"),
      second: datetime.second |> to_string() |> String.pad_leading(2, "0")
    )
  end

  def render(assigns) do
    ~L"""
    <h1 id="weekday"><%= @weekday %></h1>
    <h1 id="time"><%= @hour %>:<%= @minute %><span id="second"><%= @second %></span></h1>
    <h1 id="date"><%= @month %> <%= @day %>, <%= @year %></h1>
    """
  end
end

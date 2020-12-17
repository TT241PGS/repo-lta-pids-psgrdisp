defmodule Display.Utils.TimeUtil do
  @moduledoc false

  use Timex
  require Logger

  def get_timezone do
    Timezone.get("Asia/Singapore")
  end

  defp get_test_date_time do
    callers = Process.get(:"$callers")
    caller = if callers == nil, do: [], else: List.last(callers)

    case Cachex.get(:display, caller) do
      {:ok, nil} ->
        {:error, :not_found}

      {:ok, date_time} ->
        date_time = date_time <> "+08:00"
        DateTime.from_iso8601(date_time)

      _ ->
        {:error, :not_found}
    end
  end

  def get_time_now do
    case get_test_date_time() do
      {:ok, now, _} ->
        now
        |> Timezone.convert(get_timezone())

      _ ->
        Timezone.convert(Timex.now(), get_timezone())
    end
  end

  def get_beginning_of_day do
    get_time_now()
    |> Timex.beginning_of_day()
  end

  def get_today_date_string do
    Timex.format!(DateTime.utc_now(), "%Y-%m-%d", :strftime)
  end

  def get_current_time do
    get_time_now()
    |> Timex.format!("%H:%M", :strftime)
  end

  def get_display_date_time do
    %{
      day: Timex.format!(get_time_now(), "%A", :strftime),
      date: Timex.format!(get_time_now(), "%d %B %Y", :strftime),
      time: Timex.format!(get_time_now(), "%H:%M", :strftime)
    }
  end

  def get_iso_date_from_seconds(seconds) do
    get_beginning_of_day()
    |> Timex.add(Timex.Duration.from_seconds(seconds))
    |> Timex.format!("%FT%T%:z", :strftime)
  end

  def format_iso_date_to_hh_mm(iso_date) do
    iso_date
    |> Timex.parse!("{ISO:Extended}")
    |> Timex.format!("%H:%M", :strftime)
  end

  def get_eta_from_seconds_past_today(seconds) do
    seconds
    |> get_iso_date_from_seconds()
    |> format_time_to_eta_mins
  end

  def get_elapsed_time(nil), do: nil

  def get_elapsed_time(start_time) do
    get_time_now()
    |> Timex.diff(start_time)
    |> Timex.Duration.from_microseconds()
    |> Timex.format_duration(:humanized)
  end

  def get_seconds_past_today do
    get_time_now() |> Timex.diff(get_beginning_of_day, :seconds)
  end

  def get_weekday_name(nil), do: nil

  def get_weekday_name(date) do
    date
    |> Timex.weekday()
    |> Timex.day_name()
  end

  def get_weekday_no(nil), do: nil

  def get_weekday_no(date) do
    date
    |> Timex.weekday()
  end

  def is_public_holiday?(nil), do: nil

  def is_public_holiday?(date) do
    public_holidays = %{
      "2020-01-01" => "New Year's Day",
      "2020-01-25" => "Chinese New Year\n",
      "2020-01-26" => "Chinese New Year\n",
      "2020-04-10" => "Good Friday",
      "2020-05-01" => "Labour Day",
      "2020-05-07" => "Vesak Day",
      "2020-05-24" => "Hari Raya Puasa",
      "2020-07-10" => "Polling Day",
      "2020-07-31" => "Hari Raya Haji",
      "2020-08-09" => "National Day",
      "2020-11-14" => "Deepavali",
      "2020-12-25" => "Christmas Day"
    }

    case Map.get(public_holidays, date) do
      nil -> false
      _ -> true
    end
  end

  def format_time_to_eta_mins(nil), do: ""

  def format_time_to_eta_mins(time) do
    eta = get_eta_in_seconds(time)

    cond do
      eta <= 59 ->
        "Arr"

      eta >= 3600 ->
        "> 60 min"

      true ->
        "#{floor(eta / 60)} min"
    end
  end

  def format_min_to_eta_mins(nil), do: nil

  def format_min_to_eta_mins(eta) do
    cond do
      eta <= 0 ->
        "Arr"

      eta > 60 ->
        "> 60 min"

      true ->
        "#{eta} min"
    end
  end

  def get_eta_in_seconds(nil), do: nil

  def get_eta_in_seconds(time) do
    time
    |> DateTime.from_iso8601()
    |> elem(1)
    |> Time.diff(DateTime.utc_now(), :second)
  end

  def get_eta_in_minutes(nil), do: nil

  def get_eta_in_minutes(time) do
    seconds = get_eta_in_seconds(time)
    floor(seconds / 60)
  end
end

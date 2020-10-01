defmodule Display.Utils.TimeUtil do
  @moduledoc false

  use Timex

  def get_timezone do
    Timezone.get("Asia/Singapore")
  end

  def get_time_now do
    Timezone.convert(Timex.now(), get_timezone())
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
end
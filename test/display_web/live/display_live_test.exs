defmodule DisplayWeb.DisplayTest do
  use DisplayWeb.ConnCase

  import Phoenix.LiveViewTest

  test "initial render", %{conn: conn} do
    {:ok, view, initial_html} = live(conn, "/display?panel_id=pid0001")
    assert initial_html =~ "Loading..."
  end

  test "template render with predictions and messages", %{conn: conn} do
    # Cache predictions
    bus_arrival_predictions = File.read!("./test/fixtures/bus_arrival_predictions_14131.json")
    key = "pids:bus_arrivals"
    Display.Redix.command(["HMSET", key, "14131", bus_arrival_predictions])

    {:ok, view, initial_html} = live(conn, "/display?panel_id=pid0001")
    assert initial_html =~ "Loading..."
    # Render after retrieving all the panel data
    Process.sleep(100)
    assert render(view) =~ "14131"
    assert render(view) =~ "CARIBBEAN AT KEPPEL BAY"
    assert render(view) =~ "14131"
    assert render(view) =~ "150"
    assert render(view) =~ "60 min"
    assert render(view) =~ "Train services will be suspended from 6am to 7pm tomorrow"
  end
end

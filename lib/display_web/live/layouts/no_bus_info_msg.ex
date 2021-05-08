defmodule NoBusInfoMessage do
  @moduledoc false
  use Surface.LiveComponent

  property(prop, :map, default: %{})

  def render(assigns) do
    ~H"""
    <div style="
      text-align: center;
      display: flex;
      flex-direction: column;
      align-items: center;
      justify-content: center;
      font-size: 6vh;
      font-family: Verdana;
      height: 100%;
      color: white;
    ">
        <p style="margin: 10px;">
          Bus Arrival information is not currently available from this panel.
        </p>
        <p style="margin: 10px;">
          Please refer to poster at the shelter for information on bus services.
        </p>
    </div>
    """
  end
end

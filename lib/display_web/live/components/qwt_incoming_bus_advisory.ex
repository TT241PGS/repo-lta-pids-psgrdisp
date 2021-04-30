defmodule QwtIncomingBusAdvisoryPortrait do
  @moduledoc false
  use Surface.LiveComponent

  alias DisplayWeb.DisplayLive.Utils
  property(pane, :string, default: "pane1")
  property(prop, :map, default: %{})

  def render(assigns) do
    ~H"""
    <div>
      <div :if={{(Utils.get_content_type(@prop.current_layout_panes,  @pane) == "next_buses_arriving_at_stop")}}>
        <IncomingBusPortrait incoming_buses={{@prop.incoming_buses}} :if={{length(@prop.incoming_buses) > 0}} />
      </div>
      <div :if={{(Utils.get_content_type(@prop.current_layout_panes,  @pane) == "quickest_way_to")}}>
        <QuickestWayToPortrait qwts={{@prop.quickest_way_to}} :if={{length(@prop.quickest_way_to) > 0}} maxLength=1 />
      </div>
      <div :if={{(Utils.get_content_type(@prop.current_layout_panes,  @pane) == "scheduled_and_ad_hoc_messages")}}>
        <AdvisoriesPortrait
          message={{@prop.message}}
          :if={{
            (Utils.get_content_type(@prop.current_layout_panes,  @pane) == "scheduled_and_ad_hoc_messages") and
            @prop.message != %{}
          }}
          current_pane={{@pane}}
          panes={{@prop.current_layout_panes}}
        />
      </div>
    </div>
    """
  end
end

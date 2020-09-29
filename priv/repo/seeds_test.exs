# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     Display.Repo.insert!(%SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

alias Display.{Buses, Messages, Repo, Templates}

create_panel_bus_table_query =
  """
  CREATE TABLE panel_bus (
    base_version integer,
    id uuid,
    panel_id character varying(255),
    bus_stop_no integer,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL
  );
  """

create_stop_table_query =
  """
  CREATE TABLE stop (
    base_version integer,
    point_type integer,
    point_no integer,
    point_desc character varying(255),
    stop_no integer,
    stop_type integer,
    stop_long_no integer,
    stop_abbr character varying(255),
    stop_desc character varying(255),
    zone_cell_no integer,
    point_longitude double precision,
    point_latitude double precision,
    point_elevation integer,
    point_heading integer,
    stop_no_local integer,
    stop_no_national integer,
    stop_no_international character varying(255),
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL,
    CONSTRAINT stop_pkey PRIMARY KEY (base_version, point_type, point_no)
  );
  """

create_message_data_table_query =
  """
  CREATE TABLE cms_message_data (
    message_data_id character varying(255) PRIMARY KEY,
    name character varying(255),
    type character varying(255),
    priority character varying(255),
    start_date_time timestamp without time zone,
    end_date_time timestamp without time zone,
    start_time_1 character varying(255),
    end_time_1 character varying(255),
    day_type_1 boolean,
    day_type_2 boolean,
    day_type_3 boolean,
    message_content character varying(1000)
  );
  """

create_message_assignment_table_query =
  """
  CREATE TABLE cms_message_assignment (
      message_data_id character varying(255),
      bus_stop_panel_id character varying(255),
      bus_stop_group_id character varying(255),
      bus_stop_id character varying(255),
      service_id character varying(255),
      CONSTRAINT cms_message_assignment_pkey PRIMARY KEY (message_data_id, bus_stop_panel_id, bus_stop_group_id, bus_stop_id, service_id)
  );
  """

create_template_data_table_query =
  """
  CREATE TABLE cms_template_data (
      template_data_id character varying(150) PRIMARY KEY,
      template_name character varying(65) NOT NULL,
      template_detail character varying(5000),
      orientation character varying(25),
      requester character varying(300)
  );
  """

create_template_assignment_table_query =
  """
  CREATE TABLE cms_template_assignment (
      bus_stop_panel_id character varying(150),
      template_set_code character varying(3),
      template_data_id character varying(150) NOT NULL,
      bus_stop_group_id character(150),
      CONSTRAINT cms_template_assignment_pk PRIMARY KEY (bus_stop_panel_id, template_set_code)
  );
  """

Ecto.Adapters.SQL.query!(Repo, create_panel_bus_table_query, [])
Ecto.Adapters.SQL.query!(Repo, create_stop_table_query, [])
Ecto.Adapters.SQL.query!(Repo, create_message_data_table_query, [])
Ecto.Adapters.SQL.query!(Repo, create_message_assignment_table_query, [])
Ecto.Adapters.SQL.query!(Repo, create_template_data_table_query, [])
Ecto.Adapters.SQL.query!(Repo, create_template_assignment_table_query, [])

Repo.insert!(%Buses.BusStop{
  base_version: 20_190_512,
  point_desc: "CARIBBEAN AT KEPPEL BAY",
  point_elevation: 0,
  point_heading: 299,
  point_latitude: 103.83801388886192,
  point_longitude: 1.28165999996967,
  point_no: 14131,
  point_type: 1,
  stop_abbr: "1413",
  stop_desc: "CARIBBEAN AT KEPPEL BAY",
  stop_long_no: 0,
  stop_no: 1413,
  stop_no_international: "14131",
  stop_no_local: 0,
  stop_no_national: 0,
  stop_type: 1,
  zone_cell_no: 0
})

Repo.insert!(%Buses.BusStop{
  base_version: 20_190_512,
  point_desc: "Somewhere",
  point_elevation: 0,
  point_heading: 299,
  point_latitude: 103.83801388886192,
  point_longitude: 1.28165999996967,
  point_no: 77009,
  point_type: 1,
  stop_abbr: "7700",
  stop_desc: "Somewhere",
  stop_long_no: 0,
  stop_no: 1413,
  stop_no_international: "77009",
  stop_no_local: 0,
  stop_no_national: 0,
  stop_type: 1,
  zone_cell_no: 0
})

Repo.insert!(%Buses.PanelBus{
  base_version: 20_190_512,
  panel_id: "pid0001",
  bus_stop_no: 14131
})

Repo.insert!(%Templates.TemplateData{
  orientation: "Landscape",
  requester: "super1",
  template_data_id: "E78BB042B04F",
  template_detail:
    "{\"orientation\":{\"label\":\"Landscape\",\"value\":\"landscape\"},\"templates\":[],\"name\":\"Template A Predictions + Messages\",\"layouts\":[{\"label\":\"Two-Pane Layout B\",\"value\":\"landscape_two_pane_b\",\"duration\":10,\"id\":\"landscape_two_pane_b_0\",\"panes\":{\"pane1\":{\"type\":{\"value\":\"predictions_by_service\",\"label\":\"Predictions and Points of Interest by Service\"},\"config\":{\"font\":{\"style\":{\"label\":\"monospace\",\"value\":\"monospace\"},\"color\":{\"label\":\"red\",\"value\":\"red\"}}}},\"pane2\":{\"type\":{\"value\":\"scheduled_and_ad_hoc_messages\",\"label\":\"Scheduled and ad-hoc messages\"},\"config\":{\"scheduled_messages_font\":{\"style\":{\"label\":\"monospace\",\"value\":\"monospace\"},\"color\":{\"label\":\"red\",\"value\":\"red\"}},\"adhoc_messages_font\":{\"style\":{\"label\":\"monospace\",\"value\":\"monospace\"},\"color\":{\"label\":\"red\",\"value\":\"red\"}}}}}}]}",
  template_name: "Template A Predictions + Messages"
})

Repo.insert!(%Templates.TemplateData{
  orientation: "Landscape",
  requester: "super1",
  template_data_id: "62DAC6DB6801",
  template_detail:
    "{\"orientation\":{\"label\":\"Landscape\",\"value\":\"landscape\"},\"templates\":[],\"name\":\"Template B predictions only\",\"layouts\":[{\"label\":\"One-Pane Layout\",\"value\":\"landscape_one_pane\",\"duration\":10,\"id\":\"landscape_one_pane_0\",\"panes\":{\"pane1\":{\"type\":{\"value\":\"predictions_by_service\",\"label\":\"Predictions and Points of Interest by Service\",\"description\":\"Lorem ipsum dolor sit amet, consectetur adipisicing elit. Accusantium hic optio tempora harum placeat itaque a architecto exercitationem atque soluta ducimus, esse, laboriosam adipisci, quam ut! Necessitatibus aperiam architecto quis. \"},\"config\":{\"font\":{\"style\":{\"label\":\"monospace\",\"value\":\"monospace\"},\"color\":{\"label\":\"red\",\"value\":\"red\"}}}}}}]}",
  template_name: "Template B predictions only"
})

Repo.insert!(%Templates.TemplateAssignment{
  template_data_id: "E78BB042B04F",
  template_set_code: "A",
  bus_stop_panel_id: "pid0001"
})

Repo.insert!(%Templates.TemplateAssignment{
  template_data_id: "62DAC6DB6801",
  template_set_code: "B",
  bus_stop_panel_id: "pid0001"
})

Repo.insert!(%Messages.MessageData{
  day_type_1: nil,
  day_type_2: nil,
  day_type_3: nil,
  end_date_time: ~N[2020-10-24 23:30:00],
  end_time_1: nil,
  message_content: "Train services will be suspended from 6am to 7pm tomorrow",
  message_data_id: "F237168A0A69",
  name: "Option 1 until oct 24 23:30",
  priority: "Normal",
  start_date_time: ~N[2020-09-24 09:30:00],
  start_time_1: nil,
  type: "SCHEDULED"
})

Repo.insert!(%Messages.MessageAssignment{
  message_data_id: "F237168A0A69",
  bus_stop_panel_id: "pid0001",
  bus_stop_group_id: "",
  bus_stop_id: "",
  service_id: ""
})
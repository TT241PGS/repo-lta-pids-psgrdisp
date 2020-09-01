CREATE TABLE public.cms_message_data (
    message_data_id character varying(255) NOT NULL,
    name character varying(255),
    type character varying(255),
    priority character varying(255),
    start_date timestamp without time zone,
    end_date timestamp without time zone,
    start_time_1 timestamp without time zone,
    end_time_1 timestamp without time zone,
    start_time_2 timestamp without time zone,
    end_time_2 timestamp without time zone,
    day_type character varying(255),
    message_content character varying(1000)
);
CREATE TABLE public.cms_message_assignment (
    message_data_id character varying(255) NOT NULL,
    bus_stop_panel_id character varying(255) NOT NULL,
    bus_stop_group_id character varying(255) NOT NULL
);
INSERT INTO 
    cms_message_data (message_data_id, message_content, type)
VALUES
    ('1','hello 1','scheduled'),
    ('2','hello 2','adhoc'),
    ('3','hello 3','scheduled');

INSERT INTO 
    cms_message_assignment (message_data_id, bus_stop_panel_id, bus_stop_group_id)
VALUES
    ('1','83139','grp1');
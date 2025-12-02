
CREATE SCHEMA IF NOT EXISTS subway;

DROP TABLE IF EXISTS subway.stop CASCADE;
DROP TABLE IF EXISTS subway.ticket CASCADE;
DROP TABLE IF EXISTS subway.schedule CASCADE;
DROP TABLE IF EXISTS subway.maintenance CASCADE;
DROP TABLE IF EXISTS subway.route CASCADE;
DROP TABLE IF EXISTS subway.track CASCADE;
DROP TABLE IF EXISTS subway.train CASCADE;
DROP TABLE IF EXISTS subway.asset CASCADE;
DROP TABLE IF EXISTS subway.line CASCADE;
DROP TABLE IF EXISTS subway.station CASCADE;
DROP TABLE IF EXISTS subway.discount CASCADE;
DROP TABLE IF EXISTS subway.employee CASCADE;

CREATE TABLE subway.employee (
    employeeid INTEGER GENERATED ALWAYS AS IDENTITY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    job VARCHAR(50) NOT NULL,
    CONSTRAINT chk_job_role CHECK (job IN ('driver', 'conductor', 'station manager', 'mechanic')),
    CONSTRAINT pk_employee_employeeid PRIMARY KEY (employeeid)
);

CREATE TABLE subway.discount (
    discountid INTEGER GENERATED ALWAYS AS IDENTITY,
    discount_name VARCHAR(50) NOT NULL,
    percentage DECIMAL(5, 2) NOT NULL,
    discount_start DATE NOT NULL,
    discount_end DATE,
    CONSTRAINT chk_percentage_range CHECK (percentage BETWEEN 0.01 AND 1.00),
    CONSTRAINT chk_discount_start_date CHECK (discount_start > '2000-01-01'),
    CONSTRAINT pk_discount_discountid PRIMARY KEY (discountid)
);

CREATE TABLE subway.station (
    stationid INTEGER GENERATED ALWAYS AS IDENTITY,
    station_name VARCHAR(50) NOT NULL,
    latitude DECIMAL(9, 6) NOT NULL,
    longitude DECIMAL(9, 6) NOT NULL,
    CONSTRAINT unq_station_name UNIQUE (station_name),
    CONSTRAINT pk_station_stationid PRIMARY KEY (stationid)
);

CREATE TABLE subway.line (
    lineid INTEGER GENERATED ALWAYS AS IDENTITY,
    line_name VARCHAR(50) NOT NULL,
    color VARCHAR(20) NOT NULL,
    CONSTRAINT unq_line_name UNIQUE (line_name),
    CONSTRAINT unq_color UNIQUE (color),
    CONSTRAINT pk_line_lineid PRIMARY KEY (lineid)
);

CREATE TABLE subway.asset (
    assetid INTEGER GENERATED ALWAYS AS IDENTITY,
    asset_type VARCHAR(50) NOT NULL,
    description VARCHAR(300),
    CONSTRAINT pk_asset_assetid PRIMARY KEY (assetid)
);

CREATE TABLE subway.train (
    trainid INTEGER GENERATED ALWAYS AS IDENTITY,
    assetid INTEGER NOT NULL,
    model VARCHAR(50) NOT NULL,
    capacity INTEGER NOT NULL,
    CONSTRAINT chk_positive_capacity CHECK (capacity > 0),
    CONSTRAINT pk_train_trainid PRIMARY KEY (trainid),
    CONSTRAINT unq_train_assetid UNIQUE (assetid),
    CONSTRAINT fk_train_assetid FOREIGN KEY (assetid)
        REFERENCES subway.asset(assetid) ON DELETE RESTRICT
);

CREATE TABLE subway.track (
    trackid INTEGER GENERATED ALWAYS AS IDENTITY,
    assetid INTEGER NOT NULL,
    gauge DECIMAL(4, 2) NOT NULL,
    length DECIMAL(8, 2) NOT NULL,
    CONSTRAINT chk_positive_length CHECK (length > 0),
    CONSTRAINT pk_track_trackid PRIMARY KEY (trackid),
    CONSTRAINT unq_track_assetid UNIQUE (assetid),
    CONSTRAINT fk_track_assetid FOREIGN KEY (assetid)
        REFERENCES subway.asset(assetid) ON DELETE RESTRICT
);

CREATE TABLE subway.route (
    routeid INTEGER GENERATED ALWAYS AS IDENTITY,
    lineid INTEGER NOT NULL,
    start_stationid INTEGER NOT NULL,
    end_stationid INTEGER NOT NULL,
    CONSTRAINT chk_route_stations CHECK (start_stationid <> end_stationid),
    CONSTRAINT pk_route_routeid PRIMARY KEY (routeid),
    CONSTRAINT fk_route_lineid FOREIGN KEY (lineid)
        REFERENCES subway.line(lineid) ON DELETE RESTRICT,
    CONSTRAINT fk_route_start_stationid FOREIGN KEY (start_stationid)
        REFERENCES subway.station(stationid) ON DELETE RESTRICT,
    CONSTRAINT fk_route_end_stationid FOREIGN KEY (end_stationid)
        REFERENCES subway.station(stationid) ON DELETE RESTRICT
);

CREATE TABLE subway.maintenance (
    maintenanceid INTEGER GENERATED ALWAYS AS IDENTITY,
    assetid INTEGER NOT NULL,
    service VARCHAR(300),
    maintenance_date DATE NOT NULL,
    maintenance_cost DECIMAL(10, 2) NOT NULL,
    CONSTRAINT pk_maintenance_maintenanceid PRIMARY KEY (maintenanceid),
    CONSTRAINT fk_maintenance_assetid FOREIGN KEY (assetid)
        REFERENCES subway.asset(assetid) ON DELETE RESTRICT
);

CREATE TABLE subway.schedule (
    scheduleid INTEGER GENERATED ALWAYS AS IDENTITY,
    routeid INTEGER NOT NULL,
    trainid INTEGER NOT NULL,
    employeeid INTEGER,
    departure TIME NOT NULL,
    workdate DATE NOT NULL,
    CONSTRAINT pk_schedule_scheduleid PRIMARY KEY (scheduleid),
    CONSTRAINT fk_schedule_routeid FOREIGN KEY (routeid)
        REFERENCES subway.route(routeid) ON DELETE RESTRICT,
    CONSTRAINT fk_schedule_trainid FOREIGN KEY (trainid)
        REFERENCES subway.train(trainid) ON DELETE RESTRICT,
    CONSTRAINT fk_schedule_employeeid FOREIGN KEY (employeeid)
        REFERENCES subway.employee(employeeid) ON DELETE SET NULL
);

CREATE TABLE subway.ticket (
    ticketid INTEGER GENERATED ALWAYS AS IDENTITY,
    price DECIMAL(5, 2) NOT NULL,
    purchase_ts TIMESTAMP,
    ticket_type VARCHAR(50) NOT NULL,
    discountid INTEGER,
    CONSTRAINT chk_positive_price CHECK (price >= 0.00),
    CONSTRAINT pk_ticket_ticketid PRIMARY KEY (ticketid),
    CONSTRAINT fk_ticket_discountid FOREIGN KEY (discountid)
        REFERENCES subway.discount(discountid) ON DELETE SET NULL
);

CREATE TABLE subway.stop (
    stationid INTEGER NOT NULL,
    scheduleid INTEGER NOT NULL,
    stop_order INTEGER NOT NULL,
    stop_arrival TIME NOT NULL,
    stop_departure TIME NOT NULL,
    CONSTRAINT pk_stop_composite PRIMARY KEY (stationid, scheduleid),
    CONSTRAINT fk_stop_stationid FOREIGN KEY (stationid)
        REFERENCES subway.station(stationid) ON DELETE RESTRICT,
    CONSTRAINT fk_stop_scheduleid FOREIGN KEY (scheduleid)
        REFERENCES subway.schedule(scheduleid) ON DELETE CASCADE
);

ALTER TABLE subway.employee ADD COLUMN record_ts TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP;
ALTER TABLE subway.discount ADD COLUMN record_ts TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP;
ALTER TABLE subway.station ADD COLUMN record_ts TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP;
ALTER TABLE subway.line ADD COLUMN record_ts TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP;
ALTER TABLE subway.asset ADD COLUMN record_ts TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP;
ALTER TABLE subway.train ADD COLUMN record_ts TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP;
ALTER TABLE subway.track ADD COLUMN record_ts TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP;
ALTER TABLE subway.route ADD COLUMN record_ts TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP;
ALTER TABLE subway.maintenance ADD COLUMN record_ts TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP;
ALTER TABLE subway.schedule ADD COLUMN record_ts TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP;
ALTER TABLE subway.ticket ADD COLUMN record_ts TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP;
ALTER TABLE subway.stop ADD COLUMN record_ts TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP;

INSERT INTO subway.employee (first_name, last_name, job)
VALUES ('alex', 'smith', 'driver'),
       ('betty', 'white', 'conductor');

INSERT INTO subway.discount (discount_name, percentage, discount_start)
VALUES ('monthly pass', 0.15, '2023-01-01'),
       ('senior citizen', 0.50, '2022-05-10');

INSERT INTO subway.station (station_name, latitude, longitude)
VALUES ('union square', 40.7358, -73.9904),
       ('times square', 40.7580, -73.9855),
       ('central park', 40.7829, -73.9654);

INSERT INTO subway.line (line_name, color)
VALUES ('uptown express', 'red'),
       ('downtown local', 'green');

INSERT INTO subway.asset (asset_type, description)
VALUES ('rolling stock', 'train car set 101'),
       ('track component', 'section 42 track'),
       ('rolling stock', 'train car set 102');


INSERT INTO subway.train (assetid, model, capacity)
VALUES (
    (SELECT assetid FROM subway.asset WHERE description = 'train car set 101'),
    'r142', 300
),
(
    (SELECT assetid FROM subway.asset WHERE description = 'train car set 102'),
    'r160', 320
);


INSERT INTO subway.track (assetid, gauge, length)
VALUES (
    (SELECT assetid FROM subway.asset WHERE description = 'section 42 track'),
    1.435, 1250.50
);


INSERT INTO subway.route (lineid, start_stationid, end_stationid)
VALUES (
    (SELECT lineid FROM subway.line WHERE line_name = 'uptown express'),
    (SELECT stationid FROM subway.station WHERE station_name = 'union square'),
    (SELECT stationid FROM subway.station WHERE station_name = 'times square')
),
(
    (SELECT lineid FROM subway.line WHERE line_name = 'uptown express'),
    (SELECT stationid FROM subway.station WHERE station_name = 'times square'),
    (SELECT stationid FROM subway.station WHERE station_name = 'central park')
);


INSERT INTO subway.maintenance (assetid, service, maintenance_date, maintenance_cost)
VALUES (
    (SELECT assetid FROM subway.asset WHERE description = 'train car set 101'),
    'scheduled overhaul', '2024-03-20', 15000.00
),
(
    (SELECT assetid FROM subway.asset WHERE description = 'section 42 track'),
    'rail grinding', '2024-04-10', 5000.50
);


WITH Route1 AS (
    SELECT routeid
    FROM subway.route r
    JOIN subway.line l ON r.lineid = l.lineid
    JOIN subway.station s1 ON r.start_stationid = s1.stationid
    JOIN subway.station s2 ON r.end_stationid = s2.stationid
    WHERE l.line_name = 'uptown express'
      AND s1.station_name = 'union square'
      AND s2.station_name = 'times square'
),
Route2 AS (
    SELECT routeid
    FROM subway.route r
    JOIN subway.line l ON r.lineid = l.lineid
    JOIN subway.station s1 ON r.start_stationid = s1.stationid
    JOIN subway.station s2 ON r.end_stationid = s2.stationid
    WHERE l.line_name = 'uptown express'
      AND s1.station_name = 'times square'
      AND s2.station_name = 'central park'
),
Train1 AS (SELECT trainid FROM subway.train t JOIN subway.asset a ON t.assetid = a.assetid WHERE a.description = 'train car set 101'),
Train2 AS (SELECT trainid FROM subway.train t JOIN subway.asset a ON t.assetid = a.assetid WHERE a.description = 'train car set 102'),
Employee1 AS (SELECT employeeid FROM subway.employee WHERE first_name = 'alex' AND last_name = 'smith'),
Employee2 AS (SELECT employeeid FROM subway.employee WHERE first_name = 'betty' AND last_name = 'white')
INSERT INTO subway.schedule (routeid, trainid, employeeid, departure, workdate)
VALUES (
    (SELECT routeid FROM Route1), (SELECT trainid FROM Train1), (SELECT employeeid FROM Employee1), '07:00:00', '2024-11-15'
),
(
    (SELECT routeid FROM Route2), (SELECT trainid FROM Train2), (SELECT employeeid FROM Employee2), '08:30:00', '2024-11-15'
),
(
    (SELECT routeid FROM Route1), (SELECT trainid FROM Train1), (SELECT employeeid FROM Employee1), '10:00:00', '2024-11-15'
);



WITH Schedule1 AS (
    SELECT s.scheduleid
    FROM subway.schedule s
    JOIN subway.route r ON s.routeid = r.routeid
    JOIN subway.station start_st ON r.start_stationid = start_st.stationid
    WHERE s.departure = '07:00:00' AND s.workdate = '2024-11-15'
      AND start_st.station_name = 'union square'
),
UnionSquare AS (SELECT stationid FROM subway.station WHERE station_name = 'union square'),
TimesSquare AS (SELECT stationid FROM subway.station WHERE station_name = 'times square')
INSERT INTO subway.stop (stationid, scheduleid, stop_order, stop_arrival, stop_departure)
VALUES (
    (SELECT stationid FROM UnionSquare), (SELECT scheduleid FROM Schedule1), 1, '07:00:00', '07:00:30'
),
(
    (SELECT stationid FROM TimesSquare), (SELECT scheduleid FROM Schedule1), 2, '07:05:00', '07:05:30'
);


INSERT INTO subway.ticket (price, purchase_ts, ticket_type, discountid)
VALUES (
    2.90, '2024-11-15 06:45:00 +00', 'single ride', NULL
),
(
    150.00, '2024-11-01 12:00:00 +00', 'monthly pass', (SELECT discountid FROM subway.discount WHERE discount_name = 'monthly pass')
);
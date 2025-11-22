create database if not exists subway_db;
create schema if not exists subway;

drop table if exists subway.stop cascade;
drop table if exists subway.ticket cascade;
drop table if exists subway.schedule cascade;
drop table if exists subway.maintenance cascade;
drop table if exists subway.route cascade;
drop table if exists subway.track cascade;
drop table if exists subway.train cascade;
drop table if exists subway.asset cascade;
drop table if exists subway.line cascade;
drop table if exists subway.station cascade;
drop table if exists subway.discount cascade;
drop table if exists subway.employee cascade;

create table subway.employee (
    employeeid integer generated always as identity,
    first_name varchar(50) not null,
    last_name varchar(50) not null,
    job varchar(50) not null,
    constraint chk_job_role check (job in ('driver', 'conductor', 'station manager', 'mechanic')),
    constraint pk_employee_employeeid primary key (employeeid));

create table subway.discount (
    discountid integer generated always as identity,
    discount_name varchar(50) not null,
    percentage decimal(5, 2) not null,
    discount_start date not null,
    discount_end date,
    constraint chk_percentage_range check (percentage between 0.01 and 1.00),
    constraint chk_discount_start_date check (discount_start > '2000-01-01'),
    constraint pk_discount_discountid primary key (discountid));

create table subway.station (
    stationid integer generated always as identity,
    station_name varchar(50) not null,
    latitude decimal(9, 6) not null,
    longitude decimal(9, 6) not null,
    constraint unq_station_name unique (station_name),
    constraint pk_station_stationid primary key (stationid));

create table subway.line (
    lineid integer generated always as identity,
    line_name varchar(50) not null,
    color varchar(20) not null,
    constraint unq_line_name unique (line_name),
    constraint unq_color unique (color),
    constraint pk_line_lineid primary key (lineid));

create table subway.asset (
    assetid integer generated always as identity,
    asset_type varchar(50) not null,
    description varchar(300),
    constraint pk_asset_assetid primary key (assetid));

create table subway.train (
    trainid integer generated always as identity,
    assetid integer not null,
    model varchar(50) not null,
    capacity integer not null,
    constraint chk_positive_capacity check (capacity > 0),
    constraint pk_train_trainid primary key (trainid),
    constraint unq_train_assetid unique (assetid),
    constraint fk_train_assetid foreign key (assetid)
        references subway.asset(assetid) on delete restrict);

create table subway.track (
    trackid integer generated always as identity,
    assetid integer not null,
    gauge decimal(4, 2) not null,
    length decimal(8, 2) not null,
    constraint chk_positive_length check (length > 0),
    constraint pk_track_trackid primary key (trackid),
    constraint unq_track_assetid unique (assetid),
    constraint fk_track_assetid foreign key (assetid)
        references subway.asset(assetid) on delete restrict);

create table subway.route (
    routeid integer generated always as identity,
    lineid integer not null,
    start_stationid integer not null,
    end_stationid integer not null,
    constraint chk_route_stations check (start_stationid <> end_stationid),
    constraint pk_route_routeid primary key (routeid),
    constraint fk_route_lineid foreign key (lineid)
        references subway.line(lineid) on delete restrict,
    constraint fk_route_start_stationid foreign key (start_stationid)
        references subway.station(stationid) on delete restrict,
    constraint fk_route_end_stationid foreign key (end_stationid)
        references subway.station(stationid) on delete restrict);

create table subway.maintenance (
    maintenanceid integer generated always as identity,
    assetid integer not null,
    service varchar(300),
    maintenance_date date not null,
    maintenance_cost decimal(10, 2) not null,
    constraint pk_maintenance_maintenanceid primary key (maintenanceid),
    constraint fk_maintenance_assetid foreign key (assetid)
        references subway.asset(assetid) on delete restrict);

create table subway.schedule (
    scheduleid integer generated always as identity,
    routeid integer not null,
    trainid integer not null,
    employeeid integer,
    departure time not null,
    workdate date not null,
    constraint pk_schedule_scheduleid primary key (scheduleid),
    constraint fk_schedule_routeid foreign key (routeid)
        references subway.route(routeid) on delete restrict,
    constraint fk_schedule_trainid foreign key (trainid)
        references subway.train(trainid) on delete restrict,
    constraint fk_schedule_employeeid foreign key (employeeid)
        references subway.employee(employeeid) on delete set null);

create table subway.ticket (
    ticketid integer generated always as identity,
    price decimal(5, 2) not null,
    purchase_ts timestamp,
    ticket_type varchar(50) not null,
    discountid integer,
    constraint chk_positive_price check (price >= 0.00),
    constraint pk_ticket_ticketid primary key (ticketid),
    constraint fk_ticket_discountid foreign key (discountid)
        references subway.discount(discountid) on delete set null);

create table subway.stop (
    stationid integer not null,
    scheduleid integer not null,
    stop_order integer not null,
    stop_arrival time not null,
    stop_departure time not null,
    constraint pk_stop_composite primary key (stationid, scheduleid),
    constraint fk_stop_stationid foreign key (stationid)
        references subway.station(stationid) on delete restrict,
    constraint fk_stop_scheduleid foreign key (scheduleid)
        references subway.schedule(scheduleid) on delete cascade);

alter table subway.employee add column record_ts timestamp with time zone not null default current_timestamp;
alter table subway.discount add column record_ts timestamp with time zone not null default current_timestamp;
alter table subway.station add column record_ts timestamp with time zone not null default current_timestamp;
alter table subway.line add column record_ts timestamp with time zone not null default current_timestamp;
alter table subway.asset add column record_ts timestamp with time zone not null default current_timestamp;
alter table subway.train add column record_ts timestamp with time zone not null default current_timestamp;
alter table subway.track add column record_ts timestamp with time zone not null default current_timestamp;
alter table subway.route add column record_ts timestamp with time zone not null default current_timestamp;
alter table subway.maintenance add column record_ts timestamp with time zone not null default current_timestamp;
alter table subway.schedule add column record_ts timestamp with time zone not null default current_timestamp;
alter table subway.ticket add column record_ts timestamp with time zone not null default current_timestamp;
alter table subway.stop add column record_ts timestamp with time zone not null default current_timestamp;

insert into subway.employee (first_name, last_name, job)
values ('alex', 'smith', 'driver');

insert into subway.employee (first_name, last_name, job)
values ('betty', 'white', 'conductor');

insert into subway.discount (discount_name, percentage, discount_start)
values ('monthly pass', 0.15, '2023-01-01');

insert into subway.discount (discount_name, percentage, discount_start)
values ('senior citizen', 0.50, '2022-05-10');

insert into subway.station (station_name, latitude, longitude)
values ('union square', 40.7358, -73.9904);

insert into subway.station (station_name, latitude, longitude)
values ('times square', 40.7580, -73.9855);

insert into subway.station (station_name, latitude, longitude)
values ('central park', 40.7829, -73.9654);

insert into subway.line (line_name, color)
values ('uptown express', 'red');

insert into subway.line (line_name, color)
values ('downtown local', 'green');

insert into subway.asset (asset_type, description)
values ('rolling stock', 'train car set 101');

insert into subway.asset (asset_type, description)
values ('track component', 'section 42 track');

insert into subway.asset (asset_type, description)
values ('rolling stock', 'train car set 102');

insert into subway.train (assetid, model, capacity)
values (1, 'r142', 300);

insert into subway.train (assetid, model, capacity)
values (3, 'r160', 320);

insert into subway.track (assetid, gauge, length)
values (2, 1.435, 1250.50);

insert into subway.route (lineid, start_stationid, end_stationid)
values (1, 1, 2);

insert into subway.route (lineid, start_stationid, end_stationid)
values (1, 2, 3);

insert into subway.maintenance (assetid, service, maintenance_date, maintenance_cost)
values (1, 'scheduled overhaul', '2024-03-20', 15000.00);

insert into subway.maintenance (assetid, service, maintenance_date, maintenance_cost)
values (2, 'rail grinding', '2024-04-10', 5000.50);

insert into subway.schedule (routeid, trainid, employeeid, departure, workdate)
values (1, 1, 1, '07:00:00', '2024-11-15');

insert into subway.schedule (routeid, trainid, employeeid, departure, workdate)
values (2, 2, 2, '08:30:00', '2024-11-15');

insert into subway.schedule (routeid, trainid, employeeid, departure, workdate)
values (1, 1, 1, '10:00:00', '2024-11-15');

insert into subway.stop (stationid, scheduleid, stop_order, stop_arrival, stop_departure)
values (1, 1, 1, '07:00:00', '07:00:30');

insert into subway.stop (stationid, scheduleid, stop_order, stop_arrival, stop_departure)
values (2, 1, 2, '07:05:00', '07:05:30');

insert into subway.ticket (price, purchase_ts, ticket_type, discountid)
values (2.90, '2024-11-15 06:45:00 +00', 'single ride', null);

insert into subway.ticket (price, purchase_ts, ticket_type, discountid)
values (150.00, '2024-11-01 12:00:00 +00', 'monthly pass', 1);
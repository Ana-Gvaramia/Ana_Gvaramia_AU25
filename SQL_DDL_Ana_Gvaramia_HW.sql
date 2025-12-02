

-- employee table
create table subway.employee (
    employeeid integer,
    first_name varchar(50) not null,
    last_name varchar(50) not null,
    job varchar(50) not null,
	constraint chk_job_role check (job in ('driver', 'conductor', 'station manager', 'mechanic')),
    constraint pk_employee_employeeid primary key (employeeid));

-- discount table
create table subway.discount (
    discountid integer,
    discount_name varchar(50) not null,
    percentage decimal(5, 2) not null,
    discount_start date not null,
    discount_end date,
    constraint chk_percentage_range check (percentage between 0.01 and 1.00), --so that we can have data consistency
    constraint chk_discount_start_date check (discount_start > '2000-01-01'),
    constraint pk_discount_discountid primary key (discountid));

-- station table
create table subway.station (
    stationid integer,
    station_name varchar(50) not null,
    latitude decimal(9, 6) not null,
    longitude decimal(9, 6) not null,
	constraint unq_station_name unique (station_name), -- ha sto be unique stations dont have same names
    constraint pk_station_stationid primary key (stationid));

-- line table
create table subway.sub_line (
    lineid integer,
    line_name varchar(50) not null,
    color varchar(20) not null,
	constraint unq_line_name unique (line_name), --is a unique identifier
	constraint unq_color unique (color), --on maps lines are diffrenet colors
    constraint pk_line_lineid primary key (lineid));

-- asset table
create table subway.asset (
    assetid integer,
    asset_type varchar(50) not null,
    description varchar(300),
    constraint pk_asset_assetid primary key (assetid));

-- train table
create table subway.train (
    trainid integer,
    assetid integer not null,
    model varchar(50) not null,
    capacity integer not null,
    constraint chk_positive_capacity check (capacity > 0), -- cannot have negative capacity
    constraint pk_train_trainid primary key (trainid),
    constraint unq_train_assetid unique (assetid), -- asset ids are unique identifiers
    constraint fk_train_assetid foreign key (assetid)  -- references
               references subway.asset(assetid) on delete restrict);

-- track table
create table subway.track (
    trackid integer,
    assetid integer not null,
    gauge decimal(4, 2) not null,
    length decimal(8, 2) not null,
    constraint chk_positive_length check (length > 0),
    constraint pk_track_trackid primary key (trackid),
    constraint unq_track_assetid unique (assetid), --has to be unique as assetid is unique identifier
    constraint fk_track_assetid foreign key (assetid) --references
               references subway.asset(assetid) on delete restrict);

-- route table
create table subway.route (
    routeid integer,
    lineid integer not null,
    start_stationid integer not null, 
    end_stationid integer not null, 
    constraint chk_route_stations check (start_stationid <> end_stationid), -- cannot stay at the same place
    constraint pk_route_routeid primary key (routeid),
    constraint fk_route_lineid foreign key (lineid) -- references
               references subway.line(lineid) on delete restrict,
    constraint fk_route_start_stationid foreign key (start_stationid)  --references
               references subway.station(stationid) on delete restrict,
    constraint fk_route_end_stationid foreign key (end_stationid) --references
               references subway.station(stationid) on delete restrict);

-- maintenance table
create table subway.maintenance (
    maintenanceid integer,
    assetid integer not null,
    service varchar(300),
    maintenance_date date not null,
    maintenance_cost decimal(10, 2) not null,
    constraint pk_maintenance_maintenanceid primary key (maintenanceid),
    constraint fk_maintenance_assetid foreign key (assetid) --references
               references subway.asset(assetid) on delete restrict);

-- schedule table
create table subway.schedule (
    scheduleid integer,
    routeid integer not null, 
    trainid integer not null, 
    employeeid integer,
    departure time not null,
    workdate date not null,
    constraint pk_schedule_scheduleid primary key (scheduleid),
    constraint fk_schedule_routeid foreign key (routeid) --references
               references subway.route(routeid) on delete restrict,
    constraint fk_schedule_trainid foreign key (trainid) --references
               references subway.train(trainid) on delete restrict,
    constraint fk_schedule_employeeid foreign key (employeeid) --references
               references subway.employee(employeeid) on delete set null);

-- ticket table
create table subway.ticket (
    ticketid integer,
    price decimal(5, 2) not null,
    purchase_ts timestamp,
    ticket_type varchar(50) not null,
    discountid integer,
    constraint chk_positive_price check (price >= 0.00), --price cant be negative
    constraint pk_ticket_ticketid primary key (ticketid),
    constraint fk_ticket_discountid foreign key (discountid) --references
               references subway.discount(discountid) on delete set null);

-- stop table 
create table subway.stop (
    stationid integer not null, 
    scheduleid integer not null, 
    stop_order integer not null,
    stop_arrival time not null,
    stop_departure time not null,
    constraint pk_stop_composite primary key (stationid, scheduleid),
    constraint fk_stop_stationid foreign key (stationid) --references
               references subway.station(stationid) on delete restrict,
    constraint fk_stop_scheduleid foreign key (scheduleid) --references
               references subway.schedule(scheduleid) on delete cascade);

-- inserting record_ts for each table

alter table subway.employee add column record_ts timestamp with time zone NOT NULL default current_timestamp;
alter table subway.discount add column record_ts timestamp with time zone NOT NULL default current_timestamp;
alter table subway.station add column record_ts timestamp with time zone NOT NULL default current_timestamp;
alter table subway.line add column record_ts timestamp with time zone NOT NULL default current_timestamp;
alter table subway.asset add column record_ts timestamp with time zone NOT NULL default current_timestamp;
alter table subway.train add column record_ts timestamp with time zone NOT NULL default current_timestamp;
alter table subway.track add column record_ts timestamp with time zone NOT NULL default current_timestamp;
alter table subway.route add column record_ts timestamp with time zone NOT NULL default current_timestamp;
alter table subway.maintenance add column record_ts timestamp with time zone NOT NULL default current_timestamp;
alter table subway.schedule add column record_ts timestamp with time zone NOT NULL default current_timestamp;
alter table subway.ticket add column record_ts timestamp with time zone NOT NULL default current_timestamp;
alter table subway.stop add column record_ts timestamp with time zone NOT NULL default current_timestamp;


-- inserting values

insert into employee (employeeid, first_name, last_name, job)
select 101, 'alex', 'smith', 'driver'
where not exists (select 1 from employee where employeeid = 101);

insert into employee (employeeid, first_name, last_name, job)
select 102, 'betty', 'white', 'conductor'
where not exists (select 1 from employee where employeeid = 102);


insert into discount (discountid, discount_name, percentage, discount_start)
select 1, 'monthly pass', 0.15, '2023-01-01'
where not exists (select 1 from discount where discountid = 1);

insert into discount (discountid, discount_name, percentage, discount_start)
select 2, 'senior citizen', 0.50, '2022-05-10'
where not exists (select 1 from discount where discountid = 2);


insert into station (stationid, station_name, latitude, longitude)
select 10, 'union square', 40.7358, -73.9904
where not exists (select 1 from station where stationid = 10);
    
insert into station (stationid, station_name, latitude, longitude)
select 20, 'times square', 40.7580, -73.9855
where not exists (select 1 from station where stationid = 20);

insert into sub_line (lineid, line_name, color)
select 1, 'uptown express', 'red'
where not exists (select 1 from line where lineid = 1);

insert into sub_line (lineid, line_name, color)
select 2, 'downtown local', 'green'
where not exists (select 1 from line where lineid = 2);

insert into route (routeid, lineid, start_stationid, end_stationid)
select 1, line_red_id, stat_union_sq_id, stat_times_sq_id
where not exists (select 1 from route where routeid = 1);

insert into route (routeid, lineid, start_stationid, end_stationid)
select 2, line_red_id, stat_times_sq_id, 30
where not exists (select 1 from route where routeid = 2);
    
insert into asset (assetid, asset_type, description)
select 501, 'rolling stock', 'train car set 101'
where not exists (select 1 from asset where assetid = 501);

insert into asset (assetid, asset_type, description)
select 502, 'track component', 'section 42 track'
where not exists (select 1 from asset where assetid = 502);
    
insert into train (trainid, assetid, model, capacity)
select 1001, asset_train101_id, 'r142', 300
where not exists (select 1 from train where trainid = 1001);

insert into train (trainid, assetid, model, capacity)
select 1002, 503, 'r160', 320 
where not exists (select 1 from train where trainid = 1002);
    
insert into track (trackid, assetid, gauge, length)
select 201, asset_track_id, 1.435, 1250.50
where not exists (select 1 from track where trackid = 201);

insert into maintenance (maintenanceid, assetid, service, date, cost)
select 301, asset_train101_id, 'scheduled overhaul', '2024-03-20', 15000.00
where not exists (select 1 from maintenance where maintenanceid = 301);

insert into maintenance (maintenanceid, assetid, service, date, cost)
select 302, asset_track_id, 'rail grinding', '2024-04-10', 5000.50
where not exists (select 1 from maintenance where maintenanceid = 302);

insert into schedule (scheduleid, routeid, trainid, employeeid, departure, workdate)
select 1, route_u2t_id, train_101_id, emp_alex_id, '07:00:00', '2024-11-15'
where not exists (select 1 from schedule where scheduleid = 1);
    
insert into schedule (scheduleid, routeid, trainid, employeeid, departure, workdate)
select 2, 2, 1002, 104, '08:30:00', '2024-11-15'
where not exists (select 1 from schedule where scheduleid = 2);

insert into schedule (scheduleid, routeid, trainid, employeeid, departure, workdate)
select 3, route_u2t_id, train_101_id, emp_alex_id, '10:00:00', '2024-11-15'
where not exists (select 1 from schedule where scheduleid = 3);
    
insert into stop (stationid, scheduleid, stop_order, stop_arrival, stop_departure)
select stat_union_sq_id, sch_morning_id, 1, '07:00:00', '07:00:30'
where not exists (select 1 from stop where stationid = stat_union_sq_id and scheduleid = sch_morning_id);

insert into stop (stationid, scheduleid, stop_order, stop_arrival, stop_departure)
select stat_times_sq_id, sch_morning_id, 2, '07:05:00', '07:05:30'
where not exists (select 1 from stop where stationid = stat_times_sq_id and scheduleid = sch_morning_id);

insert into ticket (ticketid, price, purchase_ts, ticket_type, discountid)
select 10001, 2.90, '2024-11-15 06:45:00 +00', 'single ride', null
where not exists (select 1 from ticket where ticketid = 10001);
    
insert into ticket (ticketid, price, purchase_ts, ticket_type, discountid)
select 10002, 150.00, '2024-11-01 12:00:00 +00', 'monthly pass', disc_monthly_id
where not exists (select 1 from ticket where ticketid = 10002);

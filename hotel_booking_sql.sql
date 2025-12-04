create database hotel_bookings;
drop database hotel_booking;

select * from hotel_booking;

create table hotel_booking1
like hotel_booking;

select * from hotel_booking1;

insert into hotel_booking1
select * from hotel_booking;

-- Cleaning and Feature Engineering --

-- Remove Zero-Gusts Booking --

select * from  hotel_booking1 
where (adults+ifnull(children,0)+babies) = 0;

delete from hotel_booking1
where (adults + ifnull(children,0) + babies) = 0;

-- Update Null Where In children --

update hotel_booking1
set children=0
where children=null;

-- Add Columns -- 

alter table hotel_booking1
add column total_guests int,
add column total_nights int,
add column revenue decimal(10,2),
add column family_flag tinyint,
add column season varchar(150),
add column lead_time_bucket varchar(150);

-- Update What we added columns --

update hotel_booking1
set
    total_guests = adults + children + babies,
    total_nights = stays_in_weekend_nights + stays_in_week_nights,
    revenue = adr * (stays_in_weekend_nights + stays_in_week_nights),
    family_flag = case when children + babies > 0 then 1 else 0 end,
    season = case
            when arrival_date_month in ('December','January','February') then 'Winter'
            when arrival_date_month in ('March','Aprial','May') then 'Spring'
            when arrival_date_month in('June','July','August') then 'Summer'
            else 'Autumn'
            end,
    lead_time_bucket = case
                    when lead_time <= 7 then '0-7 days'
                    when lead_time <= 30 then '8-30 days'
                    when lead_time <= 90 then '31-90 days'
                    else '90+ days'
                    end;

-- find '0' or less than zero in 'Zero-Adr' or 'total nights' -- 

select adr, total_nights from hotel_booking1
where adr <= 0 or total_nights <= 0;

-- Delete Those Zeroes In adr or total_nights --

delete from hotel_booking1
where adr <= 0 or total_nights <= 0;

-- overall bookings & cancellations --

select 
    count(*) as bookings,
    sum(is_canceled) as total_canceled,
    round(100* avg(is_canceled),3) as cancel_rate_percentage
from hotel_booking1;

-- Hotel Performance --

select
      count(*) as bookings,
      hotel,
      round(avg(adr),2) as avg_adr,
      round(avg(is_canceled) * 100 ,2) as cancel_rate_percentage,
      count(*) as bookings
from hotel_booking1
group by hotel;

-- Monthly Booking & Revenue --

select 
    arrival_date_month,
    count(*) as bookings,
    round(sum(case when is_canceled = 0 then revenue else 0 end),2) as total_revenue
from hotel_booking1
group by arrival_date_month
order by bookings desc ;

-- Market Segment Cancellation --

select market_segment,
        count(*) as bookings,
        round(avg(is_canceled)*100, 2) as cancel_percentage
from hotel_booking1
group by market_segment
order by bookings desc ;

-- Families vs Non-Families --

select family_flag,
        count(*) as bookings,
        round(avg(is_canceled)*100, 2) as canceled_percentage,
        round(avg(revenue),2) as avg_revenue
from hotel_booking1
group by family_flag
order by bookings desc ;

-- Rank Months By Revenue --

select
        arrival_date_year,
        arrival_date_month,
        sum(case when is_canceled = 0 then revenue else 0 end) as month_revenue,
        rank() over (partition by arrival_date_year 
                     order by sum(case when is_canceled = 0 then revenue else 0 end ) desc
        ) as revenue_rank_by_year
from hotel_booking1
group by arrival_date_year, arrival_date_month
order by arrival_date_year, revenue_rank_by_year;

-- Running Total Of Bookings Over Time -- 

with daily_bookings as (
    select 
        reservation_status_date as dt,
        hotel,
        count(*) as bookings
    from hotel_booking1
    group by dt,hotel
)
select 
    dt,
    hotel,
    bookings,
    sum(bookings) over (partition by hotel order by dt                                               -- Current row it means Up to the Present row --
                        rows between unbounded preceding and current row) as running_total_booking   -- unbounded preceding it means start from the first row include everything until now --
from daily_bookings
order by hotel,dt desc;

-- 3-Day Moving Average Of Bookings --

with daily_booking as (
    select 
        reservation_status_date as dt,
        count(*) as bookings
    from hotel_booking1
    group by reservation_status_date
)
select 
    dt,
    bookings,
    avg(bookings) over (order by dt rows between 2 preceding and current row) as moving_avg_3d   -- 2 preceding means only include last 2 rows + current row --
from daily_booking
order by dt;

-- Cancellation rate vs Overall average --

with 
seg as (
    select 
        market_segment,
        avg(is_canceled) as seg_avg_canceled
    from hotel_booking1
    group by market_segment
),
overall as (
    select 
        avg(is_canceled) as overall_avg_canceled
    from hotel_booking1
)
select 
    s.market_segment,
    round(s.seg_avg_canceled * 100, 2) as seg_avg_canceled_percentage,
    round(o.overall_avg_canceled * 100, 2) as overall_avg_canceled_percentage,
    round((s.seg_avg_canceled - overall_avg_canceled) * 100, 2) as difference_percentage
from seg as s
cross join overall as o
order by difference_percentage desc;

-- Top 3 Countries By Booking For Each Hotel --

with country_counts as (
    select 
        hotel,
        country,
        count(*) as bookings
    from hotel_booking1
    group by hotel,country
)
select 
    hotel,
    country,
    bookings
    from country_counts
    order by bookings desc limit 3;
    
-- ADR Quartiles Per Hotel --

with adr_ranked as (
    select 
        hotel,
        adr,
        ntile(4) over (partition by hotel order by adr) adr_quartile
        from hotel_booking1
        where adr > 0
)
select 
    hotel,
    adr_quartile,
    round(avg(adr), 2) as avg_adr,
    count(*) as bookings
from adr_ranked
group by hotel, adr_quartile
order by hotel, adr_quartile desc;

-- Occupency Proxy By Day-Of-Week --

with day_of_week as (
    select 
        dayofweek(reservation_status_date) as dow,
        sum(total_nights) as room_nights
        from hotel_booking1
        where is_canceled = 0
        group by dayofweek(reservation_status_date)
)
select 
    dow,
    room_nights,
    round(100 * room_nights / sum(room_nights) over(), 2) as total_percentage
from day_of_week
order by dow;
    
-- Long Stays (Long Nights + High Cancels) --

with stay_bins as (
    select 
        case
            when total_nights <= 2 then '1-2 days'
            when total_nights <= 7 then '3-7 days'
            when total_nights <= 14 then '8-14 days'
            else '15+ days'
        end as room_stayed,
        avg(is_canceled) as cancel_rate,
        count(*) as bookings
    from hotel_booking1
    group by room_stayed
)
select
    room_stayed,
    bookings,
    round(cancel_rate * 100 ,2) as Cancel_percentage
from stay_bins
order by cancel_percentage desc;

-- Agent Ranking By 'Value' (Revenue & Cancellation) --

with agent_stats as (
    select 
        agent,
        count(*) as bookings,
        sum(revenue) as total_revenue,
        avg(is_canceled) as avg_canceled
    from hotel_booking1
    where agent is not null and agent <> 'null'
    group by agent
    having count(*) >= 50
)
select 
    agent,
    bookings,
    round(total_revenue, 2) as total_revenue,
    round(avg_canceled * 100, 2) as avg_cancel_percentage,
    rank() over (order by total_revenue desc) as revenue_rank,
    rank() over (order by avg_canceled) as low_cancel_rank
from agent_stats
order by revenue_rank;

-- Room Type Over Booking Pressure --

with room_counts as (
    select 
        reserved_room_type,
        count(*) as bookings,
        sum(case when reserved_room_type <> assigned_room_type then 1 else 0 end) as reassigned
    from hotel_booking1
    group by reserved_room_type
)
select
    reserved_room_type,
    bookings,
    reassigned,
    round(100 * reassigned / bookings, 2) as reassigned_percentage,
    round(100 * bookings / sum(bookings) over(), 2) as pct_of_total_demand
from room_counts
order by reassigned_percentage desc;
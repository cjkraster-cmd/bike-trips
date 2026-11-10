/* =====================================================================
   Cyclistic Bike-Share Case Study: SQL Analysis
   Google Data Analytics Certificate Capstone
   Author: Christopher Kraster
   Tool:   Google BigQuery
   Data:   Divvy trip data (Motivate International Inc.), Oct 2025 - Sep 2026,
           loaded from Google Drive into dataset `cyclistic_bike_trips`

   Business question: How do annual members and casual riders use
   Cyclistic bikes differently?

   The full report (index.html) was built in R. This file applies the
   same cleaning rules and analysis steps in BigQuery SQL.
   ===================================================================== */


/* ---------------------------------------------------------------------
   PREPARE: Preview the source table and copy it into a native table
   (Drive-backed external tables re-read the file on every query)
   --------------------------------------------------------------------- */

SELECT *
FROM `sanguine-parsec-392900.cyclistic_bike_trips.cyclistic_data`
LIMIT 1000;

CREATE OR REPLACE TABLE `sanguine-parsec-392900.cyclistic_bike_trips.trips_raw` AS
SELECT *
FROM `sanguine-parsec-392900.cyclistic_bike_trips.cyclistic_data`;


/* ---------------------------------------------------------------------
   PROCESS (1/2): Data quality checks
   --------------------------------------------------------------------- */

-- Duplicates: ride_id should be unique, so total_rows should equal unique_rides
SELECT
  COUNT(*)                AS total_rows,
  COUNT(DISTINCT ride_id) AS unique_rides
FROM `sanguine-parsec-392900.cyclistic_bike_trips.trips_raw`;

-- Missing values in key columns
--   Missing stations are common for e-bikes parked off-dock. These rides
--   are kept, and left out only of the station analysis.
SELECT
  COUNTIF(start_station_name IS NULL) AS null_start_station,
  COUNTIF(end_station_name IS NULL)   AS null_end_station,
  COUNTIF(started_at IS NULL)         AS null_started_at,
  COUNTIF(ended_at IS NULL)           AS null_ended_at,
  COUNTIF(member_casual IS NULL)      AS null_rider_type
FROM `sanguine-parsec-392900.cyclistic_bike_trips.trips_raw`;

-- Valid categories: member_casual should only be 'member' or 'casual'
SELECT
  member_casual,
  rideable_type,
  COUNT(*) AS rides
FROM `sanguine-parsec-392900.cyclistic_bike_trips.trips_raw`
GROUP BY 1, 2
ORDER BY 1, 2;


/* ---------------------------------------------------------------------
   PROCESS (2/2): Clean and transform
   Cleaning rules (same as the R report):
     - Remove duplicate ride_ids (keep first occurrence)
     - Remove rows missing rider type or timestamps
     - Keep rides that started Oct 1, 2025 - Sep 30, 2026
       (the monthly files overlap slightly at month edges)
     - Remove rides under 1 minute (false starts / re-docks)
       or over 24 hours (lost or stolen bikes)
   New columns: ride_length_min, day_of_week, day_num, month, start_hour
   --------------------------------------------------------------------- */

CREATE OR REPLACE TABLE `sanguine-parsec-392900.cyclistic_bike_trips.trips_clean` AS
WITH deduped AS (
  SELECT *
  FROM `sanguine-parsec-392900.cyclistic_bike_trips.trips_raw`
  QUALIFY ROW_NUMBER() OVER (PARTITION BY ride_id ORDER BY started_at) = 1
),
with_length AS (
  SELECT
    *,
    TIMESTAMP_DIFF(ended_at, started_at, MILLISECOND) / 60000 AS ride_length_min
  FROM deduped
  WHERE member_casual IN ('member', 'casual')
    AND started_at IS NOT NULL
    AND ended_at IS NOT NULL
    AND started_at >= TIMESTAMP '2025-10-01'
    AND started_at <  TIMESTAMP '2026-10-01'
)
SELECT
  ride_id,
  rideable_type,
  member_casual,
  started_at,
  ended_at,
  start_station_name,
  end_station_name,
  ride_length_min,
  FORMAT_TIMESTAMP('%A', started_at)        AS day_of_week,
  MOD(EXTRACT(DAYOFWEEK FROM started_at) + 5, 7) + 1 AS day_num,  -- 1 = Monday, 7 = Sunday
  FORMAT_TIMESTAMP('%Y-%m', started_at)     AS month,             -- e.g. 2025-10, sorts in order
  EXTRACT(HOUR FROM started_at)             AS start_hour,
  EXTRACT(DAYOFWEEK FROM started_at) IN (1, 7) AS is_weekend,     -- Sunday = 1, Saturday = 7
  start_station_name IS NOT NULL AND end_station_name IS NOT NULL AS both_stations
FROM with_length
WHERE ride_length_min BETWEEN 1 AND 1440;

-- Rows remaining after cleaning (the R report has 6,007,154)
SELECT COUNT(*) AS clean_rows
FROM `sanguine-parsec-392900.cyclistic_bike_trips.trips_clean`;


/* ---------------------------------------------------------------------
   ANALYZE: Members vs. casual riders
   --------------------------------------------------------------------- */

-- Overview: ride volume and share, mean and exact median ride length,
-- weekend share and round-trip share
SELECT
  member_casual,
  COUNT(*)                                                   AS rides,
  ROUND(100 * COUNT(*) / SUM(COUNT(*)) OVER (), 2)           AS share_pct,
  ROUND(AVG(ride_length_min), 2)                             AS mean_min,
  ROUND(ANY_VALUE(median_min), 2)                            AS median_min,
  ROUND(100 * COUNTIF(is_weekend) / COUNT(*), 2)             AS weekend_pct,
  ROUND(100 * COUNTIF(both_stations AND start_station_name = end_station_name)
            / COUNTIF(both_stations), 2)                     AS round_trip_pct
FROM (
  SELECT
    *,
    PERCENTILE_CONT(ride_length_min, 0.5) OVER (PARTITION BY member_casual) AS median_min
  FROM `sanguine-parsec-392900.cyclistic_bike_trips.trips_clean`
)
GROUP BY 1;

-- Day of week: weekday commuting vs. weekend leisure
SELECT
  member_casual,
  day_of_week,
  COUNT(*)                       AS rides,
  ROUND(AVG(ride_length_min), 1) AS mean_min
FROM `sanguine-parsec-392900.cyclistic_bike_trips.trips_clean`
GROUP BY member_casual, day_num, day_of_week
ORDER BY member_casual, day_num;

-- Hour of day: share of each rider type's rides by hour, weekdays vs. weekends
SELECT
  IF(is_weekend, 'Weekend', 'Weekday') AS day_type,
  member_casual,
  start_hour,
  COUNT(*) AS rides,
  ROUND(100 * COUNT(*) / SUM(COUNT(*)) OVER (PARTITION BY is_weekend, member_casual), 2) AS pct
FROM `sanguine-parsec-392900.cyclistic_bike_trips.trips_clean`
GROUP BY is_weekend, member_casual, start_hour
ORDER BY day_type, member_casual, start_hour;

-- Month: seasonality, with the casual share of each month's rides
SELECT
  month,
  COUNTIF(member_casual = 'casual')                   AS casual_rides,
  COUNTIF(member_casual = 'member')                   AS member_rides,
  ROUND(100 * COUNTIF(member_casual = 'casual') / COUNT(*), 1) AS casual_pct
FROM `sanguine-parsec-392900.cyclistic_bike_trips.trips_clean`
GROUP BY month
ORDER BY month;

-- Ride length distribution (share of each rider type's rides)
SELECT
  member_casual,
  CASE
    WHEN ride_length_min < 5  THEN '1-5'
    WHEN ride_length_min < 10 THEN '5-10'
    WHEN ride_length_min < 20 THEN '10-20'
    WHEN ride_length_min < 30 THEN '20-30'
    WHEN ride_length_min < 60 THEN '30-60'
    ELSE '60+'
  END AS minutes,
  COUNT(*) AS rides,
  ROUND(100 * COUNT(*) / SUM(COUNT(*)) OVER (PARTITION BY member_casual), 1) AS pct
FROM `sanguine-parsec-392900.cyclistic_bike_trips.trips_clean`
GROUP BY 1, 2
ORDER BY 1, MIN(ride_length_min);

-- Bike type: rides and average ride length
SELECT
  rideable_type,
  member_casual,
  COUNT(*)                       AS rides,
  ROUND(AVG(ride_length_min), 1) AS mean_min
FROM `sanguine-parsec-392900.cyclistic_bike_trips.trips_clean`
GROUP BY 1, 2
ORDER BY 1, 2;

-- Stations with the highest share of casual riders
-- (stations with at least 5,000 rides; targets for membership marketing)
SELECT
  start_station_name,
  COUNTIF(member_casual = 'casual') AS casual,
  COUNTIF(member_casual = 'member') AS member,
  COUNT(*)                          AS total,
  ROUND(100 * COUNTIF(member_casual = 'casual') / COUNT(*), 1) AS casual_pct
FROM `sanguine-parsec-392900.cyclistic_bike_trips.trips_clean`
WHERE start_station_name IS NOT NULL
GROUP BY 1
HAVING COUNT(*) >= 5000
ORDER BY casual_pct DESC
LIMIT 10;

-- Stations with the most casual rides overall
SELECT
  start_station_name,
  COUNT(*) AS casual_rides
FROM `sanguine-parsec-392900.cyclistic_bike_trips.trips_clean`
WHERE member_casual = 'casual'
  AND start_station_name IS NOT NULL
GROUP BY 1
ORDER BY casual_rides DESC
LIMIT 10;

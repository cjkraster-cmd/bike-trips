/* =====================================================================
   Cyclistic Bike-Share Case Study: SQL Analysis
   Google Data Analytics Certificate Capstone
   Author: Christopher Kraster
   Tool:   Google BigQuery
   Data:   Divvy trip data (Motivate International Inc.), loaded from
           Google Drive into dataset `cyclistic_bike_trips`

   Business question: How do annual members and casual riders use
   Cyclistic bikes differently?
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
--   Missing stations: common for e-bikes parked off-dock (kept, excluded from station rankings)
--   Missing end coordinates: lost/undocked bikes (removed in cleaning)
SELECT
  COUNTIF(start_station_name IS NULL) AS null_start_station,
  COUNTIF(end_station_name IS NULL)   AS null_end_station,
  COUNTIF(end_lat IS NULL)            AS null_end_coords,
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
   Cleaning rules:
     - Remove duplicate ride_ids (keep first occurrence)
     - Remove rides with no end coordinates
     - Remove rides under 1 minute (false starts / re-docks)
       or over 24 hours (lost or stolen bikes)
   New columns: ride_length_min, day_of_week, month, start_hour
   --------------------------------------------------------------------- */

CREATE OR REPLACE TABLE `sanguine-parsec-392900.cyclistic_bike_trips.trips_clean` AS
SELECT
  ride_id,
  rideable_type,
  member_casual,
  started_at,
  ended_at,
  start_station_name,
  end_station_name,
  TIMESTAMP_DIFF(ended_at, started_at, SECOND) / 60 AS ride_length_min,
  FORMAT_TIMESTAMP('%A', started_at)                AS day_of_week,
  FORMAT_TIMESTAMP('%B', started_at)                AS month,
  EXTRACT(HOUR FROM started_at)                     AS start_hour
FROM `sanguine-parsec-392900.cyclistic_bike_trips.trips_raw`
WHERE end_lat IS NOT NULL
  AND TIMESTAMP_DIFF(ended_at, started_at, SECOND) BETWEEN 60 AND 86400
QUALIFY ROW_NUMBER() OVER (PARTITION BY ride_id ORDER BY started_at) = 1;


/* ---------------------------------------------------------------------
   ANALYZE: Members vs. casual riders
   --------------------------------------------------------------------- */

-- Overall: ride volume, average and median ride length
SELECT
  member_casual,
  COUNT(*)                                                   AS rides,
  ROUND(AVG(ride_length_min), 1)                             AS avg_min,
  ROUND(APPROX_QUANTILES(ride_length_min, 2)[OFFSET(1)], 1)  AS median_min
FROM `sanguine-parsec-392900.cyclistic_bike_trips.trips_clean`
GROUP BY 1;

-- Day of week: weekday commuting vs. weekend leisure
SELECT
  member_casual,
  day_of_week,
  COUNT(*)                       AS rides,
  ROUND(AVG(ride_length_min), 1) AS avg_min
FROM `sanguine-parsec-392900.cyclistic_bike_trips.trips_clean`
GROUP BY 1, 2
ORDER BY 1, rides DESC;

-- Month: seasonality
SELECT
  member_casual,
  month,
  COUNT(*) AS rides
FROM `sanguine-parsec-392900.cyclistic_bike_trips.trips_clean`
GROUP BY 1, 2
ORDER BY 1, rides DESC;

-- Hour of day: commute peaks vs. leisure hours
SELECT
  member_casual,
  start_hour,
  COUNT(*) AS rides
FROM `sanguine-parsec-392900.cyclistic_bike_trips.trips_clean`
GROUP BY 1, 2
ORDER BY 1, 2;

-- Bike type preference
SELECT
  member_casual,
  rideable_type,
  COUNT(*) AS rides
FROM `sanguine-parsec-392900.cyclistic_bike_trips.trips_clean`
GROUP BY 1, 2
ORDER BY 1, rides DESC;

-- Top 10 start stations for casual riders (targets for membership marketing)
SELECT
  start_station_name,
  COUNT(*) AS rides
FROM `sanguine-parsec-392900.cyclistic_bike_trips.trips_clean`
WHERE member_casual = 'casual'
  AND start_station_name IS NOT NULL
GROUP BY 1
ORDER BY rides DESC
LIMIT 10;

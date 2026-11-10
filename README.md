[README-3.md](https://github.com/user-attachments/files/34644823/README-3.md)
# Cyclistic Bike-Share Analysis

**Google Data Analytics Certificate: Capstone Project**
Christopher Kraster

## Business question

How do annual members and casual riders use Cyclistic bikes differently, and how can Cyclistic convert more casual riders into members?

## Tools

- **Google BigQuery (SQL):** data loading, cleaning and analysis
- **Google Drive:** storage for the source CSVs (each over BigQuery's 100MB console upload limit)
- **R / tidyverse:** cross-checking results against the BigQuery output

## Repository contents

| File | Description |
| --- | --- |
| `cyclistic_analysis.sql` | All SQL queries, commented by phase (Prepare, Process, Analyze) |
| `https://1drv.ms/u/c/4bbc57fc8fedb21d/IQDh3V_r9K9LQ4LUaRVE_qYLAYEEwg1jrGkTSSpjkE6GEYQ?e=hyEsv6` | Full written report with charts |
| `README.md` | This file |

## Process

1. **Prepare:** Loaded monthly Divvy trip data from Google Drive into BigQuery and copied it into a native table for faster queries.
2. **Process:** Checked for duplicate ride IDs, missing values and invalid categories, then built a clean table:
   - Removed duplicate rides
   - Removed rides with no end coordinates (lost or undocked bikes)
   - Removed rides under 1 minute or over 24 hours
   - Added ride length, day of week, month and start hour
3. **Analyze:** Compared members and casual riders by ride volume, ride length (average and median), day of week, month, hour of day, bike type and top starting stations.
4. **Verify:** Key results (ride counts and ride lengths by rider type) were verified in R and matched the BigQuery output.

## Key findings

- Casual riders take longer rides than members (median 11.84 vs. 8.69 minutes).
- Members ride most on weekdays at commute hours; casual riders peak on weekends and afternoons.
- Casual riding is strongly seasonal, peaking in summer.
- Casual riders concentrate at a small set of stations, led by Shedd Aquarium.

## Recommendations

1. Run membership campaigns in late spring, before casual riding peaks.
2. Target marketing at the top casual-rider stations.
3. Test a weekend or seasonal membership that matches casual riders' habits.

## Data source

Trip data provided by Motivate International Inc. under the [Divvy Data License Agreement](https://divvybikes.com/data-license-agreement). The raw data files are not included in this repository. They are available from the [Divvy trip data page](https://divvy-tripdata.s3.amazonaws.com/index.html).

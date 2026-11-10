# Cyclistic Bike-Share Analysis

**Google Data Analytics Certificate: Capstone Project**
Christopher Kraster

**[Read the full report →](https://cjkraster-cmd.github.io/bike-trips/)**

## Business question

How do annual members and casual riders use Cyclistic bikes differently, and how can Cyclistic convert more casual riders into members?

## Tools

- **R / tidyverse:** data loading, cleaning, analysis and charts (the full report was built in R Markdown)
- **Google BigQuery (SQL):** the same cleaning and analysis steps written in SQL, to show the workflow in a cloud data warehouse
- **Google Drive:** storage for the source CSVs (each over BigQuery's 100MB console upload limit)

## Repository contents

| File | Description |
| --- | --- |
| `index.html` | Full written report with code, charts and findings ([view it as a web page](https://cjkraster-cmd.github.io/bike-trips/)) |
| `cyclistic_analysis.sql` | The same analysis in BigQuery SQL, commented by phase (Prepare, Process, Analyze) |
| `README.md` | This file |

## Data

12 months of Divvy trip data, October 2025 through September 2026: 6,171,785 rides before cleaning and 6,007,154 after.

## Process

1. **Prepare:** Combined the 12 monthly files and checked them for missing values and invalid categories. Noted the data's limits: riders are anonymous, there is no pricing data, and many e-bike trips have no station name.
2. **Process:** Cleaned the data and logged how many rows each step removed:
   - Removed duplicate ride IDs
   - Removed rows missing rider type or timestamps
   - Kept only rides that started between October 1, 2025 and September 30, 2026
   - Removed rides under 1 minute (false starts) or over 24 hours (lost or stolen bikes)
   - Added ride length, day of week, month and start hour
   - Kept rides with no station name, since they are real trips, and left them out only of the station analysis
3. **Analyze:** Compared members and casual riders by ride volume, ride length, day of week, hour of day, month, bike type and starting station.

## Key findings

- **Casual riders take longer rides.** Their median ride is 11.14 minutes, compared with 8.69 for members, and 13.3% of casual rides last 30 minutes or more, compared with 5.4% of member rides.
- **Members commute; casual riders ride for leisure.** On weekdays, member rides peak at 8 AM and 5 PM. 37.2% of casual rides happen on weekends, compared with 23.3% for members, and casual riders take round trips 3.4× as often.
- **Casual riding is strongly seasonal.** The casual share of rides ranges from 17.9% in January to 40.8% in July.
- **Casual riders dominate lakefront and museum stations.** The stations with the highest share of casual riders are Shedd Aquarium (81.6%), Field Museum, DuSable Lake Shore Dr & Monroe St, Navy Pier and Adler Planetarium. Navy Pier has the most casual rides overall.

## Recommendations

1. **Launch a summer or weekend membership.** Price it between a day pass and an annual membership, and promote it from May through September, when casual riding peaks.
2. **Advertise at lakefront and museum stations.** Put membership offers on kiosks, docks and in-app prompts where casual riders make up most of the traffic.
3. **Show casual riders what they would save.** After a long casual ride, show the trip's cost next to what it would have cost with a membership.

## Data source

Trip data provided by Motivate International Inc. under the [Divvy Data License Agreement](https://divvybikes.com/data-license-agreement). The raw data files are not included in this repository. They are available from the [Divvy trip data page](https://divvy-tripdata.s3.amazonaws.com/index.html).

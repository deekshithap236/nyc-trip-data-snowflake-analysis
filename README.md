# NYC Taxi Trip Data Analysis

This project focuses on analyzing NYC taxi trip data using Snowflake and Snowpark. The project involves setting up a database, loading data from an S3 bucket, optimizing the data for query performance, and performing various analyses on the taxi trip data.

## Project Structure


## Prerequisites

- Snowflake account
- AWS S3 bucket with NYC taxi trip data in Parquet format
- Python 3.x with Snowpark library installed

---

## Project Structure

    nyc-trip-data-snowflake-analysis/
    │
    ├── python/
    │   ├── nyc_trip_data.py
    ├── sql/
    │   ├── nyc_trip_data.sql
    │
    └── README.md

---

## Setup

1. **Create Database and Schema**: Run the SQL script `nyc_trip_data.sql` to create the database, schema, and table in Snowflake.
2. **Set Up External Stage**: Configure the external stage in Snowflake to point to your S3 bucket.
3. **Create Snowpipe**: Set up a Snowpipe to automatically ingest data from S3 into the `TAXI_TRIPS` table.
4. **Run Python Script**: Execute the Python script `nyc_trip_data.py` to verify data loading, apply optimizations, and perform analyses.

## SQL Script Overview

The SQL script `nyc_trip_data.sql` performs the following steps:

1. **Create Database and Schema**: Sets up the `NYC_TAXI_DB` database and `TAXI_SCHEMA` schema.
2. **Create Table**: Defines the `TAXI_TRIPS` table to store taxi trip data.
3. **Set Up External Stage**: Configures an external stage to load data from S3.
4. **Create Snowpipe**: Automates data ingestion from S3 into the `TAXI_TRIPS` table.
5. **Verify Data Loading**: Checks the first 10 rows of the table to ensure data is loaded correctly.
6. **Optimize Table**: Adds clustering keys and search optimization to improve query performance.
7. **Perform Analyses**: Runs various queries to analyze the data, such as total revenue by payment type, busiest pickup locations, and hourly trip trends.
8. **Time Travel Queries**: Demonstrates Snowflake's time travel feature to query historical data and restore deleted data.

## Python Script Overview

The Python script `nyc_trip_data.py` performs the following steps:

1. **Connect to Snowflake**: Establishes a connection to Snowflake using Snowpark.
2. **Verify Data Loading**: Queries the first 10 rows of the `TAXI_TRIPS` table.
3. **Apply Optimizations**: Adds a clustering key and enables search optimization on the table.
4. **Perform Analyses**: Runs queries to calculate total revenue by payment type and identify the busiest pickup locations.

## Usage

1. **Run SQL Script**: Execute the SQL script in Snowflake to set up the database, schema, and table, and load data from S3.
2. **Run Python Script**: Execute the Python script to verify data loading, apply optimizations, and perform analyses.

## Contributing

Contributions are welcome! Please open an issue or submit a pull request for any improvements or bug fixes.


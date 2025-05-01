-- =============================================
-- STEP 1: CREATE DATABASE AND SCHEMA
-- =============================================

-- Create a database for NYC Taxi data
CREATE DATABASE NYC_TAXI_DB;

-- Use the database
USE DATABASE NYC_TAXI_DB;

-- Create a schema for taxi trip data
CREATE SCHEMA TAXI_SCHEMA;

-- Use the schema
USE SCHEMA TAXI_SCHEMA;

-- =============================================
-- STEP 2: CREATE A TABLE FOR TAXI TRIPS
-- =============================================

-- Create a table to store NYC taxi trip data
CREATE OR REPLACE TABLE TAXI_TRIPS (
    VendorID INT,                      -- Vendor ID
    tpep_pickup_datetime TIMESTAMP,    -- Pickup timestamp (converted from epoch microseconds)
    tpep_dropoff_datetime TIMESTAMP,   -- Dropoff timestamp (converted from epoch microseconds)
    PASSENGER_COUNT FLOAT,             -- Number of passengers
    TRIP_DISTANCE FLOAT,               -- Distance of the trip
    RatecodeID FLOAT,                  -- Rate code ID
    STORE_AND_FWD_FLAG STRING,         -- Store and forward flag
    PULocationID INT,                  -- Pickup location ID
    DOLocationID INT,                  -- Dropoff location ID
    PAYMENT_TYPE BIGINT,               -- Payment type (1 = Credit Card, 2 = Cash, etc.)
    FARE_AMOUNT FLOAT,                 -- Fare amount
    EXTRA FLOAT,                       -- Extra charges
    MTA_TAX FLOAT,                     -- MTA tax
    TIP_AMOUNT FLOAT,                  -- Tip amount
    TOLLS_AMOUNT FLOAT,                -- Tolls amount
    IMPROVEMENT_SURCHARGE FLOAT,       -- Improvement surcharge
    TOTAL_AMOUNT FLOAT,                -- Total amount
    CONGESTION_SURCHARGE FLOAT,        -- Congestion surcharge
    Airport_fee FLOAT                  -- Airport fee
);

-- =============================================
-- STEP 3: SET UP AN EXTERNAL STAGE FOR S3
-- =============================================

-- Create an external stage pointing to your S3 bucket
CREATE OR REPLACE STAGE TAXI_TRIPS_STAGE
    URL = 's3://my-unique-bucket-ag-name-1/'  -- Point to the folder containing Parquet files
    CREDENTIALS = (AWS_KEY_ID = 'xxxxxx' AWS_SECRET_KEY = 'xxxxxxx')
    FILE_FORMAT = (TYPE = PARQUET);  -- Use Parquet file format

-- =============================================
-- STEP 4: CREATE A SNOWPIPE FOR AUTOMATED DATA LOADING
-- =============================================

-- Create a Snowpipe to auto-ingest data from S3
CREATE OR REPLACE PIPE TAXI_TRIPS_PIPE
    AUTO_INGEST = TRUE
    AS
    COPY INTO TAXI_TRIPS
    FROM (
        SELECT
            $1:VendorID::INT,  -- Extract VendorID from Parquet file
            TO_TIMESTAMP($1:tpep_pickup_datetime::BIGINT / 1000000),  -- Convert pickup timestamp to TIMESTAMP
            TO_TIMESTAMP($1:tpep_dropoff_datetime::BIGINT / 1000000),  -- Convert dropoff timestamp to TIMESTAMP
            $1:passenger_count::FLOAT,  -- Extract passenger count
            $1:trip_distance::FLOAT,  -- Extract trip distance
            $1:RatecodeID::FLOAT,  -- Extract rate code ID
            $1:store_and_fwd_flag::STRING,  -- Extract store and forward flag
            $1:PULocationID::INT,  -- Extract pickup location ID
            $1:DOLocationID::INT,  -- Extract dropoff location ID
            $1:payment_type::BIGINT,  -- Extract payment type
            $1:fare_amount::FLOAT,  -- Extract fare amount
            $1:extra::FLOAT,  -- Extract extra charges
            $1:mta_tax::FLOAT,  -- Extract MTA tax
            $1:tip_amount::FLOAT,  -- Extract tip amount
            $1:tolls_amount::FLOAT,  -- Extract tolls amount
            $1:improvement_surcharge::FLOAT,  -- Extract improvement surcharge
            $1:total_amount::FLOAT,  -- Extract total amount
            $1:congestion_surcharge::FLOAT,  -- Extract congestion surcharge
            $1:Airport_fee::FLOAT   -- Extract airport fee
        FROM @TAXI_TRIPS_STAGE)
    FILE_FORMAT = (TYPE = PARQUET);

-- Refresh the pipe to process any pending files
ALTER PIPE TAXI_TRIPS_PIPE REFRESH;

-- Check the status of the pipe
SELECT SYSTEM$PIPE_STATUS('TAXI_TRIPS_PIPE');

-- =============================================
-- STEP 5: VERIFY DATA LOADING
-- =============================================

-- Check the first 10 rows to verify data ingestion
SELECT * FROM TAXI_TRIPS LIMIT 10;

-- Check the schema and data types of the table
DESCRIBE TABLE TAXI_TRIPS;

-- =============================================
-- STEP 7: ADD OPTIMIZATION TECHNIQUES
-- =============================================

-- Optimization 1: Add Clustering Keys
-- Improve query performance by clustering the table on pickup timestamp
ALTER TABLE TAXI_TRIPS CLUSTER BY (tpep_pickup_datetime);

-- Optimization 2: Create a Materialized View for Daily Revenue
-- Precompute daily revenue for faster access
CREATE MATERIALIZED VIEW DAILY_REVENUE AS
SELECT
    DATE(tpep_pickup_datetime) AS TRIP_DATE,
    SUM(TOTAL_AMOUNT) AS DAILY_TOTAL_REVENUE
FROM TAXI_TRIPS
GROUP BY TRIP_DATE;

-- Optimization 3: Enable Search Optimization
-- Speed up point lookup queries on the table
ALTER TABLE TAXI_TRIPS ADD SEARCH OPTIMIZATION;

-- =============================================
-- STEP 8: IMPLEMENT USE CASES WITH QUERIES
-- =============================================

-- Use Case 1: Total Revenue by Payment Type
-- Categorize payment types and calculate total revenue for each
WITH Payment_Categorized AS (
    SELECT
        CASE
            WHEN PAYMENT_TYPE = 1 THEN 'Credit Card'
            WHEN PAYMENT_TYPE = 2 THEN 'Cash'
            ELSE 'Other'
        END AS PAYMENT_METHOD,
        TOTAL_AMOUNT
    FROM TAXI_TRIPS
)
SELECT
    PAYMENT_METHOD,
    SUM(TOTAL_AMOUNT) AS TOTAL_REVENUE
FROM Payment_Categorized
GROUP BY PAYMENT_METHOD
ORDER BY TOTAL_REVENUE DESC;

-- Query 2: Busiest Pickup Locations (Top 5)
-- Find the top 5 pickup locations with the most trips
SELECT
    PULocationID,
    COUNT(*) AS TRIP_COUNT
FROM TAXI_TRIPS
GROUP BY PULocationID
ORDER BY TRIP_COUNT DESC
LIMIT 5;

-- Query 3: Hourly Trip Trends
-- Analyze the number of trips per hour of the day
SELECT
    HOUR(tpep_pickup_datetime) AS PICKUP_HOUR,
    COUNT(*) AS TRIP_COUNT
FROM TAXI_TRIPS
GROUP BY PICKUP_HOUR
ORDER BY PICKUP_HOUR;

-- Query 4: Top 10 Trips with Highest Tips
-- Find the top 10 trips with the highest tips
SELECT
    VendorID,
    tpep_pickup_datetime,
    tpep_dropoff_datetime,
    TIP_AMOUNT
FROM TAXI_TRIPS
ORDER BY TIP_AMOUNT DESC
LIMIT 10;

-- Query 5: Average Trip Distance and Fare for Single-Passenger Trips
-- Calculate the average trip distance and fare for trips with 1 passenger
SELECT
    AVG(TRIP_DISTANCE) AS AVG_TRIP_DISTANCE,
    AVG(FARE_AMOUNT) AS AVG_FARE_AMOUNT
FROM TAXI_TRIPS
WHERE PASSENGER_COUNT = 1;

-- =============================================
-- STEP 9: TIME TRAVEL QUERIES
-- =============================================

-- Time Travel Query 1: Query Historical Data (1 Hour Ago)
-- Retrieve data as it existed 1 hour ago
SELECT *
FROM TAXI_TRIPS AT (TIMESTAMP => DATEADD(HOUR, -1, CURRENT_TIMESTAMP()));

-- Time Travel Query 2: Restore Deleted Data
-- Step 1: Delete some data (e.g., trips with payment type = 1)
DELETE FROM TAXI_TRIPS WHERE PAYMENT_TYPE = 1;

-- Step 2: Query the table to confirm deletion
SELECT * FROM TAXI_TRIPS WHERE PAYMENT_TYPE = 1;

-- Step 3: Restore the deleted data using Time Travel
INSERT INTO TAXI_TRIPS
SELECT * FROM TAXI_TRIPS AT (TIMESTAMP => DATEADD(HOUR, -1, CURRENT_TIMESTAMP()))
WHERE PAYMENT_TYPE = 1;

-- Step 4: Verify the restored data
SELECT * FROM TAXI_TRIPS WHERE PAYMENT_TYPE = 1;

-- Time Travel Query 3: Clone Historical Data (1 Hour Ago)
-- Create a clone of the table as it existed 1 hour ago
CREATE TABLE TAXI_TRIPS_HISTORY CLONE TAXI_TRIPS AT (TIMESTAMP => DATEADD(HOUR, -1, CURRENT_TIMESTAMP()));

-- Query the cloned table to verify historical data
SELECT * FROM TAXI_TRIPS_HISTORY LIMIT 10;

-- =============================================
-- END OF PROJECT
-- =============================================
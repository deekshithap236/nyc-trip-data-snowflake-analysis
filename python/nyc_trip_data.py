from snowflake.snowpark import Session
from snowflake.snowpark.functions import col, to_timestamp, dateadd, hour, sum as snowpark_sum, count as snowpark_count

# Snowflake connection parameters
connection_parameters = {
    "account": "xxxxxxx",          # Snowflake account identifier
    "user": "xxxxxx",              # Snowflake username
    "password": "xxxxxx",          # Snowflake password
    "warehouse": "COMPUTE_WH",     # Snowflake warehouse to use
    "database": "NYC_TAXI_DB_PYTHON",  # Database to connect to
    "schema": "TAXI_SCHEMA"        # Schema to use within the database
}

# Create a Snowpark session
session = Session.builder.configs(connection_parameters).create()

# Use the specified database
session.sql("USE DATABASE NYC_TAXI_DB;").collect()

# Use the specified schema
session.sql("USE SCHEMA TAXI_SCHEMA;").collect()


# =============================================
# STEP 5: VERIFY DATA LOADING
# =============================================

# Query the first 10 rows from the TAXI_TRIPS table
taxi_trips_df = session.table("TAXI_TRIPS")
taxi_trips_df.limit(10).show()
print("First 10 rows in TAXI_TRIPS table:")


# =============================================
# STEP 6: ADD OPTIMIZATION TECHNIQUES
# =============================================

# Add a clustering key to the TAXI_TRIPS table based on pickup datetime
# This improves query performance for time-based queries
session.sql("ALTER TABLE TAXI_TRIPS CLUSTER BY (tpep_pickup_datetime);").collect()
print("Clustering key added to TAXI_TRIPS table.")

# Enable search optimization on the TAXI_TRIPS table
# This speeds up point lookup queries
session.sql("ALTER TABLE TAXI_TRIPS ADD SEARCH OPTIMIZATION;").collect()
print("Search optimization enabled on TAXI_TRIPS table.")


# =============================================
# STEP 7: IMPLEMENT USE CASES WITH QUERIES
# =============================================

# Use Case 1: Calculate Total Revenue by Payment Type
# Group the data by PAYMENT_TYPE and sum the TOTAL_AMOUNT for each group
payment_revenue_df = taxi_trips_df.group_by("PAYMENT_TYPE").agg(
    snowpark_sum("TOTAL_AMOUNT").alias("TOTAL_REVENUE")
)
payment_revenue_df.show()
print("Total Revenue by Payment Type:")

# Use Case 2: Identify the Busiest Pickup Locations (Top 5)
# Group the data by PULocationID, count the number of trips for each location,
# sort by trip count in descending order, and limit the results to the top 5
busiest_locations_df = taxi_trips_df.group_by("PULocationID").agg(
    snowpark_count("*").alias("TRIP_COUNT")
).sort(col("TRIP_COUNT").desc()).limit(5)
busiest_locations_df.show()
print("Busiest Pickup Locations (Top 5):")

# Close the Snowpark session to release resources
session.close()
# dwh_modelling_and_customer_analytics
Repository for 8fit's [technical assignment](https://gist.github.com/rosner/14f9b25abb921394ce3724dd000eb7a3)
 

## Directory Structure and Flow

### DWH_Modelling_Part1: 
Based on https://gist.github.com/rosner/14f9b25abb921394ce3724dd000eb7a3#dwh-modelling
* [SQL Queries](https://github.com/sejalv/dwh_modelling_and_customer_analytics/blob/master/DWH_Modelling_Part1/SQL_queries_analytics.sql) to the first part of the assignment
* Assumptions: For Question 2, "with the MOST installs coming in from Android" is interpreted as channels are ordered as per count of installs coming from Android, and not filtered only for Android.

### Stripe_Webhook_Part2: 
Based on: https://gist.github.com/rosner/14f9b25abb921394ce3724dd000eb7a3#background 

/ Python:
1. [setup.py](https://github.com/sejalv/dwh_modelling_and_customer_analytics/blob/master/Stripe_Webhook_Part2/Python/setup.py) - configuration details for API_KEY and DB_CONN
2. [api_handler.py](https://github.com/sejalv/dwh_modelling_and_customer_analytics/blob/master/Stripe_Webhook_Part2/Python/api_handler.py) - Stripe's webhook function to call API and receive "Events" info.
3. [utilities.py](https://github.com/sejalv/dwh_modelling_and_customer_analytics/blob/master/Stripe_Webhook_Part2/Python/utilities.py) - Parsing of JSON Response and insert to or retrieve details from database. The code has been written for given sample JSON response of type 'Charge.Succeeded', but is flexible to be modified for handling any event type. 

/ SQL:
1. [Data Model](https://github.com/sejalv/dwh_modelling_and_customer_analytics/blob/master/Stripe_Webhook_Part2/SQL/8fit%20-%20Analytics%20-%20Data%20Model.pdf) - Schema Design for analytical purposes
2. [DWH_Schema_Build.sql](https://github.com/sejalv/dwh_modelling_and_customer_analytics/blob/master/Stripe_Webhook_Part2/SQL/DWH_Schema_Build.sql) - Schema Build script for creating the above mentioned data model
3. [Customer_Analytics_Insights.sql](https://github.com/sejalv/dwh_modelling_and_customer_analytics/blob/master/Stripe_Webhook_Part2/SQL/Customer_Analytics_Insights.sql) - Analytical queries based on given use-cases (eg. lifetime value of a customer, cohort analysis and retention info etc.). Provided with sample output
 

## Technologies
* API development: Python 3.6.4
* Database: PostgreSQL 9.6
* Queries: SQL (ANSI / PostgreSQL 9.6)
 

## Notes
* Code in untested, but focused on design and clean structure, and business use-cases
* Sample input data to be created to run the queries
* Configuration parameters to be set in setup.py

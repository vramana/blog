+++
title = "How updated 60 million rows in BigQuery"
date = 2024-06-07T20:35:30+05:30
tags = []
draft = true
layout = "post"
+++

<!--more-->

Data is in 2 place BigTable and BigQuery

I have to update a lot of rows. Fetch data from BigTable and update in BigQuery.

I want to do this quickly and cost efficiently.

If it is not quick probably it's not cost effective. If you have do the operation many many times.

## Naive approach

I don't know how to do a bulk update in bigquery. Some thing like prepared statement.

Fetched some row keys and create a list of update statements

1 update query = 14 MB billed also it takes 2 seconds

## Batching, Indirections and update

Prepare batches and update

2 columns can be used for batch. One is 20x more in size than other

20000 batches, each batch containing 3000 rows

Opted for smaller batch.

Computer science a problem can be solved by indirection.

Staring at SQL query, I figured joins are the way to go.

Upload all data to new table and then go join on both tables.

Batch Size of 10

I can read small batches of data and save as json and load the json file to BigQuery.

I can parallelize this by running many cloud functions in parallel

Ran into BigQuery limitations. Maximum partition modifications.

Tried increasing batch size to 200.

Cloud Functions have to time limit of 9 minutes.

We should get as much data as possible and So that we will ping  bigquery less

Same error from BigQuery. Qouta exhausted.

## Parquet, DuckDB and Object Storage

We can first fetch all data and store it in GCS.

Merge all data into a giant JSON blob and give it to BigQuery.

Only 1 ping so we will avoid quota limits

BigQuery can load in different formats
Parquet has excellent compression compared to JSON

DuckDB has support for parquet.

Ran cloud functions to upload all data to GCS

Batch size of 200 Each parquet file is 20MB. Total of 2GB

DuckDB used to validate all the data. Glob Feature.

Removed some duplicate files.

Merged parquet file is about 400MB. Nice.

JSON would not have been 400MB file.
Lacks nice integration with DuckDB.
Parquet being columnar format helped a lot

Uploaded this file to BigQuery job complete in a minute or two.

Ran the update statement and it finished in under 2 minutes.

18 GB is total bytes processed.


Hotel Booking Analysis (SQL + Python EDA)

This project analyzes hotel booking patterns using SQL, Pandas, NumPy, Matplotlib, and Seaborn.
The goal is to understand cancellations, revenue trends, seasonality, guest types, booking behavior, and generate clear insights.

 Features

SQL data cleaning & transformations

Python EDA using Pandas & NumPy

Feature engineering (guests, nights, revenue, season)

Visualizations using Matplotlib & Seaborn

Clear business insights

Project executed inside a Virtual Environment in VS Code

Tech Stack

SQL (MySQL)

Python

Pandas

NumPy

Matplotlib

Seaborn

Virtual Environment Setup (VS Code)

I created a Python Virtual Environment (venv) inside VS Code to keep the project clean and isolated.

1️) Create virtual environment
python -m venv venv

2️) Activate the environment
On Windows:
venv\Scripts\activate

On macOS/Linux:
source venv/bin/activate

3️) Select venv interpreter in VS Code

Press Ctrl + Shift + P

Type Python: Select Interpreter

Choose →

.venv (or venv) - Python <version>

4️) Install required libraries inside venv
pip install pandas numpy seaborn matplotlib sqlalchemy pymysql

5️) Confirm installation
pip list

Why Virtual Environment?

✔ Keeps project libraries separate
✔ Prevents version conflicts
✔ Makes deployment easier
✔ Cleaner, more professional structure

PROJECT STRUCTURE :-

hotel-booking-analysis/
│
├── venv/                        # Virtual environment
├── data/
│   └── hotel_bookings.csv
│
├── notebooks/
│   └── hotel_booking_analysis.ipynb
│
├── scripts/
│   └── data_cleaning.sql
│   └── python_eda.py
│
└── README.md

Data Cleaning Steps
SQL Cleaning

Remove zero-guest bookings

Remove invalid ADR values

Convert NULL children/babies to 0

Add:

total_guests

total_nights

revenue

Python Cleaning

Handle missing values

Create season-based columns

Create room upgrade/downgrade indicators

Convert dates to proper format

SQL Queries

1️) Total bookings by hotel type
SELECT hotel, COUNT(*) AS total_bookings
FROM hotel_bookings
GROUP BY hotel;

2️) Cancellation rate
SELECT ROUND(AVG(is_canceled)*100,2) AS cancel_rate
FROM hotel_bookings;

3️) Revenue by market segment
SELECT market_segment,
       SUM(adr * (stays_in_weekend_nights + stays_in_week_nights)) AS revenue
FROM hotel_bookings
WHERE is_canceled = 0
GROUP BY market_segment;

4️) ADR by month
SELECT arrival_date_month, AVG(adr)
FROM hotel_bookings
GROUP BY arrival_date_month;

5️) Lead time buckets
SELECT
CASE
    WHEN lead_time <= 7 THEN '0-7'
    WHEN lead_time <= 30 THEN '8-30'
    WHEN lead_time <= 90 THEN '31-90'
    ELSE '90+'
END AS lead_time_bucket,
COUNT(*) AS bookings,
ROUND(AVG(is_canceled)*100,2) AS cancel_rate
FROM hotel_bookings
GROUP BY lead_time_bucket;

Key Visualizations (EDA)

Bookings by hotel

Monthly ADR comparison

Cancellation rate by season

Revenue by market segment

Stay-length distribution

Top 10 countries by bookings

Room upgrade/downgrade analysis

Correlation heatmap

Key Insights

OTA channels → highest cancellation rate

Resort Hotels → highest revenue per booking

Summer → peak demand & highest ADR

Families spend more and cancel less

Long lead-time bookings → most likely to cancel

Repeat guests → more reliable

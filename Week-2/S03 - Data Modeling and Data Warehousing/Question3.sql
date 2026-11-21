
/*==========================================================
  LOAD DIM AIRPORT
==========================================================*/

INSERT INTO dw.DimAirport
(
    airport_code,
    airport_name,
    city,
    country,
    region
)
SELECT
    airport_code,
    airport_name,
    city,
    country,
    region
FROM dbo.bronze_airports;
GO

SELECT *
FROM dw.DimAirport
ORDER BY airport_key;

SELECT
    COUNT(*) AS TotalRecords,
    COUNT(DISTINCT airport_code) AS UniqueAirports
FROM dw.DimAirport;


/*==========================================================
  LOAD DIM AIRCRAFT
  
- aircraft_key is the warehouse surrogate key, generated automatically.
- aircraft_code is the source business key, retained for future lookups.
==========================================================*/

INSERT INTO dw.DimAircraft
(
    aircraft_code,
    model,
    manufacturer,
    seat_capacity
)
SELECT
    aircraft_code,
    model,
    manufacturer,
    seat_capacity
FROM dbo.bronze_aircraft;
GO

SELECT *
FROM dw.DimAircraft
ORDER BY aircraft_key;


SELECT
    COUNT(*) AS TotalRecords,
    COUNT(DISTINCT aircraft_code) AS UniqueAircraft
FROM dw.DimAircraft;


/*==========================================================
  LOAD DIM PASSENGER
  This step is slightly different from the previous two because DimPassenger has a foreign-key relationship with DimAirport.
==========================================================*/

INSERT INTO dw.DimPassenger
(
    passenger_id,
    passenger_name,
    home_airport_key,
    frequent_flyer_tier,
    signup_date
)
SELECT
    p.passenger_id,
    p.passenger_name,
    a.airport_key,
    p.frequent_flyer_tier,
    TRY_CONVERT(DATE, p.signup_date, 23)
FROM dbo.bronze_passengers p
INNER JOIN dw.DimAirport a
    ON p.home_airport_code = a.airport_code;
GO
/*
Why use INNER JOIN? --> Because we have already checked that every passenger's home airport exists in DimAirport.

The join retrieves the corresponding surrogate key.

The date conversion uses style 23, which represents yyyy-MM-dd.
*/

SELECT *
FROM dw.DimPassenger
ORDER BY passenger_key;

SELECT
    COUNT(*) AS TotalRecords,
    COUNT(DISTINCT passenger_id) AS UniquePassengers
FROM dw.DimPassenger;

SELECT
    p.passenger_id,
    p.passenger_name,
    p.home_airport_key,
    a.airport_code,
    a.airport_name
FROM dw.DimPassenger p
INNER JOIN dw.DimAirport a
    ON p.home_airport_key = a.airport_key;


/*==========================================================
  LOAD DIM FLIGHT
==========================================================*/

INSERT INTO dw.DimFlight
(
    flight_id,
    flight_number
)
SELECT
    flight_id,
    flight_number
FROM dbo.bronze_flights;
GO

SELECT *
FROM dw.DimFlight
ORDER BY flight_key;

SELECT
    COUNT(*) AS TotalRecords,
    COUNT(DISTINCT flight_id) AS UniqueFlightIDs,
    COUNT(DISTINCT flight_number) AS UniqueFlightNumbers
FROM dw.DimFlight;


/*==========================================================
  LOAD DIM DATE

  Date sources:
    bronze_bookings.booking_date
    bronze_bookings.travel_date
    bronze_flights.flight_date

  DateKey format: YYYYMMDD
==========================================================*/

;WITH SourceDates AS
(
    -- Booking date: DD-MM-YYYY
    SELECT
        TRY_CONVERT(DATE, booking_date, 105) AS date_value
    FROM dbo.bronze_bookings

    UNION ALL

    -- Travel date: DD-MM-YYYY
    SELECT
        TRY_CONVERT(DATE, travel_date, 105)
    FROM dbo.bronze_bookings

    UNION ALL

    -- Flight date: YYYY-MM-DD
    SELECT
        TRY_CONVERT(DATE, flight_date, 23)
    FROM dbo.bronze_flights
),

DateBounds AS
(
    SELECT
        MIN(date_value) AS min_date,
        MAX(date_value) AS max_date
    FROM SourceDates
    WHERE date_value IS NOT NULL
),

CalendarDates AS
(
    -- Anchor member: Start with minimum date
    SELECT
        min_date AS calendar_date
    FROM DateBounds

    UNION ALL

    -- Recursive member: Add one day
    SELECT
        DATEADD(DAY, 1, c.calendar_date)
    FROM CalendarDates c
    CROSS JOIN DateBounds b
    WHERE c.calendar_date < b.max_date
)

INSERT INTO dw.DimDate
(
    date_key,
    date_value
)
SELECT
    CONVERT(INT, CONVERT(CHAR(8), calendar_date, 112)),
    calendar_date
FROM CalendarDates c
WHERE NOT EXISTS
(
    SELECT 1
    FROM dw.DimDate d
    WHERE d.date_value = c.calendar_date
)
OPTION (MAXRECURSION 0);
GO

SELECT *
FROM dw.DimDate
ORDER BY date_key;

SELECT
    COUNT(*) AS TotalRecords,
    MIN(date_value) AS MinDate,
    MAX(date_value) AS MaxDate,
    MIN(date_key) AS MinDateKey,
    MAX(date_key) AS MaxDateKey
FROM dw.DimDate;

SELECT
    COUNT(*) AS MissingCalendarDays
FROM
(
    SELECT
        DATEADD(
            DAY,
            1,
            LAG(date_value) OVER (ORDER BY date_value)
        ) AS ExpectedNextDate,
        date_value
    FROM dw.DimDate
) d
WHERE ExpectedNextDate IS NOT NULL
  AND ExpectedNextDate <> date_value;

/*==========================================================
  LOAD FACTTICKETSALES
==========================================================*/

INSERT INTO dw.FactTicketSales
(
    booking_id,
    passenger_key,
    flight_key,
    aircraft_key,
    booking_date_key,
    travel_date_key,
    flight_date_key,
    origin_airport_key,
    destination_airport_key,
    fare_class,
    booking_status,
    fare_amount,
    tax_amount,
    miles_earned
)
SELECT
    b.booking_id,

    dp.passenger_key,
    df.flight_key,
    da.aircraft_key,

    db.date_key AS booking_date_key,
    dt.date_key AS travel_date_key,
    dfd.date_key AS flight_date_key,

    ao.airport_key AS origin_airport_key,
    ad.airport_key AS destination_airport_key,

    b.fare_class,
    b.booking_status,

    b.fare_amount,
    b.tax_amount,
    b.miles_earned

FROM dbo.bronze_bookings b

INNER JOIN dbo.bronze_flights f
    ON b.flight_id = f.flight_id

INNER JOIN dw.DimPassenger dp
    ON b.passenger_id = dp.passenger_id

INNER JOIN dw.DimFlight df
    ON f.flight_id = df.flight_id

INNER JOIN dw.DimAircraft da
    ON f.aircraft_code = da.aircraft_code

INNER JOIN dw.DimAirport ao
    ON f.origin_airport_code = ao.airport_code

INNER JOIN dw.DimAirport ad
    ON f.dest_airport_code = ad.airport_code

INNER JOIN dw.DimDate db
    ON TRY_CONVERT(DATE, b.booking_date, 105)
       = db.date_value

INNER JOIN dw.DimDate dt
    ON TRY_CONVERT(DATE, b.travel_date, 105)
       = dt.date_value

INNER JOIN dw.DimDate dfd
    ON TRY_CONVERT(DATE, f.flight_date, 23)
       = dfd.date_value;

SELECT
    (SELECT COUNT(*)
     FROM dbo.bronze_bookings) AS BronzeBookingCount,

    (SELECT COUNT(*)
     FROM dw.FactTicketSales) AS FactTicketSalesCount;

SELECT
    COUNT(*) AS TotalRows,
    COUNT(DISTINCT booking_id) AS DistinctBookings
FROM dw.FactTicketSales;

/*==========================================================
  BRONZE VS DW VALIDATION
==========================================================*/
SELECT
    'Bronze' AS Source,
    CAST(SUM(fare_amount) AS DECIMAL(18,2)) AS TotalFare,
    CAST(SUM(tax_amount) AS DECIMAL(18,2)) AS TotalTax,
    CAST(SUM(miles_earned) AS DECIMAL(18,2)) AS TotalMiles
FROM dbo.bronze_bookings

UNION ALL

SELECT
    'Fact' AS Source,
    CAST(SUM(fare_amount) AS DECIMAL(18,2)),
    CAST(SUM(tax_amount) AS DECIMAL(18,2)),
    CAST(SUM(miles_earned) AS DECIMAL(18,2))
FROM dw.FactTicketSales;



SELECT
    ft.booking_id,

    -- Date validation
    b.booking_date AS SourceBookingDate,
    db.date_value AS FactBookingDate,

    b.travel_date AS SourceTravelDate,
    dt.date_value AS FactTravelDate,

    f.flight_date AS SourceFlightDate,
    dfd.date_value AS FactFlightDate,

    -- Airport validation
    f.origin_airport_code AS SourceOrigin,
    ao.airport_code AS FactOrigin,

    f.dest_airport_code AS SourceDestination,
    ad.airport_code AS FactDestination

FROM dw.FactTicketSales ft

INNER JOIN dbo.bronze_bookings b
    ON ft.booking_id = b.booking_id

INNER JOIN dbo.bronze_flights f
    ON b.flight_id = f.flight_id

INNER JOIN dw.DimDate db
    ON ft.booking_date_key = db.date_key

INNER JOIN dw.DimDate dt
    ON ft.travel_date_key = dt.date_key

INNER JOIN dw.DimDate dfd
    ON ft.flight_date_key = dfd.date_key

INNER JOIN dw.DimAirport ao
    ON ft.origin_airport_key = ao.airport_key

INNER JOIN dw.DimAirport ad
    ON ft.destination_airport_key = ad.airport_key

WHERE
       TRY_CONVERT(DATE, b.booking_date, 105) <> db.date_value
    OR TRY_CONVERT(DATE, b.travel_date, 105) <> dt.date_value
    OR TRY_CONVERT(DATE, f.flight_date, 23) <> dfd.date_value
    OR f.origin_airport_code <> ao.airport_code
    OR f.dest_airport_code <> ad.airport_code;

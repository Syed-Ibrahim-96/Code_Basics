
/*==========================================================
  AIRLINE DATA WAREHOUSE - STAR SCHEMA
  Database: SQL Server
  Schema: dw

  Grain:
  One row represents one passenger booking for a
  specific flight (one booking_id).
==========================================================*/


/*==========================================================
  1. CREATE DW SCHEMA
==========================================================*/

IF NOT EXISTS
(
    SELECT 1
    FROM sys.schemas
    WHERE name = 'dw'
)
BEGIN
    EXEC('CREATE SCHEMA dw');
END;
GO


/*==========================================================
  2. DIMENSION: DATE

  Source:
    bronze_bookings.booking_date
    bronze_bookings.travel_date
    bronze_flights.flight_date

  DateKey format: YYYYMMDD
==========================================================*/

CREATE TABLE dw.DimDate
(
    date_key INT NOT NULL PRIMARY KEY,
    date_value DATE NOT NULL UNIQUE
);
GO


/*==========================================================
  3. DIMENSION: AIRPORT

  Source: bronze_airports

  Business Key: airport_code
==========================================================*/

CREATE TABLE dw.DimAirport
(
    airport_key INT IDENTITY(1,1) PRIMARY KEY,

    -- Business key
    airport_code VARCHAR(10) NOT NULL UNIQUE,

    -- Source attributes
    airport_name VARCHAR(100),
    city VARCHAR(50),
    country VARCHAR(50),
    region VARCHAR(50)
);
GO


/*==========================================================
  4. DIMENSION: PASSENGER

  Source: bronze_passengers

  Business Key: passenger_id

  HomeAirportKey references DimAirport.
==========================================================*/

CREATE TABLE dw.DimPassenger
(
    passenger_key INT IDENTITY(1,1) PRIMARY KEY,

    -- Business key
    passenger_id INT NOT NULL UNIQUE,

    -- Source attributes
    passenger_name VARCHAR(100),

    -- Foreign key to DimAirport
    home_airport_key INT NOT NULL,

    frequent_flyer_tier VARCHAR(30),
    signup_date DATE,

    CONSTRAINT FK_DimPassenger_Airport
        FOREIGN KEY (home_airport_key)
        REFERENCES dw.DimAirport(airport_key)
);
GO


/*==========================================================
  5. DIMENSION: AIRCRAFT

  Source: bronze_aircraft

  Business Key: aircraft_code
==========================================================*/

CREATE TABLE dw.DimAircraft
(
    aircraft_key INT IDENTITY(1,1) PRIMARY KEY,

    -- Business key
    aircraft_code VARCHAR(10) NOT NULL UNIQUE,

    -- Source attributes
    model VARCHAR(50),
    manufacturer VARCHAR(50),
    seat_capacity INT
);
GO


/*==========================================================
  6. DIMENSION: FLIGHT

  Source: bronze_flights

  Business Key: flight_id

  Only flight-related descriptive attributes are retained.
  Airport, aircraft and date relationships are maintained
  directly in FactTicketSales.
==========================================================*/

CREATE TABLE dw.DimFlight
(
    flight_key INT IDENTITY(1,1) PRIMARY KEY,

    -- Business key
    flight_id INT NOT NULL UNIQUE,

    -- Descriptive attribute
    flight_number VARCHAR(20)
);
GO


/*==========================================================
  7. FACT: TICKET SALES

  Grain:
  One row per booking_id.

  Source:
  bronze_bookings JOIN bronze_flights

  Degenerate Dimension:
  booking_id

  Dimension Foreign Keys:
  passenger_key
  flight_key
  aircraft_key
  booking_date_key
  travel_date_key
  flight_date_key
  origin_airport_key
  destination_airport_key

  Measures:
  fare_amount
  tax_amount
  miles_earned
==========================================================*/

CREATE TABLE dw.FactTicketSales
(
    -- Degenerate dimension
    booking_id INT NOT NULL PRIMARY KEY,


    /*-----------------------------------------
      DIMENSION FOREIGN KEYS
    -----------------------------------------*/

    passenger_key INT NOT NULL,
    flight_key INT NOT NULL,
    aircraft_key INT NOT NULL,

    -- Date dimension foreign keys
    booking_date_key INT NOT NULL,
    travel_date_key INT NOT NULL,
    flight_date_key INT NOT NULL,

    -- Airport dimension foreign keys
    origin_airport_key INT NOT NULL,
    destination_airport_key INT NOT NULL,


    /*-----------------------------------------
      DESCRIPTIVE ATTRIBUTES
    -----------------------------------------*/

    fare_class VARCHAR(30),
    booking_status VARCHAR(30),


    /*-----------------------------------------
      ADDITIVE MEASURES
    -----------------------------------------*/

    fare_amount DECIMAL(12,2) NOT NULL,
    tax_amount DECIMAL(12,2) NOT NULL,
    miles_earned INT NOT NULL,


    /*-----------------------------------------
      FOREIGN KEY CONSTRAINTS
    -----------------------------------------*/

    CONSTRAINT FK_Fact_Passenger
        FOREIGN KEY (passenger_key)
        REFERENCES dw.DimPassenger(passenger_key),

    CONSTRAINT FK_Fact_Flight
        FOREIGN KEY (flight_key)
        REFERENCES dw.DimFlight(flight_key),

    CONSTRAINT FK_Fact_Aircraft
        FOREIGN KEY (aircraft_key)
        REFERENCES dw.DimAircraft(aircraft_key),

    CONSTRAINT FK_Fact_BookingDate
        FOREIGN KEY (booking_date_key)
        REFERENCES dw.DimDate(date_key),

    CONSTRAINT FK_Fact_TravelDate
        FOREIGN KEY (travel_date_key)
        REFERENCES dw.DimDate(date_key),

    CONSTRAINT FK_Fact_FlightDate
        FOREIGN KEY (flight_date_key)
        REFERENCES dw.DimDate(date_key),

    CONSTRAINT FK_Fact_OriginAirport
        FOREIGN KEY (origin_airport_key)
        REFERENCES dw.DimAirport(airport_key),

    CONSTRAINT FK_Fact_DestinationAirport
        FOREIGN KEY (destination_airport_key)
        REFERENCES dw.DimAirport(airport_key)

);
GO

# Airline data warehouse

A star schema in the `dw` schema on SQL Server. **One row in `FactTicketSales` is one passenger booking** for a specific flight, identified by `booking_id`.

- `PK`primary key
- `FK`foreign key
- `UK`unique business key

```mermaid
erDiagram
    DimDate {
        INT date_key PK
        DATE date_value UK
    }
    DimAirport {
        INT airport_key PK
        VARCHAR airport_code UK
        VARCHAR airport_name
        VARCHAR city
        VARCHAR country
        VARCHAR region
    }
    DimPassenger {
        INT passenger_key PK
        INT passenger_id UK
        VARCHAR passenger_name
        INT home_airport_key FK
        VARCHAR frequent_flyer_tier
        DATE signup_date
    }
    DimAircraft {
        INT aircraft_key PK
        VARCHAR aircraft_code UK
        VARCHAR model
        VARCHAR manufacturer
        INT seat_capacity
    }
    DimFlight {
        INT flight_key PK
        INT flight_id UK
        VARCHAR flight_number
    }
    FactTicketSales {
        INT booking_id PK
        INT passenger_key FK
        INT flight_key FK
        INT aircraft_key FK
        INT booking_date_key FK
        INT travel_date_key FK
        INT flight_date_key FK
        INT origin_airport_key FK
        INT destination_airport_key FK
        VARCHAR fare_class
        VARCHAR booking_status
        DECIMAL fare_amount
        DECIMAL tax_amount
        INT miles_earned
    }
    DimAirport ||--o{ DimPassenger : "home airport"
    DimPassenger ||--o{ FactTicketSales : "passenger"
    DimFlight ||--o{ FactTicketSales : "flight"
    DimAircraft ||--o{ FactTicketSales : "aircraft"
    DimDate ||--o{ FactTicketSales : "booking date"
    DimDate ||--o{ FactTicketSales : "travel date"
    DimDate ||--o{ FactTicketSales : "flight date"
    DimAirport ||--o{ FactTicketSales : "origin"
    DimAirport ||--o{ FactTicketSales : "destination"
```

## Role-playing dimensions

`DimDate` connects to the fact table three times (booking, travel, flight) and `DimAirport` twice (origin, destination).

## One snowflaked link

`DimPassenger` points to `DimAirport` through `home_airport_key`, so the model is a star with a single outrigger.

## Measures

Additive measures are `fare_amount`, `tax_amount` and `miles_earned`. `booking_id` is a degenerate dimension.
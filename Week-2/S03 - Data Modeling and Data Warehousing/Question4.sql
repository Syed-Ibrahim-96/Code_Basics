
BEGIN TRY
    BEGIN TRANSACTION;

    /* =========================================
       Create DimCountry
       ========================================= */

    CREATE TABLE dw.DimCountry
    (
        country_key INT IDENTITY(1,1) PRIMARY KEY,
        country VARCHAR(50) NOT NULL UNIQUE
    );


    /* =========================================
       Create DimCity
       ========================================= */

    CREATE TABLE dw.DimCity
(
    city_key INT IDENTITY(1,1) PRIMARY KEY,
    city VARCHAR(50) NOT NULL,
    region VARCHAR(50),
    country_key INT NOT NULL,

    CONSTRAINT FK_DimCity_DimCountry
        FOREIGN KEY (country_key)
        REFERENCES dw.DimCountry(country_key),

    CONSTRAINT UQ_DimCity_Country_City
        UNIQUE (country_key, city)
);
GO

/* =========================================
       Populate DimCountry
   ========================================= */
INSERT INTO dw.DimCountry (country)
SELECT DISTINCT country
FROM dw.DimAirport
WHERE country IS NOT NULL;
GO

SELECT
    COUNT(*) AS TotalCountries,
    COUNT(DISTINCT country) AS DistinctCountries
FROM dw.DimCountry;


    /* =========================================
       Populate DimCity
       ========================================= */

INSERT INTO dw.DimCity
(
    city,
    region,
    country_key
)
SELECT DISTINCT
    a.city,
    a.region,
    c.country_key
FROM dw.DimAirport a
INNER JOIN dw.DimCountry c
    ON a.country = c.country;
GO

SELECT
    COUNT(*) AS TotalCities,
    COUNT(DISTINCT country_key) AS CountriesRepresented
FROM dw.DimCity;


    /* =========================================
       Add city_key to existing DimAirport
       ========================================= */

    ALTER TABLE dw.DimAirport
    ADD city_key INT NULL;
    GO

    SELECT
    COLUMN_NAME,
    DATA_TYPE,
    IS_NULLABLE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'dw'
  AND TABLE_NAME = 'DimAirport'
  AND COLUMN_NAME = 'city_key';


    /* =========================================
       Populate city_key in DimAirport
       ========================================= */

   UPDATE a
SET a.city_key = c.city_key
FROM dw.DimAirport a
INNER JOIN dw.DimCity c
    ON a.city = c.city
INNER JOIN dw.DimCountry co
    ON a.country = co.country
   AND c.country_key = co.country_key;
GO

SELECT
    COUNT(*) AS TotalAirports,
    SUM(CASE WHEN city_key IS NULL THEN 1 ELSE 0 END) AS MissingCityMappings
FROM dw.DimAirport;

    /* =========================================
       Make city_key NOT NULL
       ========================================= */

ALTER TABLE dw.DimAirport
ALTER COLUMN city_key INT NOT NULL;
GO

SELECT
    COLUMN_NAME,
    DATA_TYPE,
    IS_NULLABLE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'dw'
  AND TABLE_NAME = 'DimAirport'
  AND COLUMN_NAME = 'city_key';

    /* =========================================
       Add the foreign key constraint
       ========================================= */

ALTER TABLE dw.DimAirport
ADD CONSTRAINT FK_DimAirport_DimCity
FOREIGN KEY (city_key)
REFERENCES dw.DimCity(city_key);
GO

    /* =========================================
       Validate the complete geography hierarchy
       ========================================= */

SELECT
    a.airport_key,
    a.airport_code,
    a.airport_name,
    ci.city,
    ci.region,
    co.country
FROM dw.DimAirport a
INNER JOIN dw.DimCity ci
    ON a.city_key = ci.city_key
INNER JOIN dw.DimCountry co
    ON ci.country_key = co.country_key
ORDER BY co.country, ci.city, a.airport_code;

SELECT
    COUNT(*) AS TotalFactRecords,
    SUM(CASE WHEN origin.airport_key IS NULL THEN 1 ELSE 0 END)
        AS MissingOriginAirports,
    SUM(CASE WHEN destination.airport_key IS NULL THEN 1 ELSE 0 END)
        AS MissingDestinationAirports
FROM dw.FactTicketSales f
LEFT JOIN dw.DimAirport origin
    ON f.origin_airport_key = origin.airport_key
LEFT JOIN dw.DimAirport destination
    ON f.destination_airport_key = destination.airport_key;

    /* =========================================
       Drop redundant geography columns
       ========================================= */

ALTER TABLE dw.DimAirport
DROP COLUMN city, country, region;
GO
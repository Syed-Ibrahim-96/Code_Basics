/* Finding constraints as we kept passenger_id as UNIQUE */

SELECT
    name AS ConstraintName,
    type_desc AS ConstraintType
FROM sys.key_constraints
WHERE parent_object_id = OBJECT_ID('dw.DimPassenger')
  AND type = 'UQ';

/* Removing the constraint */

ALTER TABLE dw.DimPassenger
DROP CONSTRAINT UQ__DimPasse__037645878CD63CF4;
GO

/* Add the three SCD Type 2 columns */

ALTER TABLE dw.DimPassenger
ADD
    effective_from DATE NULL,
    effective_to DATE NOT NULL
        CONSTRAINT DF_DimPassenger_effective_to
        DEFAULT ('9999-12-31'),
    is_current BIT NOT NULL
        CONSTRAINT DF_DimPassenger_is_current
        DEFAULT (1);
GO

/* Populate effective_from */

UPDATE dw.DimPassenger
SET effective_from = signup_date;
GO

/* Make effective_from mandatory */

ALTER TABLE dw.DimPassenger
ALTER COLUMN effective_from DATE NOT NULL;
GO

/* Create a filtered unique index - We need to allow multiple historical records but only one current record per passenger. */

CREATE UNIQUE NONCLUSTERED INDEX UX_DimPassenger_Current
ON dw.DimPassenger(passenger_id)
WHERE is_current = 1;
GO

/* Validate the changes */

SELECT
    COUNT(*) AS TotalRecords,
    COUNT(DISTINCT passenger_id) AS DistinctPassengers,

    SUM(CASE WHEN is_current = 1
        THEN 1 ELSE 0 END) AS CurrentPassengers,

    SUM(CASE WHEN effective_from IS NULL
        THEN 1 ELSE 0 END) AS MissingEffectiveFrom,

    SUM(CASE WHEN effective_to IS NULL
        THEN 1 ELSE 0 END) AS MissingEffectiveTo

FROM dw.DimPassenger;

/* Analyse staging updates */

SELECT
    COUNT(*) AS TotalStagingRecords,
    COUNT(DISTINCT passenger_id) AS DistinctPassengers
FROM dbo.stg_passenger_updates;

SELECT
    COUNT(*) AS ExistingPassengers
FROM dbo.stg_passenger_updates s
INNER JOIN dw.DimPassenger p
    ON s.passenger_id = p.passenger_id
   AND p.is_current = 1;

SELECT
    COUNT(*) AS NewPassengers
FROM dbo.stg_passenger_updates s
LEFT JOIN dw.DimPassenger p
    ON s.passenger_id = p.passenger_id
   AND p.is_current = 1
WHERE p.passenger_id IS NULL;

/* Identify changed records */

SELECT
    s.passenger_id,

    -- Passenger name
    p.passenger_name AS OldPassengerName,
    s.passenger_name AS NewPassengerName,

    -- Home airport
    a.airport_code AS OldHomeAirport,
    s.home_airport_code AS NewHomeAirport,

    -- Frequent flyer tier
    p.frequent_flyer_tier AS OldTier,
    s.frequent_flyer_tier AS NewTier

FROM dbo.stg_passenger_updates s

INNER JOIN dw.DimPassenger p
    ON s.passenger_id = p.passenger_id
   AND p.is_current = 1

INNER JOIN dw.DimAirport a
    ON p.home_airport_key = a.airport_key

WHERE
       ISNULL(p.passenger_name, '') 
           <> ISNULL(s.passenger_name, '')

    OR ISNULL(a.airport_code, '')
           <> ISNULL(s.home_airport_code, '')

    OR ISNULL(p.frequent_flyer_tier, '')
           <> ISNULL(s.frequent_flyer_tier, '')

ORDER BY s.passenger_id;

/* Categorize the changes */

SELECT
    COUNT(*) AS TotalChangedPassengers,

    SUM(CASE
        WHEN p.frequent_flyer_tier <> s.frequent_flyer_tier
        THEN 1 ELSE 0
    END) AS TierChanges,

    SUM(CASE
        WHEN a.airport_code <> s.home_airport_code
        THEN 1 ELSE 0
    END) AS HomeAirportChanges,

    SUM(CASE
        WHEN p.frequent_flyer_tier <> s.frequent_flyer_tier
         AND a.airport_code <> s.home_airport_code
        THEN 1 ELSE 0
    END) AS BothChanged

FROM dbo.stg_passenger_updates s

INNER JOIN dw.DimPassenger p
    ON s.passenger_id = p.passenger_id
   AND p.is_current = 1

INNER JOIN dw.DimAirport a
    ON p.home_airport_key = a.airport_key

WHERE
       p.frequent_flyer_tier <> s.frequent_flyer_tier
    OR a.airport_code <> s.home_airport_code;

/* Validate staging airport references */

SELECT
    COUNT(*) AS TotalStagingRecords,
    SUM(CASE
        WHEN a.airport_key IS NULL THEN 1
        ELSE 0
    END) AS MissingAirportMappings
FROM dbo.stg_passenger_updates s
LEFT JOIN dw.DimAirport a
    ON s.home_airport_code = a.airport_code;

/* Validate effective dates */

SELECT
    s.passenger_id,
    p.effective_from,
    CAST('2026-11-17' AS DATE) AS NewEffectiveDate
FROM dbo.stg_passenger_updates s
INNER JOIN dw.DimPassenger p
    ON s.passenger_id = p.passenger_id
   AND p.is_current = 1
WHERE p.effective_from > '2026-11-17';

/* Expire the existing passenger versions that have changed. */

SELECT
    p.passenger_id,
    p.passenger_name,
    p.frequent_flyer_tier AS OldTier,
    s.frequent_flyer_tier AS NewTier,
    a.airport_code AS OldAirport,
    s.home_airport_code AS NewAirport
FROM dw.DimPassenger p
INNER JOIN dbo.stg_passenger_updates s
    ON p.passenger_id = s.passenger_id
INNER JOIN dw.DimAirport a
    ON p.home_airport_key = a.airport_key
WHERE p.is_current = 1
  AND (
        ISNULL(p.passenger_name, '') <> ISNULL(s.passenger_name, '')
        OR ISNULL(a.airport_code, '') <> ISNULL(s.home_airport_code, '')
        OR ISNULL(p.frequent_flyer_tier, '') <> ISNULL(s.frequent_flyer_tier, '')
      );

/* Expire the old passenger versions */

UPDATE p
SET
    p.effective_to = '2026-11-16',
    p.is_current = 0
FROM dw.DimPassenger p
INNER JOIN dbo.stg_passenger_updates s
    ON p.passenger_id = s.passenger_id
INNER JOIN dw.DimAirport a
    ON p.home_airport_key = a.airport_key
WHERE p.is_current = 1
  AND (
        ISNULL(p.passenger_name, '') <> ISNULL(s.passenger_name, '')
        OR ISNULL(a.airport_code, '') <> ISNULL(s.home_airport_code, '')
        OR ISNULL(p.frequent_flyer_tier, '') <> ISNULL(s.frequent_flyer_tier, '')
      );

/* validate the result: */

SELECT
    COUNT(*) AS ExpiredPassengerVersions,
    SUM(CASE WHEN effective_to = '2026-11-16' THEN 1 ELSE 0 END) AS CorrectEndDate
FROM dw.DimPassenger
WHERE is_current = 0;

/* Insert the new versions for the 200 changed passengers */

INSERT INTO dw.DimPassenger
(
    passenger_id,
    passenger_name,
    home_airport_key,
    frequent_flyer_tier,
    signup_date,
    effective_from,
    effective_to,
    is_current
)
SELECT
    s.passenger_id,
    s.passenger_name,
    a.airport_key,
    s.frequent_flyer_tier,
    p.signup_date,
    '2026-11-17',
    '9999-12-31',
    1
FROM dbo.stg_passenger_updates s
INNER JOIN dw.DimPassenger p
    ON s.passenger_id = p.passenger_id
   AND p.is_current = 0
   AND p.effective_to = '2026-11-16'
INNER JOIN dw.DimAirport a
    ON s.home_airport_code = a.airport_code
WHERE
    ISNULL(p.passenger_name, '') <> ISNULL(s.passenger_name, '')
    OR ISNULL(
        (SELECT da.airport_code
         FROM dw.DimAirport da
         WHERE da.airport_key = p.home_airport_key), ''
       ) <> ISNULL(s.home_airport_code, '')
    OR ISNULL(p.frequent_flyer_tier, '') <> ISNULL(s.frequent_flyer_tier, '');

/* validate the result: */

SELECT
    COUNT(*) AS TotalPassengerVersions,
    SUM(CASE WHEN is_current = 1 THEN 1 ELSE 0 END) AS CurrentVersions,
    SUM(CASE WHEN is_current = 0 THEN 1 ELSE 0 END) AS ExpiredVersions
FROM dw.DimPassenger;

/* Insert the 50 new passengers */

INSERT INTO dw.DimPassenger
(
    passenger_id,
    passenger_name,
    home_airport_key,
    frequent_flyer_tier,
    signup_date,
    effective_from,
    effective_to,
    is_current
)
SELECT
    s.passenger_id,
    s.passenger_name,
    a.airport_key,
    s.frequent_flyer_tier,
    NULL,
    '2026-11-17',
    '9999-12-31',
    1
FROM dbo.stg_passenger_updates s
INNER JOIN dw.DimAirport a
    ON s.home_airport_code = a.airport_code
LEFT JOIN dw.DimPassenger p
    ON s.passenger_id = p.passenger_id
WHERE p.passenger_id IS NULL;

/* validate the result: */

SELECT
    COUNT(*) AS TotalPassengerVersions,
    COUNT(DISTINCT passenger_id) AS DistinctPassengers,
    SUM(CASE WHEN is_current = 1 THEN 1 ELSE 0 END) AS CurrentVersions,
    SUM(CASE WHEN is_current = 0 THEN 1 ELSE 0 END) AS ExpiredVersions,
    SUM(CASE WHEN signup_date IS NULL THEN 1 ELSE 0 END) AS NullSignupDates
FROM dw.DimPassenger;

/* Validate Fact table passenger surrogate keys */

SELECT
    COUNT(*) AS TotalFactRecords,
    SUM(
        CASE
            WHEN expected.passenger_key IS NULL THEN 1
            ELSE 0
        END
    ) AS MissingPassengerVersion,
    SUM(
        CASE
            WHEN f.passenger_key <> expected.passenger_key THEN 1
            ELSE 0
        END
    ) AS IncorrectPassengerKey
FROM dw.FactTicketSales f
INNER JOIN dw.DimPassenger current_ref
    ON f.passenger_key = current_ref.passenger_key
INNER JOIN dw.DimDate d
    ON f.booking_date_key = d.date_key
OUTER APPLY
(
    SELECT p.passenger_key
    FROM dw.DimPassenger p
    WHERE p.passenger_id = current_ref.passenger_id
      AND d.date_value >= p.effective_from
      AND d.date_value <= p.effective_to
) expected;

/* Updating effective_from date to minimum of all signup_date. because for 43 accounts booking date is earlier than signup date */

UPDATE dw.DimPassenger
SET effective_from = '2024-11-02'
WHERE signup_date IS NOT NULL
  AND effective_from = signup_date;
GO

SELECT
    COUNT(*) AS OriginalPassengerVersions,
    SUM(
        CASE
            WHEN effective_from = '2024-11-02' THEN 1
            ELSE 0
        END
    ) AS CorrectEffectiveFrom
FROM dw.DimPassenger
WHERE signup_date IS NOT NULL
  AND effective_to IN ('2026-11-16', '9999-12-31')
  AND effective_from = '2024-11-02';
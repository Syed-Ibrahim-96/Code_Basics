
-- Check existing indexes and primary key
EXEC sp_helpindex 'dw.FactTicketSales';
GO

-- Check the primary key definition
SELECT
    i.name AS IndexName,
    i.type_desc AS IndexType,
    i.is_primary_key,
    i.is_unique,
    c.name AS ColumnName,
    ic.key_ordinal
FROM sys.indexes i
INNER JOIN sys.index_columns ic
    ON i.object_id = ic.object_id
   AND i.index_id = ic.index_id
INNER JOIN sys.columns c
    ON ic.object_id = c.object_id
   AND ic.column_id = c.column_id
WHERE i.object_id = OBJECT_ID('dw.FactTicketSales')
ORDER BY i.index_id, ic.key_ordinal;
GO

CREATE PARTITION FUNCTION pf_FactTicketSales_BookingDate (INT)
AS RANGE RIGHT FOR VALUES
(
    20241201,
    20250101,
    20250201,
    20250301,
    20250401,
    20250501,
    20250601,
    20250701,
    20250801,
    20250901,
    20251001,
    20251101,
    20251201,
    20260101,
    20260201,
    20260301,
    20260401
);
GO

CREATE PARTITION SCHEME ps_FactTicketSales
AS PARTITION pf_FactTicketSales_BookingDate
ALL TO ([PRIMARY]);
GO
-- For this assignment, all partitions can reside on the PRIMARY filegroup.
-- In a production warehouse, separate filegroups can be considered for storage management and archival strategies.

-- Check the existing primary key
SELECT
    name AS PrimaryKeyName,
    type_desc AS IndexType
FROM sys.indexes
WHERE object_id = OBJECT_ID('dw.FactTicketSales')
  AND is_primary_key = 1;
GO

-- Drop and recreate the primary key as NONCLUSTERED
ALTER TABLE dw.FactTicketSales
DROP CONSTRAINT PK__FactTick__5DE3A5B1219679D0;
GO

ALTER TABLE dw.FactTicketSales
ADD CONSTRAINT PK_FactTicketSales
PRIMARY KEY NONCLUSTERED (booking_id);
GO

-- Create the partitioned clustered index
CREATE CLUSTERED INDEX CX_FactTicketSales_BookingDate
ON dw.FactTicketSales
(
    booking_date_key,
    booking_id
)
ON ps_FactTicketSales(booking_date_key);
GO

-- Validate the indexes
EXEC sp_helpindex 'dw.FactTicketSales';
GO

-- Validate partition distribution
SELECT
    $PARTITION.pf_FactTicketSales_BookingDate(
        booking_date_key
    ) AS PartitionNumber,
    COUNT(*) AS TotalRecords,
    MIN(booking_date_key) AS MinBookingDateKey,
    MAX(booking_date_key) AS MaxBookingDateKey
FROM dw.FactTicketSales
GROUP BY
    $PARTITION.pf_FactTicketSales_BookingDate(
        booking_date_key
    )
ORDER BY PartitionNumber;
GO

-- Query using the partition column
SELECT
    booking_id,
    booking_date_key,
    fare_amount,
    tax_amount
FROM dw.FactTicketSales
WHERE booking_date_key >= 20250101
  AND booking_date_key < 20250201;
GO

-- Query using a non-partition column
SELECT
    booking_id,
    passenger_key,
    fare_amount,
    booking_status
FROM dw.FactTicketSales
WHERE passenger_key = 700003;
GO

-- The FactTicketSales table was partitioned using the booking_date_key column with monthly RANGE RIGHT partitioning.
-- A partition function defines monthly date boundaries, while a partition scheme maps the partitions to the PRIMARY filegroup.
-- This improves query efficiency for date-based analytical workloads by enabling partition elimination.
-- Queries filtering directly on booking_date_key can access only the relevant partitions, whereas queries filtering on non-partition
-- columns may need to scan multiple partitions.
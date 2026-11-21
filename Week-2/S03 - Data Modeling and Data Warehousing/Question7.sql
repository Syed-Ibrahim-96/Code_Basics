-- The Bronze layer stores raw source data, the Silver layer contains cleansed and validated staging data, 
-- and the Gold layer contains curated analytical structures. 
-- In this project, the Gold layer follows a dimensional modelling approach consisting of fact and dimension tables.
-- The Passenger dimension uses SCD Type 2 to preserve historical changes, while geography is normalized into Country, City and Airport dimensions.

SELECT
    COLUMN_NAME,
    DATA_TYPE,
    CHARACTER_MAXIMUM_LENGTH,
    NUMERIC_PRECISION,
    NUMERIC_SCALE,
    IS_NULLABLE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'dbo'
  AND TABLE_NAME = 'bronze_bookings'
ORDER BY ORDINAL_POSITION;
GO

-- DATA CONTRACT

-- The Bronze Bookings data contract defines the dataset structure, column definitions, data types, allowed values, 
-- data quality expectations, ownership and delivery SLA. It ensures consistency between the source booking system 
-- and downstream analytical systems. Breaking changes require impact assessment and consumer updates, 
-- whereas non-breaking changes, such as adding an optional nullable column, can be introduced without disrupting existing consumers.
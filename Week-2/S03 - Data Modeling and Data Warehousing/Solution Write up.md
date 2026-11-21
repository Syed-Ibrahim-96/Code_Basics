### Q1 – Fact Grain and Column Classification

Defined the **fact table grain** as one row per passenger booking (`booking_id`) for a specific flight. Classified the **dimension keys, descriptive attributes, and additive measures** to establish a clear dimensional model for accurate analytical reporting.

### Q2 – Star Schema Design

Designed a **Star Schema** consisting of **FactTicketSales** and five supporting dimension tables to organize booking transactions for analytical reporting. Implemented **surrogate keys, primary keys, and foreign key relationships** to maintain data integrity and enable efficient dimensional analysis.

### Q3 – Data Loading

Loaded the dimension and fact tables from the **Bronze source data** by resolving business keys to their corresponding **surrogate keys**. Created a continuous **Date Dimension** and validated **record counts, key relationships, and measure reconciliation** to ensure data completeness and accuracy.

### Q4 – Geography Normalization (Snowflake Schema)

Normalized the geographical hierarchy by separating **Country, City, and Airport** into individual dimensions, reducing redundant geographical attributes. Preserved existing **airport surrogate keys and fact table relationships** while maintaining **referential integrity** across the hierarchy.

### Q5 – Passenger SCD Type 2

Implemented **SCD Type 2** on the Passenger dimension to maintain historical records whenever passenger attributes change. Introduced **effective date ranges, current-record indicators, and new surrogate keys** to preserve historical accuracy and ensure fact transactions reference the correct passenger version **as of the booking date**.

### Q6 – Fact Table Partitioning

Designed a **monthly table partitioning** strategy for the FactTicketSales table using the `booking_date_key` column, with SQL Server **partition functions and partition schemes**. This enables **partition elimination** for date-based queries, improving query efficiency and supporting better management of historical booking data.

### Q7(a) – Medallion Architecture Mapping

Mapped the source datasets to the **Bronze, Silver, and Gold layers** based on their processing and transformation stages. Bronze retains **raw source data**, Silver handles **validated and transformed data**, and Gold contains **curated dimensional models** optimized for business intelligence and analytical reporting.

### Q7(b) – Bronze Bookings Data Contract

Defined a **data contract** for Bronze Bookings covering **dataset structure, column definitions, data types, allowed values, data quality rules, ownership, and delivery expectations**. Established **validation mechanisms** to ensure consistency between source data producers and downstream data consumers, while defining how **breaking and non-breaking schema changes** are managed.
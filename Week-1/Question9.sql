-- Question 9

-- The catalogue source now emits a change feed (operation codes. Apply it to cdc_product_changes) with dim_product in a single MERGE that honours the codes:
-- I inserts a new product, U updates an existing one, D deletes it. Acceptance criteria: one MERGE handling all three operations; 
-- include a verification query showing inserted, updated, and deleted products.

DECLARE @merge_check TABLE
(
    merge_action VARCHAR(10),
    product_id INT,
    old_product_name VARCHAR(255),
    new_product_name VARCHAR(255)
);

MERGE INTO dim_product AS tgt
USING cdc_product_changes AS src

ON tgt.product_id = src.product_id

-- UPDATE existing products
WHEN MATCHED AND src.operation = 'U'
THEN UPDATE SET
    tgt.product_name = src.product_name,
    tgt.category_id  = src.category_id,
    tgt.unit_price   = src.unit_price,
    tgt.unit_cost    = src.unit_cost,
    tgt.launch_date  = src.launch_date

-- DELETE existing products
WHEN MATCHED AND src.operation = 'D'
THEN DELETE

-- INSERT new products
WHEN NOT MATCHED AND src.operation = 'I'
THEN INSERT
( product_id, product_name, category_id, unit_price, unit_cost, launch_date )
VALUES
( src.product_id, src.product_name, src.category_id, src.unit_price, src.unit_cost, src.launch_date )

OUTPUT
    $action, COALESCE(inserted.product_id, deleted.product_id), deleted.product_name, inserted.product_name
INTO @merge_check;

SELECT
    merge_action,
    COUNT(*) AS affected_records
FROM @merge_check
GROUP BY merge_action;


SELECT
    merge_action,
    product_id,
    old_product_name,
    new_product_name
FROM @merge_check
ORDER BY merge_action, product_id;


-- RESULT WRITE UP

-- Implemented a CDC-based MERGE process to apply catalogue changes to the dim_product table using a single SQL statement.
-- The process handles new product insertions, updates to existing product details, and deletions based on the source operation codes (I, U, D).
-- Captured the affected records using the OUTPUT clause and validated the inserted, updated, and deleted products through verification queries,
-- ensuring accurate synchronization between the source and target tables.
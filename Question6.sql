-- Question 6

--The catalogue team needs to see everything under a part of the tree. Using a recursive query, list all categories in the subtree rooted at 'Computers' at any depth, 
-- with how deep each sits and a readable path from Computers. 
-- Required output: category_id, category_name, depth_level, category_path
WITH recursive_cte AS
(
SELECT 
		category_id,category_name,
		1 AS depth_level,
		CAST(category_name AS VARCHAR(MAX)) AS category_path
FROM dim_category
WHERE category_name = 'Computers'

UNION ALL

SELECT 
		a.category_id,a.category_name,
		b.depth_level + 1 AS depth_level,
		CAST(b.category_path + ' -> ' + a.category_name AS VARCHAR(MAX)) AS category_path
FROM dim_category AS a
INNER JOIN recursive_cte AS b
ON a.parent_category_id = b.category_id
)

SELECT 
		category_id, category_name,
		depth_level, category_path
FROM recursive_cte
ORDER BY depth_level
OPTION (MAXRECURSION 100);


-- RESULT WRITE UP

-- Retrieved the complete category hierarchy under 'Computers', including all subcategories and their respective levels. 
-- This gives the catalogue team better visibility into the product structure, helping them manage category organization, 
-- maintain accurate product classification, and identify where new products or subcategories should be added.
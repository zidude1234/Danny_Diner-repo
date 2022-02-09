/* --------------------
   Case Study Questions
   --------------------*/

-- 1. What is the total amount each customer spent at the restaurant?
-- 2. How many days has each customer visited the restaurant?
-- 3. What was the first item from the menu purchased by each customer?
-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
-- 5. Which item was the most popular for each customer?
-- 6. Which item was purchased first by the customer after they became a member?
-- 7. Which item was purchased just before the customer became a member?
-- 8. What is the total items and amount spent for each member before they became a member?
-- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - 
--  how many points do customer A and B have at the end of January?

-- Create tables menu, sales and members


DROP TABLE IF EXISTS menu 

CREATE TABLE IF NOT EXISTS menu
(
    product_id integer PRIMARY KEY NOT NULL,
    product_name character varying(5) NOT NULL,
    price numeric NOT NULL
);

DROP TABLE IF EXISTS sales;

CREATE TABLE IF NOT EXISTS sales
(
    customer_id VARCHAR(1)NOT NULL,
  	order_date DATE NOT NULL,
 	product_id INTEGER NOT NULL
);

DROP TABLE IF EXISTS members;

CREATE TABLE IF NOT EXISTS members
(
    customer_id character varying(1) NOT NULL,
    join_date date
)


-- insert data into tables 

INSERT INTO sales
  ("customer_id", "order_date", "product_id")
VALUES
  ('A', '2021-01-01', '1'),
  ('A', '2021-01-01', '2'),
  ('A', '2021-01-07', '2'),
  ('A', '2021-01-10', '3'),
  ('A', '2021-01-11', '3'),
  ('A', '2021-01-11', '3'),
  ('B', '2021-01-01', '2'),
  ('B', '2021-01-02', '2'),
  ('B', '2021-01-04', '1'),
  ('B', '2021-01-11', '1'),
  ('B', '2021-01-16', '3'),
  ('B', '2021-02-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-07', '3');
 
INSERT INTO menu
  ("product_id", "product_name", "price")
VALUES
  ('1', 'sushi', '10'),
  ('2', 'curry', '15'),
  ('3', 'ramen', '12');
	
	
INSERT INTO members
  ("customer_id", "join_date")
VALUES
  ('A', '2021-01-07'),
  ('B', '2021-01-09');
	
-- 1. What is the total amount each customer spent at the restaurant?
SELECT  sales.customer_id, SUM(price)
FROM sales
LEFT JOIN menu
ON sales.product_id = menu.product_id 
GROUP BY 1
ORDER BY 1;

-- 2. How many days has each customer visited the restaurant?
SELECT  customer_id, COUNT(DISTINCT order_date) As "Unique Visits"
FROM sales
GROUP BY 1
ORDER BY 1;

-- 3. What was the first item from the menu purchased by each customer?
SELECT * 	
FROM
		(
		SELECT  DENSE_RANK() OVER(PARTITION BY sales.customer_id ORDER BY order_date) As "row_rank", sales.customer_id, order_date, sales.product_id,product_name 
		FROM sales
		LEFT JOIN menu
		ON sales.product_id  = menu.product_id 
		) As InnerQuery
WHERE row_rank = 1
GROUP BY 1,2,3,4,5;


-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
SELECT  product_name, COUNT(sales.customer_id)
FROM sales
LEFT JOIN menu
ON sales.product_id = menu.product_id 
GROUP BY 1
ORDER BY 2 DESC
LIMIT 1;

--5. Which item was the most popular for each customer?
SELECT * 	
FROM
		(
		SELECT  DENSE_RANK() OVER(PARTITION BY sales.customer_id ORDER BY COUNT(product_name ) DESC) As "track_count", 
		sales.customer_id, sales.product_id,product_name, COUNT(product_name) As "meal_count"
		FROM sales
		LEFT JOIN menu
		ON sales.product_id  = menu.product_id 
		GROUP BY product_name,sales.customer_id,sales.product_id
		) As InnerQuery
WHERE track_count  = 1;

-- 6. Which item was purchased first by the customer after they became a member?
SELECT * 
FROM 	(
		SELECT DENSE_RANK() OVER(PARTITION BY sales.customer_id ORDER BY order_date) As "rank", sales.customer_id, order_date,join_date, sales.product_id,product_name 
		FROM sales
		LEFT JOIN members
		ON sales.customer_id = members.customer_id 
		LEFT JOIN menu
		ON sales.product_id  = menu.product_id
		WHERE join_date <= order_date
		) AS InnerQuery
		
WHERE rank = 1
ORDER BY 2,3

-- 7. Which item was purchased just before the customer became a member?
SELECT * 
FROM 	(
		SELECT DENSE_RANK() OVER(PARTITION BY sales.customer_id ORDER BY order_date DESC) As "rev_rank", sales.customer_id, order_date,join_date, sales.product_id,product_name 
		FROM sales
		LEFT JOIN members
		ON sales.customer_id = members.customer_id 
		LEFT JOIN menu
		ON sales.product_id  = menu.product_id
		WHERE join_date > order_date
		) AS InnerQuery
WHERE rev_rank = 1
ORDER BY 2,3

-- 8. What is the total items and amount spent for each member before they became a member?

SELECT * 
FROM 	(
		SELECT sales.customer_id, SUM(price) 
		FROM sales
		LEFT JOIN members
		ON sales.customer_id = members.customer_id 
		LEFT JOIN menu
		ON sales.product_id  = menu.product_id
		WHERE join_date > order_date
		GROUP BY 1
		) AS InnerQuery

-- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
SELECT customer_id, SUM(Purchase_Points)
FROM
(
			SELECT  sales.customer_id, sales.product_id,product_name,price,
				CASE
					WHEN product_name IN ('curry','ramen')  	THEN price * 10
					WHEN product_name = 'sushi'  	THEN price * 10 * 2
					ELSE -1
				END AS Purchase_Points
			FROM sales
			LEFT JOIN menu
			ON sales.product_id = menu.product_id 
	) As InnerQuery
GROUP BY 1
ORDER BY 1;

-- 10. In the first week after a customer joins the program (including their join date) 
-- they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?
-- Nested CASE

SELECT customer_id, SUM(Purchase_Points)
FROM
(
			SELECT  sales.customer_id, sales.product_id,product_name,join_date, order_date, price,
				CASE
					WHEN join_date > order_date OR order_date > join_date + interval '1 week' 	THEN 
						CASE 
							WHEN product_name IN ('curry','ramen')  	THEN price * 10
							WHEN product_name = 'sushi'  	THEN price * 10 * 2
						END
	
					WHEN order_date BETWEEN join_date AND join_date + interval '1 week'  	THEN  price * 10 * 2
					WHEN join_date IS NULL			THEN
						CASE
							WHEN product_name IN ('curry','ramen')  	THEN price * 10
							WHEN product_name = 'sushi'  	THEN price * 10 * 2
						END
				
				END AS Purchase_Points
			FROM sales
			LEFT JOIN menu
			ON sales.product_id = menu.product_id 
			LEFT JOIN members
			ON sales.customer_id = members.customer_id 
	) As InnerQuery
GROUP BY 1
ORDER BY 1;

-- BONUS QUESTION
-- Join All The Things
-- Recreate the table with: customer_id, order_date, product_name, price, member (Y/N)

SELECT  sales.customer_id, order_date,product_name, price,
	CASE
		WHEN sales.customer_id IN (SELECT members.customer_id FROM members) AND join_date <= order_date 	THEN 'Y'
		WHEN sales.customer_id NOT IN (SELECT members.customer_id FROM members)	THEN 'N'
		ELSE 'N'
	END AS "member(Y/N)"
FROM sales
LEFT JOIN menu
ON sales.product_id = menu.product_id 
LEFT JOIN members
ON sales.customer_id = members.customer_id 
ORDER BY 1,2,3;			
			
-- Danny also requires further information about the ranking of customer products, 
-- but he purposely does not need the ranking for non-member purchases 
-- so he expects null ranking values for the records when customers are not yet part of the loyalty program.

SELECT * , 
			CASE
				WHEN innerquery.membersYN = 'N' THEN NULL
				ELSE DENSE_RANK () OVER(PARTITION BY customer_id, innerquery.membersYN ORDER BY order_date)
			END AS "members"

	FROM 
	(
	SELECT  sales.customer_id, order_date,product_name, price, 
	CASE
		WHEN sales.customer_id IN (SELECT members.customer_id FROM members) AND join_date <= order_date 	THEN 'Y'
		WHEN sales.customer_id NOT IN (SELECT members.customer_id FROM members)	THEN 'N'
		ELSE 'N'
	END AS membersYN
	FROM sales
	LEFT JOIN menu
	ON sales.product_id = menu.product_id 
	LEFT JOIN members
	ON sales.customer_id = members.customer_id 
	ORDER BY 1,2,3
	) As InnerQuery


CREATE SCHEMA dannys_dinner;
use dannys_dinner;

CREATE TABLE sales (
  customer_id VARCHAR(1),
  order_date DATE,
  product_id INTEGER
);


INSERT INTO sales
  (customer_id, order_date, product_id)
VALUES
  ('A', '2021-01-01', 1),
  ('A', '2021-01-01', 2),
  ('A', '2021-01-07', 2),
  ('A', '2021-01-10', 3),
  ('A', '2021-01-11', 3),
  ('A', '2021-01-11', 3),
  ('B', '2021-01-01', 2),
  ('B', '2021-01-02', 2),
  ('B', '2021-01-04', 1),
  ('B', '2021-01-11', 1),
  ('B', '2021-01-16', 3),
  ('B', '2021-02-01', 3),
  ('C', '2021-01-01', 3),
  ('C', '2021-01-01', 3),
  ('C', '2021-01-07', 3);
 


CREATE TABLE menu (
  product_id INTEGER PRIMARY KEY,
  product_name VARCHAR(5),
  price INTEGER
);


INSERT INTO menu
  (product_id, product_name, price)
VALUES
  (1, 'sushi', 10),
  (2, 'curry', 15),
  (3, 'ramen', 12);
  


CREATE TABLE members (
  customer_id VARCHAR(1) PRIMARY KEY,
  join_date DATE
);


INSERT INTO members
  (customer_id, join_date)
VALUES
  ('A', '2021-01-07'),
  ('B', '2021-01-09');
  
  select * from members;
  select * from menu;
  select * from sales;
  
## 1. What is the total amount each customer spent at the restaurant?
SELECT s.customer_id, SUM(m.price) AS TOTAL_AMOUNT_SPENT
FROM sales s JOIN menu m
ON s.product_id = m.product_id
GROUP BY s.customer_id;

## 2. How many days has each customer visited the restaurant?
SELECT customer_id,count(Order_date) as Total_Days_visited_to_res
FROM sales 
GROUP BY customer_id;

## 3. What was the first item from the menu purchased by each customer?
WITH CTE AS(
SELECT s.customer_id,s.order_date,m.product_name,
DENSE_RANK() OVER(PARTITION BY s.customer_id ORDER BY s.order_date) AS Rnk
FROM sales s join menu m ON s.product_id = m.product_id
)
SELECT
CTE.customer_id,
CTE.order_date,
CTE.product_name
FROM CTE
WHERE Rnk=1;

 ##4. What is the most purchased item on the menu and how many times was it purchased by all customers?
 SELECT product_name,count(order_date) as orders
 FROM sales s JOIN menu m ON s.product_id = m.product_id
 GROUP BY product_name
 ORDER BY orders desc
 LIMIT 1;
 
 ## 5. Which item was the most popular for each customer?
 WITH CTE AS(
 SELECT product_name,customer_id,count(order_date) as orders,
 rank() over(partition by customer_id order by count(order_date) DESC)as rnk,
 row_number() over(partition by customer_id order by count(order_date) DESC)as rn
 FROM sales s JOIN menu m ON s.product_id = m.product_id
 GROUP BY product_name,customer_id
 )
 SELECT customer_id,product_name
 FROM CTE
 WHERE rnk = 1;
 
 ##6. Which item was purchased first by the customer after they became a member?
 WITH CTE AS(
 SELECT s.customer_id,order_date,join_date,product_name,
 rank() over(partition by s.customer_id order by order_date) as rnk,
 row_number() over(partition by s.customer_id order by order_date) as rn
 FROM sales s JOIN members mem ON mem.customer_id = s.customer_id 
 JOIN menu m ON s.product_id = m.product_id
 WHERE order_date >= join_date
 )
 SELECT customer_id,product_name
 FROM CTE 
 WHERE rnk = 1
 
##7. Which item was purchased just before the customer became a member?
WITH CTE AS(
SELECT s.customer_id,order_date,join_date,product_name,
rank() over(partition by s.customer_id order by order_date DESC) as rnk,
row_number() over(partition by s.customer_id order by order_date DESC) as rn
FROM sales s JOIN members mem ON mem.customer_id = s.customer_id 
JOIN menu m ON s.product_id = m.product_id
WHERE order_date < join_date
)
SELECT customer_id,product_name
FROM CTE 
WHERE rnk = 1

##8. What is the total items and amount spent for each member before they became a member?
SELECT s.customer_id,COUNT(product_name) AS total_items,sum(price) as amount_spent
FROM sales s JOIN members mem ON mem.customer_id = s.customer_id 
JOIN menu m ON s.product_id = m.product_id
WHERE order_date < join_date
GROUP BY s.customer_id

##9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
SELECT customer_id,
sum(CASE 
WHEN product_name = "sushi" THEN price * 10 * 2 
ELSE price * 10
END) AS Points
FROM menu m JOIN sales s ON s.product_id = m.product_id
GROUP BY customer_id;

##10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?
SELECT s.customer_id,sum(m.price)*10*2 as sum_points
FROM sales s JOIN menu m ON s.product_id = m.product_id
JOIN members mem ON s.customer_id = mem.customer_id
WHERE s.order_date BETWEEN mem.join_date and mem.join_date + 7
and s.order_date <= "2021-01-31"
GROUP BY 1
ORDER BY 1 ASC;

## BONUS QUESTIONS
##1. JOIN ALL THE THINGS
SELECT 
s.customer_id,order_date,product_name,price,
CASE WHEN join_date IS NULL THEN 'N'
     WHEN order_date < join_date THEN 'N'
     ELSE 'Y'
     END AS memeber
FROM sales s JOIN menu m ON s.product_id = m.product_id
LEFT JOIN members mem ON mem.customer_id = s.customer_id
ORDER BY s.customer_id,
order_date,price DESC;

##2. Rank All The Things
WITH CTE AS (
  SELECT 
    S.customer_id, 
    S.order_date, 
    product_name, 
    price, 
    CASE 
      WHEN join_date IS NULL THEN 'N'
      WHEN order_date < join_date THEN 'N'
      ELSE 'Y' 
    END as member 
  FROM 
    SALES as S 
    INNER JOIN MENU AS M ON S.product_id = M.product_id
    LEFT JOIN MEMBERS AS MEM ON MEM.customer_id = S.customer_id
  ORDER BY 
    customer_id, 
    order_date, 
    price DESC
)
SELECT 
  *
  ,CASE 
    WHEN member = 'N'  THEN NULL
    ELSE RANK() OVER(PARTITION BY customer_id, member ORDER BY order_date)  
  END as rnk
FROM CTE;


 
 




  
  
  
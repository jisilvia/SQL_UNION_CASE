-- Subqueries

/*
01 - Are there any products that have never been ordered? 
	 Only use a subquery and no JOINs.
*/
SELECT ProductNumber, ProductName
FROM Products 
WHERE ProductNumber NOT IN
	(
		SELECT DISTINCT(ProductNumber)	# DISTINCT selects unique values only
		FROM Order_Details
	);

/*
02 - Show me customers who have never ordered a helmet
*/
SELECT 
	Customers.CustomerID, 
	CustFirstName, 
	CustLastName,
	HelmetOrders.CustomerID
FROM Customers
LEFT JOIN
	(
		SELECT CustomerID, ProductName
		FROM Orders
		JOIN Order_Details 
			ON Orders.OrderNumber = Order_Details.OrderNumber 
		JOIN Products 
			ON Order_Details.ProductNumber = Products.ProductNumber
		WHERE ProductName LIKE '%helmet%' 	# LIKE = pattern matching
	) AS HelmetOrders
ON Customers.CustomerID = HelmetOrders.CustomerID
WHERE HelmetOrders.CustomerID IS NULL;
	


-- UNION

/*
03.01 - Build a single mailing list that consists of the full name,
		address, city, state, and ZIP Code for customers and employees
03.02 - Alias the columns in the first SELECT to standardize the column names
03.03 - Identify the type of user for each row by adding a string 
		in single quotes to the SELECT field list
*/
SELECT 
	CustFirstName AS FirstName, 	# AS creates new column headers (column headers of first SELECT by default)
	CustLastName AS LastName,
	CustCity AS City,
	CustStreetAddress AS StreetAddress,
	CustState AS State,
	CustZipCode AS ZipCode,
	'Customer' AS UserType			# to distinguish customers from employees; UserType is an ambiguous variable
FROM Customers
UNION
SELECT 
	EmpFirstName, 
	EmpLastName,
	EmpCity,
	EmpStreetAddress,
	EmpState,
	EmpZipCode,
	'Employee'						# no need to add AS UserType
FROM Employees;

/*
04.01 - Build a single mailing list that consists of the name, 
		address, city, state, and ZIP Code for customers, employees, and vendors
04.02 - Sort by the state
04.03 - Only include if they are from TX
*/
SELECT
	CONCAT(CustFirstName, ' ',CustLastName) AS FullName,
	CustCity AS City,
	CustStreetAddress AS StreetAddress,
	CustState AS State,
	CustZipCode AS ZipCode,
	'Customer' AS UserType			
FROM Customers
WHERE CustState IS 'TX'
UNION
SELECT 
	CONCAT(EmpFirstName, ' ',EmpLastName),
	EmpCity,
	EmpStreetAddress,
	EmpState,
	EmpZipCode,
	'Employee'						
FROM Employees
WHERE EmpState IS 'TX'
UNION
SELECT
	VendName,
	VendCity,
	VendStreetAddress,
	VendState,
	VendZipCode,
	'Vendor'
FROM Vendors
WHERE VendState IS 'TX'
ORDER BY UserType;	# can also use column position instead of alias



/*
05.01 - List the customers who ordered a King Cobra Helmet 
		together with the vendors who provide the King Cobra Helmet
05.02 - Identify the user type
05.03 - Sort results to display vendors on top
Customers
	CustomerID
Orders
	OrderNumber
Order_Details
	ProductNumber
Products
*/
SELECT CustFirstName, CustLastName, ProductName 
FROM Customers 
JOIN Orders
	ON Customers.CustomerID = Orders.CustomerID 
JOIN Order_Details 
	ON Orders.OrderNumber = Order_Details.OrderNumber
JOIN Products 
	ON Order_Details.ProductNumber = Products.ProductNumber
WHERE ProductName ='King Cobra Helmet';


/*
Find vendors who provide the King Cobra Helmet
Vendors
	VendorID	
Product Vendors
	ProductNumber
Products
 */
SELECT VendName, ProductName
FROM Vendors 
JOIN Product_Vendors
	ON Vendors.VendorID = Product_Vendors.VendorID 
JOIN Products
	ON Product_Vendors.ProductNumber = Products.ProductNumber
WHERE ProductName = 'King Cobra Helmet';


-- Need to CONCAT the customer first and last name to line up with VendName
SELECT CONCAT(CustFirstName, ' ', CustLastName) AS FullName, ProductName,
'Customer' AS UserType
FROM Customers
JOIN Orders
	ON Customers.CustomerID = Orders.CustomerID 
JOIN Order_Details 
	ON Orders.OrderNumber = Order_Details.OrderNumber
JOIN Products 
	ON Order_Details.ProductNumber = Products.ProductNumber
WHERE ProductName ='King Cobra Helmet'
UNION
SELECT VendName, ProductName,
'Vendor'
FROM Vendors 
JOIN Product_Vendors
	ON Vendors.VendorID = Product_Vendors.VendorID 
JOIN Products
	ON Product_Vendors.ProductNumber = Products.ProductNumber
WHERE ProductName = 'King Cobra Helmet'
ORDER BY UserType DESC;


-- Switch to the sakila database
USE sjilmubu_sakila;

-- CASE

/*
06 - List the customer_id, first_name, last_name, and email 
	 for all customers and denote if they are active or inactive 
 	 with a text expression instead of a 1 or 0 from the active column.
*/
SELECT 
	customer_id,
	first_name,
	last_name,
	email,
	active,
	CASE
		WHEN active = 1 THEN 'active'
		WHEN active = 0 THEN 'inactive'
	END AS customer_status
FROM customer;


/*
07 - Categorize films based on rental duration length. 
	 SELECT the title, rental_duration, and the duration label.
	 Duration labels:
		short: < 4 days
		medium: BETWEEN 4 AND 6 days
		long: > 6 days
 */
SELECT 
	title,
	rental_duration,
	CASE
		WHEN rental_duration < 4 THEN 'short'
		WHEN rental_duration BETWEEN 4 AND 6 THEN 'medium'
		WHEN rental_duration > 6 THEN 'long'
	END AS rental_duration_category
FROM film;

/*
08 - Display film titles, # of times a film was rented, 
	 and a rental ranking text label based on the number of rentals:
	 poor: < 10 rentals
	 average: 10 - 19 rentals
	 good: 20 - 30 rentals
	 excellent: > 30 rentals or everything ELSE
*/
SELECT
	film.film_id,
	title,
	COUNT(*) AS rental_count,
	CASE
		WHEN COUNT(*) < 10 THEN 'poor'
		WHEN COUNT(*) BETWEEN 10 AND 19 THEN 'average'
		WHEN COUNT(*) BETWEEN 20 AND 30 THEN 'good'
		ELSE 'excellend'
	END AS rental_ranking
FROM film
JOIN inventory 
	ON film.film_id = inventory.film_id 
JOIN rental
	ON inventory.inventory_id = rental.inventory_id 
GROUP BY film.film_id;

/*
09 - What is the total replacement cost per rating and rental rate? 
Display the results in 3 ways:
1. rating | rental_rate | total_replacement_cost
2. rental_rate | rating | total_replacement_cost
3. rating | 0.99_replacement_cost | 2.99_replacement_cost | 4.99_replacement_cost
*/
SELECT 
	CASE 
		WHEN rating IS NULL THEN 'Total'
		ELSE rating 
	END AS report_rating,
	SUM(
		CASE
			WHEN rental_rate = 0.99 THEN replacement_cost
		END
	) AS '0.99_replacement_cost',
	SUM(
		CASE
			WHEN rental_rate = 2.99 THEN replacement_cost
		END
	) AS '2.99_replacement_cost',
	SUM(
		CASE
			WHEN rental_rate = 4.99 THEN replacement_cost
		END
	) AS '4.99_replacement_cost'
FROM film
JOIN inventory 
	ON film.film_id = inventory.film_id 
GROUP BY rating
WITH ROLLUP;


-- 10 - Label if a film at the $4.99 rental rate was rented in June 2005.
SELECT
	film_id,
	title,
	rental_rate,
	CASE
		WHEN film_id IN
			(
				SELECT
					film_id
				FROM inventory 
				JOIN rental 
					ON inventory.inventory_id = rental.inventory_id 
				WHERE rental_date BETWEEN '2005-06-01' AND '2005-06-30 23:59:59'
			) THEN 'Rented'
		ELSE 'Not Rented'
	END AS rental_status
FROM film 
WHERE rental_rate = 4.99;

-- 11 - Count the # of films rented vs not rented from the previous query.
SELECT
	rental_status,
	COUNT(*)
FROM 
(
SELECT
	film_id,
	title,
	rental_rate,
	CASE
		WHEN film_id IN
			(
				SELECT
					film_id
				FROM inventory 
				JOIN rental 
					ON inventory.inventory_id = rental.inventory_id 
				WHERE rental_date BETWEEN '2005-06-01' AND '2005-06-30 23:59:59'
			) THEN 'Rented'
		ELSE 'Not Rented'
	END AS rental_status
FROM film 
WHERE rental_rate = 4.99
) AS premium_rental_status
GROUP BY rental_status;

/*
12 - Rewrite the query to count the # of films rented vs not rented 
but use an aggregate function with a CASE statement to return the 
results in this format: 
rented_films|not_rented_films|
------------|----------------|
         300|              36|
 */
SELECT
	COUNT(
		CASE 
			WHEN june_rental.film_id IS NOT NULL THEN 1
		END) AS rented_films,
	COUNT(
		CASE 
			WHEN june_rental.film_id IS NULL THEN 1
		END) AS not_rented_films
FROM film
LEFT JOIN
	(
	SELECT
		DISTINCT(film_id)
	FROM inventory 
	JOIN rental 
		ON inventory.inventory_id = rental.inventory_id 
	WHERE rental_date BETWEEN '2005-06-01' AND '2005-06-30 23:59:59'
	) AS june_rental
	ON film.film_id = june_rental.film_id
WHERE rental_rate = 4.99;
	

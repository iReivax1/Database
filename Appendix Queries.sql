use ssp6g6;
GO


-- Query 1
SELECT PPH.productID, PM.name, CONVERT(DECIMAL(10, 2), AVG(CAST(PPH.price AS FLOAT))) AS AveragePrice
FROM dbo.Product_Price_History PPH INNER JOIN dbo.Product_Maker PM
ON PPH.productID = PM.productID
WHERE (PM.name = 'iPhone Xs') AND 
((PPH.priceStart BETWEEN '2018-08-01' AND '2018-08-31') OR 
(PPH.priceEnd BETWEEN '2018-08-01' AND '2018-08-31') OR 
(PPH.priceStart < '2018-08-01' AND priceEnd = NULL))
GROUP BY PPH.productID, PM.name;
SELECT * FROM Product_Rating;

-- Query 2
WITH MoreThanHundred(productID) AS
	(SELECT productID
	FROM Product_Rating
	WHERE (rating = 5) AND (ratingDate BETWEEN '2018-08-01' AND '2018-08-31')
	GROUP BY productID
	HAVING COUNT(rating) >= 100)

SELECT PR.productID, COUNT(PR.rating) AS NumOfRatings, CONVERT(DECIMAL(10, 2), AVG(CAST(PR.rating AS FLOAT))) AS AverageRating
FROM dbo.Product_Rating PR
WHERE PR.productID IN (SELECT * FROM MoreThanHundred)
GROUP BY PR.productID
ORDER BY AVG(CAST(PR.rating AS FLOAT)) DESC;


-- Query 3.1 -- Average of all products delivered in June
SELECT CONVERT(DECIMAL(10, 2), AVG(CAST(DATEDIFF(day, O.orderedDate, OP.deliveryDate) AS FLOAT))) AS JuneAverageWaitTime
FROM dbo.[Order] O INNER JOIN dbo.Order_Product OP ON O.orderID = OP.orderID
WHERE O.orderedDate BETWEEN '2018-06-1' AND '2018-06-30' AND OP.status = 'delivered';

-- Query 3.2 -- Average of each product delivered in June
WITH JuneDelivery (productID) AS
	(SELECT OP1.productID FROM dbo.[Order] O1
	INNER JOIN dbo.Order_Product OP1 ON O1.orderID = OP1.orderID
	WHERE (O1.orderedDate BETWEEN '2018-06-01' AND '2018-06-30')
	AND (OP1.status = 'delivered'))

SELECT OP.productID, CONVERT(DECIMAL(10, 2), AVG(CAST(DATEDIFF(day, O.orderedDate, OP.deliveryDate) AS FLOAT))) AS JuneAverageWaitTime
FROM dbo.[Order] O INNER JOIN dbo.Order_Product OP ON O.orderID = OP.orderID
WHERE OP.productID IN (SELECT * FROM JuneDelivery)
GROUP BY OP.productID;


-- Query 4
WITH MinimumLatency(duration) AS
	(SELECT TOP 1 CONVERT(DECIMAL(10, 2), AVG(CAST(DATEDIFF(day, C1.dateAssigned, C1.dateAddressed) AS FLOAT)))
	FROM dbo.Complaint C1
	WHERE C1.employeeID IS NOT NULL
	GROUP BY C1.employeeID)

SELECT E.employeeID, E.name, CONVERT(DECIMAL(10, 2), AVG(CAST(DATEDIFF(day, C.dateAssigned, C.dateAddressed) AS FLOAT))) AS LatencyDays
FROM dbo.Complaint C
INNER JOIN dbo.Employee E ON C.employeeID = E.employeeID
GROUP BY E.employeeID, E.name
HAVING CONVERT(DECIMAL(10, 2), AVG(CAST(DATEDIFF(day, C.dateAssigned, C.dateAddressed) AS FLOAT))) <= (SELECT * FROM MinimumLatency);


-- Query 5
SELECT PM.productID, PM.name, COUNT(PSS.shopName) AS NumSellingShops
FROM dbo.Product_Maker PM
INNER JOIN dbo.Product_Shipping_Stock PSS ON PM.productID = PSS.productID
WHERE PM.maker = 'Samsung'
GROUP BY PM.productID, PM.name;


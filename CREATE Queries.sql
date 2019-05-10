-- set initial state
use master;

-- check if there is a database called 'ssp6g6'
-- drop the database and create the tables
IF DB_ID(N'ssp6g6') IS NOT NULL
    BEGIN 
        DROP DATABASE ssp6g6;
        CREATE DATABASE ssp6g6;
    END
ELSE
    BEGIN
        CREATE DATABASE ssp6g6;
    END
GO

-- change database to the newly created 'ssp6g6'
use ssp6g6;
GO

-----------------------------------------------------------------------------------------------------
----------------------------------------- Table Creation --------------------------------------------
-----------------------------------------------------------------------------------------------------
-- User Table
CREATE TABLE [User](
    -- attribute(s)
    userID BIGINT NOT NULL IDENTITY,
    name NVARCHAR(64) NOT NULL,
    password VARCHAR(256) NOT NULL,

    -- primary key(s)
    PRIMARY KEY (userID),

	-- constraint(s) 
	CONSTRAINT User_checkPasswordLength CHECK (DATALENGTH(password) >= 8)
);
GO

-- Employee Table
CREATE TABLE Employee(
    -- attribute(s)
    employeeID BIGINT NOT NULL IDENTITY,
    name NVARCHAR(64) NOT NULL,
    password VARCHAR(256) NOT NULL,
    salary MONEY NOT NULL DEFAULT 0,

    -- primary key(s)
    PRIMARY KEY (employeeID),

    -- constraint(s)
	CONSTRAINT Employee_checkPasswordLength CHECK (DATALENGTH(password) >= 8),
    CONSTRAINT Employee_checkSalary CHECK (salary >= 0)
);
GO

-- Shop Table
CREATE TABLE Shop(
    -- attribute(s)
    name NVARCHAR(64) NOT NULL,

    -- primary key(s)
    PRIMARY KEY (name)
);
GO

-- Product_Category Table
CREATE TABLE Product_Category(
    -- attribute(s)
    name NVARCHAR(64) NOT NULL,
    maker NVARCHAR(64) NOT NULL,
    category NVARCHAR(64) NOT NULL,

    -- primary key(s)
    PRIMARY KEY (name, maker)
);
GO

-- Product_Maker Table
CREATE TABLE Product_Maker(
    -- attribute(s)
    productID BIGINT NOT NULL IDENTITY,
    name NVARCHAR(64) NOT NULL,
    maker NVARCHAR(64) NOT NULL,

    -- primary key(s)
    PRIMARY KEY (productID),

    -- foreign key(s)
    FOREIGN KEY (name, maker) REFERENCES Product_Category(name, maker) ON DELETE CASCADE ON UPDATE CASCADE
);
GO

-- Order Table
CREATE TABLE [Order](
    -- attribute(s)
    orderID BIGINT NOT NULL IDENTITY,
    orderedDate DATE NOT NULL DEFAULT GETDATE(),
    shippingAddr NVARCHAR(256) NOT NULL,
    totalShippingCost MONEY NOT NULL DEFAULT 0,
    totalProductCost MONEY NOT NULL DEFAULT 0,
    userID BIGINT NOT NULL,

    -- primary key(s)
    PRIMARY KEY (orderID),

    -- foreign key(s)
    FOREIGN KEY (userID) REFERENCES [User](userID) ON DELETE CASCADE ON UPDATE CASCADE,

    -- constraint(s)
    CONSTRAINT Order_checkOrderedDate CHECK(DATEDIFF(DAY, GETDATE(), orderedDate) = 0),
    CONSTRAINT Order_checkTotalShippingCost CHECK(totalShippingCost >= 0),
    CONSTRAINT Order_checkTotalProductCost CHECK(totalProductCost >= 0)
);
GO

-- Product_Shipping_Stock Table
CREATE TABLE Product_Shipping_Stock(
    -- attribute(s)
    shopName NVARCHAR(64) NOT NULL,
    productID BIGINT NOT NULL,
    stockQty INT NOT NULL DEFAULT 0,
    itemShippingCost MONEY NOT NULL DEFAULT 0,

    -- primary key(s)
    PRIMARY KEY (shopName, productID),

    -- foreign key(s)
    FOREIGN KEY (shopName) REFERENCES Shop (name) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (productID) REFERENCES Product_Maker(productID) ON DELETE CASCADE ON UPDATE CASCADE, 

    -- constraint(s)
    CONSTRAINT Product_Shipping_Stock_checkStockQty CHECK (stockQty >= 0),
    CONSTRAINT Product_Shipping_Stock_itemShippingCost CHECK (itemShippingCost >= 0)
);
GO

-- Product_Price_History Table
CREATE TABLE Product_Price_History(
    -- attribute(s)
    shopName NVARCHAR(64) NOT NULL,
    productID BIGINT NOT NULL,
    priceStart DATE NOT NULL DEFAULT GETDATE(),
    price MONEY NOT NULL DEFAULT 0,
    priceEnd DATE NULL,

    -- primary key(s)
    PRIMARY KEY (shopName, productID, priceStart),

    -- foreign key(s)
    FOREIGN KEY (shopName, productID) REFERENCES Product_Shipping_Stock (shopName, productID) ON DELETE CASCADE ON UPDATE CASCADE,

    -- constraint(s)
    CONSTRAINT Product_Price_History_checkPriceStart CHECK (DATEDIFF(DAY, GETDATE(), priceStart) >= 0),
    CONSTRAINT Product_Price_History_checkPrice CHECK (price >= 0),
    CONSTRAINT Product_Price_History_checkPriceEnd CHECK (DATEDIFF(DAY, priceStart, priceEnd) >= 0 OR priceEnd IS NULL)
);
GO

-- Order_Product Table
CREATE TABLE Order_Product(
    -- attribute(s)
    shopName NVARCHAR(64) NOT NULL,
    productID BIGINT NOT NULL,
    priceStart DATE NOT NULL,
    orderID BIGINT NOT NULL,
    qty INT NOT NULL DEFAULT 1,
    status VARCHAR(20) NOT NULL DEFAULT 'being processed',
    statChangeDate DATE NOT NULL DEFAULT GETDATE(),
    deliveryDate DATE NULL,

    -- primary key(s)
    PRIMARY KEY (shopName, productID, priceStart, orderID),

    -- foreign key(s)
    FOREIGN KEY (shopName, productID, priceStart) REFERENCES Product_Price_History (shopName, productID, priceStart) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (orderID) REFERENCES [Order] ON DELETE CASCADE ON UPDATE CASCADE,

    -- constraint(s)
    CONSTRAINT Order_Product_checkQty CHECK (qty > 0),
	CONSTRAINT Order_Product_checkStatus CHECK (status IN ('being processed', 'shipped', 'delivered', 'returned')),
    CONSTRAINT Order_Product_checkStatChangeDate CHECK (DATEDIFF(DAY, GETDATE(), statChangeDate) = 0),
    CONSTRAINT Order_Product_checkDeliveryDate CHECK (DATEDIFF(DAY, GETDATE(), deliveryDate) = 0)
);
GO

-- Product_Rating Table
CREATE TABLE Product_Rating(
    -- attribute(s)
    shopName NVARCHAR(64) NOT NULL,
    productID BIGINT NOT NULL,
    priceStart DATE NOT NULL,
    orderID BIGINT NOT NULL,
    userID BIGINT NOT NULL,
    rating INT NOT NULL,
    ratingDate DATE NOT NULL DEFAULT GETDATE(),

    -- primary key(s)
    PRIMARY KEY (shopName, productID, priceStart, orderID, userID),

    -- foreign key(s)
    FOREIGN KEY (shopName, productID, priceStart, orderID) REFERENCES Order_Product (shopName, productID, priceStart, orderID) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (userID) REFERENCES [User] (userID) ON DELETE CASCADE ON UPDATE CASCADE,

    -- constraint(s)
    CONSTRAINT Product_Rating_checkRating CHECK (rating BETWEEN 1 AND 5),
    CONSTRAINT Product_Rating_checkRatingDate CHECK (DATEDIFF(DAY, GETDATE(), ratingDate) = 0)
);
GO

-- Comment Table
CREATE TABLE Comment(
    -- attribute(s)
    commentID BIGINT NOT NULL IDENTITY,
    text NTEXT NOT NULL,
    shopName NVARCHAR(64) NOT NULL,
    productID BIGINT NOT NULL,
    priceStart DATE NOT NULL,
    orderID BIGINT NOT NULL,

    -- primary key(s)
    PRIMARY KEY (commentID),

    -- foreign key(s)
    FOREIGN KEY (shopName, productID, priceStart, orderID) REFERENCES Order_Product (shopName, productID, priceStart, orderID) ON DELETE CASCADE ON UPDATE CASCADE
);
GO

-- Reply Table
CREATE TABLE Reply(
    -- attribute(s)
    replyID BIGINT NOT NULL IDENTITY,
    text NTEXT NOT NULL,
    userID BIGINT NOT NULL,
    commentID BIGINT NOT NULL,

    -- primary key(s)
    PRIMARY KEY (replyID),

    -- foreign key(s)
    FOREIGN KEY (userID) REFERENCES [User] (userID) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (commentID) REFERENCES Comment (commentID) ON DELETE CASCADE ON UPDATE CASCADE
);
GO

-- Complaint Table
CREATE TABLE Complaint(
    -- attribute(s)
    complaintID BIGINT NOT NULL IDENTITY,
    description NTEXT NOT NULL,
    dateFiled DATE NOT NULL DEFAULT GETDATE(),
    dateAddressed DATE NULL,
    dateAssigned DATE NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'pending',
    userID BIGINT NOT NULL,
    employeeID BIGINT NULL,

    -- primary key(s)
    PRIMARY KEY (complaintID),

    -- foreign key(s)
    FOREIGN KEY (userID) REFERENCES [User] (userID) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (employeeID) REFERENCES Employee (employeeID) ON DELETE SET NULL ON UPDATE CASCADE,

    -- constraint(s)
	CONSTRAINT Complaint_checkStatus CHECK (status IN ('pending', 'being handled', 'addressed')),
    CONSTRAINT Complaint_checkDateFiled CHECK (DATEDIFF(DAY, GETDATE(), dateFiled) = 0),
    CONSTRAINT Complaint_checkDateAddressed CHECK (DATEDIFF(DAY, dateAssigned, dateAddressed) >= 0),
    CONSTRAINT Complaint_checkDateAssigned CHECK (DATEDIFF(DAY, dateFiled, dateAssigned) >= 0)
);
GO

-- Shop_Complaint Table
CREATE TABLE Shop_Complaint(
    -- attribute(s)
    complaintID BIGINT NOT NULL REFERENCES Complaint (complaintID) ON DELETE CASCADE ON UPDATE CASCADE,
    shopName NVARCHAR(64) NOT NULL,

    -- primary key(s)
    PRIMARY KEY (complaintID),

    -- foreign key(s)
    FOREIGN KEY (shopName) REFERENCES Shop (name) ON DELETE CASCADE ON UPDATE CASCADE
);
GO

-- Comment_Complaint Table
CREATE TABLE Comment_Complaint(
    -- attribute(s)
    complaintID BIGINT NOT NULL REFERENCES Complaint (complaintID) ON DELETE CASCADE ON UPDATE CASCADE,
    commentID BIGINT NOT NULL,

    -- primary key(s)
    PRIMARY KEY (complaintID),

    -- foreign key(s)
    FOREIGN KEY (commentID) REFERENCES Comment (commentID) ON DELETE CASCADE ON UPDATE CASCADE
);
GO

-- Order_Product_Complaint Table
CREATE TABLE Order_Product_Complaint(
    -- attribute(s)
    complaintID BIGINT NOT NULL REFERENCES Complaint (complaintID) ON DELETE CASCADE ON UPDATE CASCADE,
    shopName NVARCHAR(64) NOT NULL,
    productID BIGINT NOT NULL,
    priceStart DATE NOT NULL,
    orderID BIGINT NOT NULL,
	
    -- primary key(s)
    PRIMARY KEY (complaintID),

    -- foreign key(s)
    FOREIGN KEY (shopName, productID, priceStart, orderID) REFERENCES Order_Product (shopName, productID, priceStart, orderID) ON DELETE CASCADE ON UPDATE CASCADE
);
GO

-----------------------------------------------------------------------------------------------------
------------------------------------------- Trigger(s) ----------------------------------------------
-----------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------
-- @trigger: User_RestrictDeletion
-- @description: Once a user is created, the user cannot be removed from the system
-----------------------------------------------------------------------------------------------------
CREATE TRIGGER User_RestrictDeletion
ON [User]
INSTEAD OF DELETE
AS 
BEGIN
	-- Prevent deletion from User Table
	RAISERROR('Deletion in User Table is strictly not allowed', 11, 0);
END 
GO

-----------------------------------------------------------------------------------------------------
-- @trigger: Shop_RestrictNameChange
-- @description: Once a shop has been created, the shop cannot be deleted and the name cannot be
--				 changed
-----------------------------------------------------------------------------------------------------
CREATE TRIGGER Shop_RestrictNameChange
ON Shop
INSTEAD OF DELETE, UPDATE
AS
BEGIN
	-- Prevent updating/deletion from Shop Table
	RAISERROR('Updating/Deletion in Shop Table is strictly not allowed', 11, 0);
END
GO

-----------------------------------------------------------------------------------------------------
-- @trigger: Order_RestrictChange
-- @description: Once an order is created, the order cannot be deleted and the attributes cannot be
--				 changed
-----------------------------------------------------------------------------------------------------
CREATE TRIGGER Order_RestrictChange
ON [Order]
INSTEAD OF DELETE, UPDATE
AS
BEGIN
	-- Prevent updating of order information
	RAISERROR('Updating/Deletion in Order Table is strictly not allowed', 11, 0);
END
GO

-----------------------------------------------------------------------------------------------------
-- @trigger: Product_Price_History_RestrictChange
-- @description: Once a Product_Price_History is created, it cannot be deleted
-----------------------------------------------------------------------------------------------------
CREATE TRIGGER Product_Price_History_RestrictChange
ON Product_Price_History
INSTEAD OF DELETE
AS
BEGIN
	-- Prevent deletion of product price history
	RAISERROR('Deletion in Product_Price_History Table is strictly not allowed', 11, 0);
END
GO

-----------------------------------------------------------------------------------------------------
-- @trigger: Product_Price_History_checkPreviousPriceEnd
-- @description: Check if any record of a product has priceEnd set as NULL. To insert a new record of 
--				 price, all priceEnd of a product has to be set
-----------------------------------------------------------------------------------------------------
CREATE TRIGGER Product_Price_History_checkPreviousPriceEnd
ON Product_Price_History
INSTEAD OF INSERT
AS
BEGIN
	-- new value(s)
	DECLARE @priceStartClashCount INT
	DECLARE @priceEndClashCount INT
	DECLARE @count INT
	DECLARE @shopName NVARCHAR(64)
	DECLARE @productID BIGINT
	DECLARE @newPriceStart DATE
	DECLARE @newPriceEnd DATE
	DECLARE @newPrice MONEY

	-- get value(s) from inserted Table
	SET @shopName = (SELECT TOP (1) inserted.shopName FROM inserted);
	SET @productID = (SELECT TOP (1) inserted.productID FROM inserted);
	SET @newPriceStart = (SELECT TOP (1) inserted.priceStart FROM inserted);
	SET @newPriceEnd = (SELECT TOP (1) inserted.priceEnd FROM inserted);
	SET @newPrice = (SELECT TOP (1) inserted.price FROM inserted);

	-- check if there are any records with priceEnd set to NULL
	SET @count = (SELECT COUNT(*) FROM Product_Price_History WHERE shopName = @shopName AND productID = @productID AND priceEnd IS NULL);

	-- if there are no records with priceEnd set to NULL
	IF (@count = 0)
	BEGIN
		-- if the new record has priceEnd, check if it will clash with other records
		IF (@newPriceEnd IS NOT NULL)
		BEGIN
			SET @priceEndClashCount = (SELECT COUNT(*) FROM Product_Price_History WHERE shopName = @shopName AND productID = @productID 
			AND @newPriceEnd BETWEEN priceStart AND priceEnd);
		END
		ELSE -- if the new record has no priceEnd, no need to calculate for clashes
		BEGIN
			SET @priceEndClashCount = 0;
		END
		
		-- check if the specified priceStart clashes with other records
		SET @priceStartClashCount = (SELECT COUNT(*) FROM Product_Price_History WHERE shopName = @shopName AND productID = @productID 
		AND @newPriceStart BETWEEN priceStart AND priceEnd);

		-- if there are no clashes
		IF (@priceStartClashCount = 0 AND @priceEndClashCount = 0)
		BEGIN
			INSERT INTO Product_Price_History (shopName, productID, priceStart, price, priceEnd) 
			VALUES (@shopName, @productID, @newPriceStart, @newPrice, @newPriceEnd);
		END
		ELSE -- if there are clashes
		BEGIN
			RAISERROR('There is a clash in priceStart/priceEnd date for the newly inserted record', 11, 0);
		END
	END
	ELSE -- if there exist at least one record with priceEnd date set as NULL
	BEGIN
		RAISERROR('Please ensure that all priceEnd dates are not NULL before inserting a new record', 11, 0);
	END
END
GO

-----------------------------------------------------------------------------------------------------
-- @trigger: Product_Price_History_checkPriceEndClash
-- @description: Check if the change in priceEnd will clash with any current Product_Price_History
-----------------------------------------------------------------------------------------------------
CREATE TRIGGER Product_Price_History_checkPriceEndClash
ON Product_Price_History
INSTEAD OF UPDATE
AS
BEGIN
	-- attribute(s)
	DECLARE @oldShopName NVARCHAR(64)
	DECLARE @oldProductID BIGINT
	DECLARE @oldPriceStart DATE
	DECLARE @oldPriceEnd DATE
	DECLARE @oldPrice MONEY
	DECLARE @priceEndClashCount INT

	-- attribute(s)
	DECLARE @newShopName NVARCHAR(64)
	DECLARE @newProductID BIGINT
	DECLARE @newPriceStart DATE
	DECLARE @newPriceEnd DATE
	DECLARE @newPrice MONEY

	-- get value(s) from deleted Table
	SET @oldshopName = (SELECT TOP (1) deleted.shopName FROM deleted);
	SET @oldproductID = (SELECT TOP (1) deleted.productID FROM deleted);
	SET @oldPriceStart = (SELECT TOP (1) deleted.priceStart FROM deleted);
	SET @oldPriceEnd = (SELECT TOP (1) deleted.priceEnd FROM deleted);
	SET @oldPrice = (SELECT TOP (1) deleted.price FROM deleted);

	-- get value(s) from inserted Table
	SET @newshopName = (SELECT TOP (1) inserted.shopName FROM inserted);
	SET @newproductID = (SELECT TOP (1) inserted.productID FROM inserted);
	SET @newPriceStart = (SELECT TOP (1) inserted.priceStart FROM inserted);
	SET @newPriceEnd = (SELECT TOP (1) inserted.priceEnd FROM inserted);
	SET @newPrice = (SELECT TOP (1) inserted.price FROM inserted);

	IF @newPriceEnd IS NULL -- once a priceEnd is set, it cannot be set to NULL again
	BEGIN
		RAISERROR('Cannot set priceEnd to NULL', 11, 0);
	END
	ELSE
	BEGIN
		-- ensure that shopName, productID, priceStart, price cannot be change
		IF (@oldShopName = @newShopName AND @oldProductID = @newProductID AND @oldPriceStart = @newPriceStart AND @oldPrice = @newPrice)
		BEGIN
			-- check if the new priceEnd will clash with the other records
			SET @priceEndClashCount = (SELECT COUNT(*) FROM Product_Price_History WHERE shopName = @oldShopName 
			AND productID = @oldProductID AND priceStart <> @oldPriceStart AND @newPriceEnd BETWEEN priceStart AND priceEnd);

			-- if there are no clashses
			IF (@priceEndClashCount = 0)
			BEGIN
				UPDATE Product_Price_History SET priceEnd = @newPriceEnd
				WHERE shopName = @oldShopName AND productID = @oldProductID AND priceStart = @oldPriceStart;
			END
			ELSE -- if there are clashes
			BEGIN
				RAISERROR('There is a clash in priceEnd date', 11, 0);
			END
		END
		ELSE -- ensure that only priceEnd date can be updated
		BEGIN
			RAISERROR('Only priceEnd date can be updated in the Product_Price_History Table', 11, 0);
		END
	END
END
GO

-----------------------------------------------------------------------------------------------------
-- @trigger: Order_Product_UpdateTotalProductCost
-- @description: Ensure totalProductCost & totalShippingCost in Order, is kept consistent with the
--				 products in Order_Product, given an orderID 
-----------------------------------------------------------------------------------------------------
CREATE TRIGGER Order_Product_UpdateTotalProductCost
ON Order_Product
AFTER INSERT, DELETE 
AS
BEGIN
	-- variable(s)
	DECLARE @orderID BIGINT
	DECLARE @totalProductCost MONEY
	DECLARE @totalShippingCost MONEY

	-- check if it is a DELETE/UPDATE or INSERT/UPDATE opeartion
	-- retrieve the orderID from deleted table
	SET @orderID = (SELECT TOP (1) deleted.orderID FROM deleted);

	IF @orderID IS NULL -- means that it is a INSERT opeartion
	BEGIN
		SET @orderID = (SELECT TOP (1) inserted.orderID FROM inserted);
	END

	-- retrieve the latest totalProductCost, given the orderID
	SET @totalProductCost = (
		SELECT SUM(Product_Price_History.price * Order_Product.qty)
		FROM [Order]
		INNER JOIN Order_Product ON [Order].orderID = Order_Product.orderID
		INNER JOIN Product_Price_History 
		ON [Order_Product].productID = Product_Price_History.productID 
		AND [Order_Product].shopName = Product_Price_History.shopName 
		AND [Order_Product].priceStart = Product_Price_History.priceStart
		GROUP BY [Order].orderID, totalProductCost
		HAVING [Order].orderID = @orderID
	);

	-- retrieve the latest totalShippingCost, given the orderID
	SET @totalShippingCost = (
		SELECT SUM(itemShippingCost)
		FROM [Order]
		INNER JOIN Order_Product 
		ON [Order].orderID = Order_Product.orderID
		INNER JOIN Product_Shipping_Stock 
		ON [Order_Product].productID = Product_Shipping_Stock.productID 
		AND [Order_Product].shopName = Product_Shipping_Stock.shopName
		GROUP BY [Order].orderID, totalShippingCost
		HAVING [Order].orderID = @orderID
	);

	-- check if totalProductCost is NULL, if it is NULL, set to default value of 0
	IF @totalProductCost IS NULL
	BEGIN
		SET @totalProductCost = 0;
	END

	-- check if totalShippingCost is NULL, if it is NULL, set to default value of 0
	IF @totalShippingCost IS NULL
	BEGIN
		SET @totalShippingCost = 0;
	END

	-- temporary disable trigger to change the totalProductCost and totalShippingCost
	ALTER TABLE [Order] DISABLE TRIGGER Order_RestrictChange;

	-- update to reflect the latest record
	UPDATE [Order]
	SET [Order].totalProductCost = @totalProductCost, [Order].totalShippingCost = @totalShippingCost
	WHERE [Order].orderID = @orderID;

	-- enable trigger after update
	ALTER TABLE [Order] ENABLE TRIGGER Order_RestrictChange;
END
GO

-----------------------------------------------------------------------------------------------------
-- @trigger: Order_Product_StatusChange
-- @description: Change only relevant columns when status of an Order_Product is changed
-----------------------------------------------------------------------------------------------------
CREATE TRIGGER Order_Product_StatusChange
ON Order_Product
AFTER UPDATE
AS
BEGIN
	-- old attribute(s)
	DECLARE @oldShopName NVARCHAR(64)
	DECLARE @oldProductID BIGINT
	DECLARE @oldPriceStart DATE
	DECLARE @oldOrderID BIGINT
	DECLARE @oldQty INT
	DECLARE @oldStatus VARCHAR(20)
	DECLARE @oldStatChangeDate DATE
	DECLARE @oldDeliveryDate DATE

	-- new attribute(s)
	DECLARE @newShopName NVARCHAR(64)
	DECLARE @newProductID BIGINT
	DECLARE @newPriceStart DATE
	DECLARE @newOrderID BIGINT
	DECLARE @newQty INT
	DECLARE @newStatus VARCHAR(20)
	DECLARE @newStatChangeDate DATE
	DECLARE @newDeliveryDate DATE

	-- get all old attributes from deleted table
	SELECT TOP(1) @oldShopName = deleted.shopname, @oldProductID = deleted.productID, @oldPriceStart = deleted.priceStart,
	@oldOrderID = deleted.orderID, @oldQty = deleted.qty, @oldStatus = deleted.status, @oldStatChangeDate = deleted.statChangeDate,
	@oldDeliveryDate = deleted.deliveryDate
	FROM deleted;
	
	-- get all new attributes from inserted table
	SELECT TOP(1) @newShopName = inserted.shopname, @newProductID = inserted.productID, @newPriceStart = inserted.priceStart,
	@newOrderID = inserted.orderID, @newQty = inserted.qty, @newStatus = inserted.status, @newStatChangeDate = inserted.statChangeDate,
	@newDeliveryDate = inserted.deliveryDate
	FROM inserted;

	BEGIN
		-- only status/statChangeDate/deliveryDate can be updated, other attributes should remain the same
		IF (@oldShopName = @newShopName AND @oldProductID = @newProductID AND @oldPriceStart = @newPriceStart AND @oldOrderID = @newOrderID 
			AND @oldQty = @newQty)
		BEGIN
			-- if the current operation wants to change from 'being processed' to 'shipped'
			IF @oldStatus = 'being processed' AND @newStatus = 'shipped'
			BEGIN
				UPDATE Order_Product
				SET status = @newStatus, statChangeDate = GETDATE(), deliveryDate = NULL
				WHERE shopName = @newShopName AND productID = @newProductID AND priceStart = @newPriceStart 
				AND orderID = @newOrderID;
			END
			-- if the current operation wants to change from 'shipped' to 'delivered'
			ELSE IF @oldStatus = 'shipped' AND @newStatus = 'delivered'
			BEGIN
				UPDATE Order_Product
				SET status = @newStatus, statChangeDate = GETDATE(), deliveryDate = GETDATE()
				WHERE shopName = @newShopName AND productID = @newProductID AND priceStart = @newPriceStart 
				AND orderID = @newOrderID;
			END
			-- if the current operation wants to change from 'delivered' to 'returned'
			ELSE IF @oldStatus = 'delivered' AND @newStatus = 'returned'
			BEGIN
				-- ensure that there is only a maximum of 30 days difference between deliveryDate and current date
				IF DATEDIFF(DAY, @oldDeliveryDate, GETDATE()) <= 30
				BEGIN
					UPDATE Order_Product
					SET status = @newStatus, statChangeDate = GETDATE(), deliveryDate = @oldDeliveryDate
					WHERE shopName = @newShopName AND productID = @newProductID AND priceStart = @newPriceStart 
					AND orderID = @newOrderID;
				END
				ELSE -- if 30 days has passed since the deliveryDate
				BEGIN
					RAISERROR('More than 30 days have passed, product cannot be returned', 11, 0);
					ROLLBACK TRANSACTION;
				END
			END
			ELSE -- if there is an invalid transition between statuses
			BEGIN
				RAISERROR('Cannot update status from %s to %s', 11, 0, @oldStatus, @newStatus);
				ROLLBACK TRANSACTION;
			END
		END
		ELSE -- if other parameters other than status, statChangeDate, deliveryDate are updated
			BEGIN
				RAISERROR('Only status, statChangeDate and deliveryDate can be updated in Order_Product Table', 11, 0);
				ROLLBACK TRANSACTION;
			END
	END
END
GO

-----------------------------------------------------------------------------------------------------
-- @trigger: Product_Rating_ratingDate
-- @description: Ensure that ratingDate is kept relevant whenever rating is updated
-----------------------------------------------------------------------------------------------------
CREATE TRIGGER Product_Rating_ratingDate
ON Product_Rating
AFTER UPDATE
AS
BEGIN
	-- old values
	DECLARE @oldShopName NVARCHAR(64) 
    DECLARE @oldProductID BIGINT 
    DECLARE @oldPriceStart DATE 
    DECLARE @oldOrderID BIGINT 
    DECLARE @oldUserID BIGINT 
    DECLARE @oldRating INT 
    DECLARE @oldRatingDate DATE 

	-- new values
	DECLARE @newShopName NVARCHAR(64) 
    DECLARE @newProductID BIGINT 
    DECLARE @newPriceStart DATE 
    DECLARE @newOrderID BIGINT 
    DECLARE @newUserID BIGINT 
    DECLARE @newRating INT 
    DECLARE @newRatingDate DATE 

	-- get old values from deleted table
	SELECT TOP(1) @oldShopName = deleted.shopname, @oldProductID = deleted.productID, @oldPriceStart = deleted.priceStart,
	@oldOrderID = deleted.orderID, @oldUserID = deleted.userID, @oldRating = deleted.rating, @oldRatingDate = deleted.ratingDate
	FROM deleted;
	
	-- get new values from inserted table
	SELECT TOP(1) @newShopName = inserted.shopname, @newProductID = inserted.productID, @newPriceStart = inserted.priceStart,
	@newOrderID = inserted.orderID, @newUserID = inserted.userID, @newRating = inserted.rating, @newRatingDate = inserted.ratingDate
	FROM inserted;

	-- only rating/ratingDate can be updated
	IF (@oldShopName = @newShopName AND @oldProductID = @newProductID AND @oldPriceStart = @newPriceStart AND @oldOrderID = @newOrderID 
		AND @oldUserID = @newUserID)
	BEGIN
		UPDATE Product_Rating
		SET rating = @newRating, ratingDate = GETDATE()
		WHERE shopName = @newShopName AND productID = @newProductID AND priceStart = @newPriceStart AND orderID = @newOrderID 
		AND userID = @newUserID;
	END
	ELSE -- if other parameters other than rating and ratingDate are updated
	BEGIN
		RAISERROR('Only rating and ratingDate can be updated in Product_Rating Table', 11, 0);
		ROLLBACK TRANSACTION;
	END
END
GO

-----------------------------------------------------------------------------------------------------
-- @trigger: Product_Rating_checkUserID
-- @description: Ensure that the user who makes the rating is the one who bought the product
-----------------------------------------------------------------------------------------------------
CREATE TRIGGER Product_Rating_checkUserID
ON Product_Rating
AFTER INSERT
AS
BEGIN
	-- attribute(s)
	DECLARE @orderID BIGINT
	DECLARE @userID BIGINT
	DECLARE @count INT

	-- get value(s)
	SET @orderID = (SELECT TOP (1) inserted.orderID FROM inserted);
	SET @userID = (SELECT TOP (1) inserted.userID FROM inserted);
	SET @count = (SELECT COUNT(*) FROM [Order] WHERE orderID = @orderID AND userID = @userID);

	-- if the user did not purchase the product
	IF (@count = 0)
	BEGIN
		RAISERROR('The user did not purchase the product and hence, cannot rate the product', 11, 0);
		ROLLBACK TRANSACTION;
	END
END
GO

-----------------------------------------------------------------------------------------------------
-- @trigger: Complaint_checkInsertion
-- @description: Ensure that the insertion of complaint don't include attributes such as
--				 dateAddressed, dateAssigned, employeeID
-----------------------------------------------------------------------------------------------------
CREATE TRIGGER Complaint_checkInsertion
ON Complaint
INSTEAD OF INSERT
AS
BEGIN
	-- attribute(s)
	DECLARE @complaintID BIGINT
	DECLARE @userID BIGINT

	-- get value(s)
	SET @complaintID = (SELECT TOP (1) inserted.complaintID FROM inserted);
	SET @userID = (SELECT TOP (1) inserted.userID FROM inserted);

	INSERT INTO Complaint (complaintID, description, dateFiled, status, userID)
	VALUES (@complaintID, (SELECT TOP (1) inserted.description FROM inserted), GETDATE(), 'pending', @userID);
END
GO

-----------------------------------------------------------------------------------------------------
-- @trigger: Complaint_checkUpdate
-- @description: Ensure that only dateFiled, dateAddressed, dateAssigned, status, employeeID can be
--				 updated
-----------------------------------------------------------------------------------------------------
CREATE TRIGGER Complaint_checkUpdate
ON Complaint
INSTEAD OF UPDATE
AS
BEGIN
	-- old attribute(s)
	DECLARE @oldComplaintID BIGINT
	DECLARE @oldDateFiled DATE
	DECLARE @oldDateAddressed DATE
	DECLARE @oldDateAssigned DATE
	DECLARE @oldStatus VARCHAR(20)
	DECLARE @oldUserID BIGINT
	DEClARE @oldEmployeeID BIGINT

	-- new attribute(s)
	DECLARE @newComplaintID BIGINT
	DECLARE @newDateFiled DATE
	DECLARE @newDateAddressed DATE
	DECLARE @newDateAssigned DATE
	DECLARE @newStatus VARCHAR(20)
	DECLARE @newUserID BIGINT
	DEClARE @newEmployeeID BIGINT

	-- get old value(s) from deleted table
	SET @oldComplaintID = (SELECT TOP (1) deleted.complaintID FROM deleted);
	SET @oldDateFiled = (SELECT TOP (1) deleted.dateFiled FROM deleted);
	SET @oldDateAddressed = (SELECT TOP (1) deleted.dateAddressed FROM deleted);
	SET @oldDateAssigned = (SELECT TOP (1) deleted.dateAssigned FROM deleted);
	SET @oldStatus = (SELECT TOP (1) deleted.status FROM deleted);
	SET @oldUserID = (SELECT TOP (1) deleted.userID FROM deleted);
	SET @oldEmployeeID = (SELECT TOP (1) deleted.employeeID FROM deleted);

	-- get new value(s) from inserted table
	SET @newComplaintID = (SELECT TOP (1) inserted.complaintID FROM inserted);
	SET @newDateFiled = (SELECT TOP (1) inserted.dateFiled FROM inserted);
	SET @newDateAddressed = (SELECT TOP (1) inserted.dateAddressed FROM inserted);
	SET @newDateAssigned = (SELECT TOP (1) inserted.dateAssigned FROM inserted);
	SET @newStatus = (SELECT TOP (1) inserted.status FROM inserted);
	SET @newUserID = (SELECT TOP (1) inserted.userID FROM inserted);
	SET @newEmployeeID = (SELECT TOP (1) inserted.employeeID FROM inserted);

	-- only dateAddressed, dateAssigned, status, employeeID can be updated
	IF @oldComplaintID = @newComplaintID AND @oldDateFiled = @newDateFiled AND @oldUserID = @newUserID
	BEGIN
		-- can update from 'being handled' to 'being handled', assuming that there is a change in employee
		IF (@oldStatus = 'pending' AND @newStatus = 'being handled') OR (@oldStatus = 'being handled' and @newStatus = 'being handled')
		BEGIN
			-- ensure that employeeID is specified
			IF @newEmployeeID IS NOT NULL
			BEGIN
				UPDATE Complaint SET status = @newStatus, dateAssigned = GETDATE(), employeeID = @newEmployeeID
				WHERE complaintID = @oldComplaintID;
			END
			ELSE -- otherwise error will be flagged
			BEGIN
				RAISERROR('Please include the employeeID', 11, 0);
			END
		END
		-- update from 'being handled' to 'addressed'
		ELSE IF @oldStatus = 'being handled' AND @newStatus = 'addressed'
		BEGIN
			UPDATE Complaint SET status = @newStatus, dateAddressed = GETDATE()
			WHERE complaintID = @oldComplaintID;
		END
		ELSE -- if there is an invalid transition between statuses
		BEGIN
			RAISERROR('Cannot update status from %s to %s', 11, 0, @oldStatus, @newStatus);
		END
	END
	ELSE -- if other parameters are updated
	BEGIN
		RAISERROR('Only dateAddressed, dateAssigned, status, employeeID can be updated in the Complaint Table', 11, 0);
	END
END
GO

-----------------------------------------------------------------------------------------------------
-- @trigger: Shop_Complaint_checkComplaintExist
-- @description: Ensure that a complaint can only be inside Complaint Table and Shop_Complaint/
--				 Order_Product_Complaint/Comment_Complaint
-----------------------------------------------------------------------------------------------------
CREATE TRIGGER Shop_Complaint_checkComplaintExist
ON Shop_Complaint
AFTER INSERT
AS
BEGIN
	-- attribute(s)
	DECLARE @complaintID BIGINT
	DECLARE @countOrderProductComplaint INT
	DECLARE @countCommentComplaint INT

	-- get values(s)
	SET @complaintID = (SELECT TOP (1) inserted.complaintID FROM inserted);
	SET @countOrderProductComplaint = (SELECT COUNT(*) FROM Order_Product_Complaint WHERE complaintID = @complaintID);
	SET @countCommentComplaint = (SELECT COUNT(*) FROM Comment_Complaint WHERE complaintID = @complaintID);

	-- if it exists in the other two subclass tables
	IF (@countOrderProductComplaint != 0 OR @countCommentComplaint != 0)
	BEGIN
		RAISERROR('The complaint already exists in another relation', 11, 0);
		ROLLBACK TRANSACTION;
	END
END
GO

-----------------------------------------------------------------------------------------------------
-- @trigger: Order_Product_Complaint_checkComplaintExist
-- @description: Ensure that a complaint can only be inside Complaint Table and Shop_Complaint/
--				 Order_Product_Complaint/Comment_Complaint
-----------------------------------------------------------------------------------------------------
CREATE TRIGGER Order_Product_Complaint_checkComplaintExist
ON Order_Product_Complaint
AFTER INSERT
AS
BEGIN
	-- attribute(s)
	DECLARE @complaintID BIGINT
	DECLARE @countShopComplaint INT
	DECLARE @countCommentComplaint INT

	-- get values(s)
	SET @complaintID = (SELECT TOP (1) inserted.complaintID FROM inserted);
	SET @countShopComplaint = (SELECT COUNT(*) FROM Shop_Complaint WHERE complaintID = @complaintID);
	SET @countCommentComplaint = (SELECT COUNT(*) FROM Comment_Complaint WHERE complaintID = @complaintID);

	-- if it exists in the other two subclass tables
	IF (@countShopComplaint != 0 OR @countCommentComplaint != 0)
	BEGIN
		RAISERROR('The complaint already exists in another subclass relation', 11, 0);
		ROLLBACK TRANSACTION;
	END
END
GO

-----------------------------------------------------------------------------------------------------
-- @trigger: Comment_Complaint_checkComplaintExist
-- @description: Ensure that a complaint can only be inside Complaint Table and Shop_Complaint/
--				 Order_Product_Complaint/Comment_Complaint
-----------------------------------------------------------------------------------------------------
CREATE TRIGGER Comment_Complaint_checkComplaintExist
ON Comment_Complaint
AFTER INSERT
AS
BEGIN
	-- attribute(s)
	DECLARE @complaintID BIGINT
	DECLARE @countShopComplaint INT
	DECLARE @countOrderProductComplaint INT

	-- get values(s)
	SET @complaintID = (SELECT TOP (1) inserted.complaintID FROM inserted);
	SET @countShopComplaint = (SELECT COUNT(*) FROM Shop_Complaint WHERE complaintID = @complaintID);
	SET @countOrderProductComplaint = (SELECT COUNT(*) FROM Order_Product_Complaint WHERE complaintID = @complaintID);

	-- if it exists in the other two subclass tables
	IF (@countShopComplaint != 0 OR @countOrderProductComplaint != 0)
	BEGIN
		RAISERROR('The complaint already exists in another subclass relation', 11, 0);
		ROLLBACK TRANSACTION;
	END
END
GO

-----------------------------------------------------------------------------------------------------
-- @trigger: Comment_Complaint_DeleteComplaint
-- @description: Delete the existing complaint in the Complaint Table
-----------------------------------------------------------------------------------------------------
CREATE TRIGGER Comment_Complaint_DeleteComplaint
ON Comment_Complaint
AFTER DELETE
AS
BEGIN
	-- attribute(s)
	DECLARE @complaintID BIGINT

	-- get values(s)
	SET @complaintID = (SELECT TOP (1) deleted.complaintID FROM deleted);
	DELETE FROM Complaint WHERE complaintID = @complaintID;
END
GO

-----------------------------------------------------------------------------------------------------
-- @trigger: Order_Product_Complaint_DeleteComplaint
-- @description: Delete the existing complaint in the Complaint Table
-----------------------------------------------------------------------------------------------------
CREATE TRIGGER Order_Product_Complaint_DeleteComplaint
ON Order_Product_Complaint
AFTER DELETE
AS
BEGIN
	-- attribute(s)
	DECLARE @complaintID BIGINT

	-- get values(s)
	SET @complaintID = (SELECT TOP (1) deleted.complaintID FROM deleted);
	DELETE FROM Complaint WHERE complaintID = @complaintID;
END
GO

-----------------------------------------------------------------------------------------------------
-- @trigger: Shop_Complaint_DeleteComplaint
-- @description: Delete the existing complaint in the Complaint Table
-----------------------------------------------------------------------------------------------------
CREATE TRIGGER Shop_Complaint_DeleteComplaint
ON Shop_Complaint
AFTER DELETE
AS
BEGIN
	-- attribute(s)
	DECLARE @complaintID BIGINT

	-- get values(s)
	SET @complaintID = (SELECT TOP (1) deleted.complaintID FROM deleted);
	DELETE FROM Complaint WHERE complaintID = @complaintID;
END
GO

-----------------------------------------------------------------------------------------------------
-- @trigger: Order_Product_Complaint_checkUserID
-- @description: Ensure that a Order_Product_Complaint can be filed when the user has ordered the
--				 product 
-----------------------------------------------------------------------------------------------------
CREATE TRIGGER Order_Product_Complaint_checkUserID
ON Order_Product_Complaint
AFTER INSERT
AS
BEGIN
	-- attribute(s)
	DECLARE @orderID BIGINT
	DECLARE @userID BIGINT
	DECLARE @count INT

	-- get value(s)
	SET @orderID = (SELECT TOP (1) inserted.orderID FROM inserted);
	SET @userID = (SELECT TOP (1) Complaint.userID FROM Complaint INNER JOIN inserted ON Complaint.complaintID = inserted.complaintID);
	SET @count = (SELECT COUNT(*) FROM [Order] WHERE orderID = @orderID AND userID = @userID);

	IF (@count = 0)
	BEGIN
		RAISERROR('The user did not purchase the product and hence, cannot file a complaint for the product', 11, 0);
		ROLLBACK TRANSACTION;
	END
END
GO
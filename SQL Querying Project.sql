---פרויקט 2

--- question 1
use [WideWorldImporters]
go
WITH tbl1
AS
(
SELECT IvLine.InvoiceLineID
,IvLine.InvoiceID
,IvLine.ExtendedPrice
,IvLine.TaxAmount
,IvLine.ExtendedPrice - IvLine.TaxAmount as Income
,iv.InvoiceDate
,YEAR(iv.InvoiceDate) AS InYear
,MONTH(iv.InvoiceDate) AS InMonth
FROM Sales.InvoiceLines IvLine join Sales.Invoices Iv
	ON IvLine.InvoiceID = Iv.InvoiceID
), tbl2 AS
(
SELECT InYear AS InvoiceYear
,SUM(Income) AS IncomePerYear
,COUNT(DISTINCT InMonth) As NumberOfDistincrMonth
FROM tbl1
GROUP BY InYear
), tbl3 AS
(
SELECT InvoiceYear
, IncomePerYear
, NumberOfDistincrMonth
, IncomePerYear / NumberOfDistincrMonth *12 AS YearlyLinearIcome
FROM tbl2
)
SELECT InvoiceYear
, FORMAT(IncomePerYear,'#,#.00') AS IncomePerYear
, NumberOfDistincrMonth
, FORMAT(YearlyLinearIcome,'#,#.00') AS YearlyLinearIcome
, FORMAT((YearlyLinearIcome / LAG(YearlyLinearIcome)OVER(ORDER BY InvoiceYear)-1)*100,'0.00') AS GrowsRate
FROM tbl3
GO

--
-- QUESTION 2
WITH tbl1
AS
(
SELECT IvLine.InvoiceLineID
,IvLine.InvoiceID
,IvLine.ExtendedPrice
,IvLine.TaxAmount
,IvLine.ExtendedPrice - IvLine.TaxAmount as Income
,iv.InvoiceDate
,YEAR(iv.InvoiceDate) AS InYear
,DATEPART(Q,iv.InvoiceDate) AS InQuarter
,CS.CustomerID
,CS.CustomerName
FROM Sales.InvoiceLines IvLine join Sales.Invoices Iv
	ON IvLine.InvoiceID = Iv.InvoiceID
JOIN Sales.Customers CS
	ON CS.CustomerID = Iv.CustomerID
), tbl2 AS
(
SELECT InYear,InQuarter,CustomerName,
SUM(Income) AS InComePerQuarterYear
FROM tbl1
GROUP BY InYear,InQuarter,CustomerName
), tbl3 AS
(
SELECT *
,ROW_NUMBER()OVER(PARTITION BY InYear,InQuarter ORDER BY InYear,InQuarter,InComePerQuarterYear DESC) AS DNR
FROM tbl2
)
SELECT *
FROM tbl3
WHERE DNR <=5

GO

--QUESTION 3

WITH tbl1
AS
(
SELECT IvLine.InvoiceID
,IvLine.ExtendedPrice
,IvLine.TaxAmount
,IvLine.ExtendedPrice - IvLine.TaxAmount as Income
,SI.StockItemID
,SI.StockItemName
FROM Sales.InvoiceLines IvLine join Warehouse.StockItems SI
	ON IvLine.StockItemID = SI.StockItemID
)
SELECT TOP 10 StockItemID
,StockItemName
,SUM(Income) AS TotalProfit
FROM tbl1
GROUP BY StockItemID,StockItemName
ORDER BY TotalProfit DESC

GO

---QUSTION 4
WITH tb1
AS
(
SELECT SI.StockItemID
,SI.StockItemName
,SI.UnitPrice
,SI.RecommendedRetailPrice
,SI.RecommendedRetailPrice - SI.UnitPrice AS NominalProductProfit
FROM Warehouse.StockItems SI
WHERE si.ValidTo > GETDATE()
)
SELECT ROW_NUMBER()OVER(ORDER BY NominalProductProfit DESC) AS Rn
,*
,DENSE_RANK()OVER(ORDER BY NominalProductProfit DESC) AS DNR
FROM tb1
GO

-- QUESTION 5
WITH tbl1
AS
(
SELECT SP.SupplierID
,SP.SupplierName
,CONCAT( SP.SupplierID ,' - ' ,SP.SupplierName) AS SupplierDetails
,IT.StockItemID
,IT.StockItemName
,CONCAT( IT.StockItemID ,' ',IT.StockItemName) AS ProductDetails
FROM Warehouse.StockItems IT JOIN Purchasing.Suppliers SP
	ON IT.SupplierID = SP.SupplierID
)
SELECT SupplierDetails
,STRING_AGG(ProductDetails, ' /, ') AS ProductDetails
FROM tbl1
GROUP BY SupplierDetails
ORDER BY SUBSTRING(SupplierDetails,2,1),SUBSTRING(SupplierDetails,1,1) -- דואג שהשורות יהיו לפי הסר וש10 לא יהיה לפני 2
GO

--QUESTION 6
WITH tb
AS
(
SELECT IV.CustomerID
,SUM(IvLine.ExtendedPrice) as TotalExtendedPr
FROM Sales.InvoiceLines IvLine join Sales.Invoices Iv
	ON IvLine.InvoiceID = Iv.InvoiceID
GROUP BY IV.CustomerID
)
SELECT TOP 5 CS.CustomerID
,Ci.CityName AS CityName
,CN.CountryName AS CountryName
,CN.Continent
,CN.Region
,FORMAT(TB.TotalExtendedPr,'#,#.00') AS TotalExtendedPrice
FROM TB JOIN Sales.Customers CS
	ON CS.CustomerID = TB.CustomerID
JOIN Application.Cities CI
	ON CI.CityID = CS.DeliveryCityID
JOIN Application.StateProvinces SP
	ON CI.StateProvinceID = SP.StateProvinceID
JOIN Application.Countries CN
	ON SP.CountryID = CN.CountryID
ORDER BY TotalExtendedPr DESC

GO

--QUESTION 7
GO
WITH TB1
AS
(
SELECT YEAR(IV.InvoiceDate) AS InvoiceYear
,MONTH(IV.InvoiceDate) AS InvoiceMonth
,SUM(IvLine.ExtendedPrice - IvLine.TaxAmount) AS MonthlyTotal0
FROM Sales.InvoiceLines IvLine join Sales.Invoices Iv
	ON IvLine.InvoiceID = Iv.InvoiceID
GROUP BY  YEAR(IV.InvoiceDate),MONTH(IV.InvoiceDate)
), 
TB2 AS
(
SELECT InvoiceYear
,CONVERT(varchar(15),InvoiceMonth) AS InvoiceMonth
,MonthlyTotal0 AS MonthlyTotal0
,SUM(MonthlyTotal0)OVER(PARTITION BY InvoiceYear ORDER BY InvoiceMonth
			ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS CumulativeTotal0
FROM TB1 
	UNION ALL
SELECT InvoiceYear --יצירת שורת סיכום
,'Grand Total' AS InvoiceMonth
,SUM(MonthlyTotal0)
,SUM(MonthlyTotal0)
FROM TB1
GROUP BY InvoiceYear
)

SELECT InvoiceYear-- סידור סופי של הטבלא
,InvoiceMonth
,FORMAT(MonthlyTotal0,'#,#.00') AS MonthlyTotal
,FORMAT(CumulativeTotal0,'#,#.00') AS CumulativeTotal
FROM TB2
ORDER BY InvoiceYear,CumulativeTotal0


GO

--QUESTION 8
GO
WITH TB1 
AS
(
SELECT YEAR(OrderDate) AS YE
,MONTH(OrderDate) AS MON
,OrderID
FROM Sales.Orders 
)
SELECT MON AS OrderMonth
, [2013],[2014],[2015],[2016]
FROM TB1
PIVOT (COUNT(OrderID) FOR YE IN ([2013],[2014],[2015],[2016])) AS PIV
ORDER BY OrderMonth

GO

--QUESTION 9
WITH TB1
AS
(
SELECT OrderID
, O.CustomerID
, CUS.CustomerName
, O.OrderDate
, LAG(O.OrderDate)OVER(PARTITION BY O.CustomerID ORDER BY O.OrderDate) AS PreviousOrderDate
--, MIN(O.OrderDate)OVER(PARTITION BY O.CustomerID) AS FirstOrder
--, MAX(O.OrderDate)OVER(PARTITION BY O.CustomerID) AS LastOrder
, DATEDIFF(dd,MIN(O.OrderDate)OVER(PARTITION BY O.CustomerID), MAX(O.OrderDate)OVER(PARTITION BY O.CustomerID)) AS DIFF
, COUNT(O.OrderID)OVER(PARTITION BY O.CustomerID) AS OrderCount
, MAX(O.OrderDate)OVER(PARTITION BY O.CustomerID) AS LastCustOrderDate
, MAX(O.OrderDate)OVER() AS LastOrderDateAll
, DATEDIFF(dd,MAX(O.OrderDate)OVER(PARTITION BY O.CustomerID), MAX(O.OrderDate)OVER() )  AS DaysSinceLastOrder
FROM Sales.Orders O JOIN Sales.Customers CUS
	ON O.CustomerID = CUS.CustomerID
), TB2 AS
(
SELECT OrderID
,CEILING(DIFF/OrderCount) AS AvgDaysBetweenOrders
FROM TB1
)
select TB1.CustomerID
, TB1.CustomerName
, TB1.OrderDate
, TB1.PreviousOrderDate
, TB2.AvgDaysBetweenOrders
, TB1.LastCustOrderDate
, TB1.LastOrderDateAll
, TB1.DaysSinceLastOrder
, CASE WHEN TB1.DaysSinceLastOrder > 2*TB2.AvgDaysBetweenOrders 
			THEN 'Potential Chum'
	   ELSE
			'Active'
  END AS CustomerStatus
FROM TB1 JOIN TB2
	ON TB1.OrderID = TB2.OrderID
ORDER BY TB1.CustomerID,TB1.OrderDate

GO


-- QUESTION 10
WITH TB1
AS
(
SELECT cus.CustomerID
, cus.CustomerName
,CASE WHEN cus.CustomerName LIKE 'Tailspin%'
		THEN 'Tail'
	  WHEN cus.CustomerName LIKE 'Wingtip%'
	    THEN 'Wing'
	 ELSE
	   cus.CustomerName
	END AS DistName
, cat.CustomerCategoryName
FROM Sales.Customers cus JOIN Sales.CustomerCategories AS cat
	ON cus.CustomerCategoryID = cat.CustomerCategoryID
),
TB2 AS
(
SELECT CustomerCategoryName
, COUNT(DISTINCT DistName) AS CustomerCOUNT
FROM TB1
GROUP BY CustomerCategoryName
)
SELECT CustomerCategoryName
, CustomerCOUNT
, SUM(CustomerCOUNT)OVER() AS TotalCustCount
, FORMAT(CONVERT(MONEY,CustomerCOUNT)*100/SUM(CustomerCOUNT)OVER(), '#,#.00''%') AS DistributionFactor
FROM TB2
ORDER BY CustomerCategoryName

USE [WideWorldImporters]
GO

---ИЗНАЧАЛЬНЫЙ

SET STATISTICS IO, time ON 

Select ord.CustomerID, det.StockItemID, SUM(det.UnitPrice), SUM(det.Quantity), COUNT(ord.OrderID)
	
FROM Sales.Orders AS ord
	JOIN Sales.OrderLines AS det
		ON det.OrderID = ord.OrderID
	JOIN Sales.Invoices AS Inv
		ON Inv.OrderID = ord.OrderID
	JOIN Sales.CustomerTransactions AS Trans
		ON Trans.InvoiceID = Inv.InvoiceID
	JOIN Warehouse.StockItemTransactions AS ItemTrans
		ON ItemTrans.StockItemID = det.StockItemID

WHERE 
		Inv.BillToCustomerID != ord.CustomerID
AND		(Select SupplierId
		FROM Warehouse.StockItems AS It
		Where It.StockItemID = det.StockItemID) = 12

AND		(SELECT SUM(Total.UnitPrice*Total.Quantity)
		FROM Sales.OrderLines AS Total
		Join Sales.Orders AS ordTotal
		On ordTotal.OrderID = Total.OrderID
		WHERE ordTotal.CustomerID = Inv.CustomerID) > 250000
AND		DATEDIFF(dd, Inv.InvoiceDate, ord.OrderDate) = 0
	
GROUP BY ord.CustomerID, det.StockItemID
ORDER BY ord.CustomerID, det.StockItemID

SET STATISTICS IO, time OFF

GO


SET STATISTICS IO, time ON 

---ИЗМЕНЕННЫЙ

Select ord.CustomerID, det.StockItemID, SUM(det.UnitPrice), SUM(det.Quantity), COUNT(ord.OrderID)
	
FROM Sales.Orders AS ord --WITH (READPAST)
	JOIN Sales.OrderLines AS det
		ON det.OrderID = ord.OrderID
	JOIN Sales.Invoices AS Inv --WITH (INDEX ([FK_Sales_Invoices_OrderID])) - и так самый подходящий используется
		ON Inv.OrderID = ord.OrderID
	JOIN Sales.CustomerTransactions AS Trans --WITH (INDEX ([FK_Sales_CustomerTransactions_InvoiceID]))- и так самый подходящий используется
		ON Trans.InvoiceID = Inv.InvoiceID
	JOIN Warehouse.StockItemTransactions AS ItemTrans --WITH (INDEX ([CCX_Warehouse_StockItemTransactions]))
		ON ItemTrans.StockItemID = det.StockItemID
	

WHERE 
		Inv.BillToCustomerID != ord.CustomerID
AND		(Select SupplierId
		FROM Warehouse.StockItems AS It WITH (INDEX ([FK_Warehouse_StockItems_SupplierID]))
		Where It.StockItemID = det.StockItemID) = 12

AND		(SELECT SUM(Total.UnitPrice*Total.Quantity)
		FROM Sales.OrderLines AS Total
		Join Sales.Orders AS ordTotal
		On ordTotal.OrderID = Total.OrderID
		WHERE ordTotal.CustomerID = Inv.CustomerID) > 250000
AND		DATEDIFF(dd, Inv.InvoiceDate, ord.OrderDate) = 0
	
GROUP BY ord.CustomerID, det.StockItemID
ORDER BY ord.CustomerID, det.StockItemID

--OPTION (OPTIMIZE FOR UNKNOWN)
--OPTION (FORCE ORDER)

--OPTION


SET STATISTICS IO, time OFF
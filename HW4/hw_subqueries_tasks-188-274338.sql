/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "03 - Подзапросы, CTE, временные таблицы".

Задания выполняются с использованием базы данных WideWorldImporters.

Бэкап БД можно скачать отсюда:
https://github.com/Microsoft/sql-server-samples/releases/tag/wide-world-importers-v1.0
Нужен WideWorldImporters-Full.bak

Описание WideWorldImporters от Microsoft:
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-what-is
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-oltp-database-catalog
*/

-- ---------------------------------------------------------------------------
-- Задание - написать выборки для получения указанных ниже данных.
-- Для всех заданий, где возможно, сделайте два варианта запросов:
--  1) через вложенный запрос
--  2) через WITH (для производных таблиц)
-- ---------------------------------------------------------------------------

USE WideWorldImporters

/*
1. Выберите сотрудников (Application.People), которые являются продажниками (IsSalesPerson), 
и не сделали ни одной продажи 04 июля 2015 года. 
Вывести ИД сотрудника и его полное имя. 
Продажи смотреть в таблице Sales.Invoices.
*/

TODO:
;with InvoicesCTE (SalespersonPersonID) as
	(
	select distinct I.SalespersonPersonID
	from Sales.Invoices as I
	where I.InvoiceDate in ('2015-07-04')
	)
SELECT P.PersonID, 
	   P.FullName
FROM Application.People as P
	left join InvoicesCTE on 
	P.PersonID = InvoicesCTE.SalespersonPersonID
	WHERE  IsSalesPerson = 1 AND InvoicesCTE.SalespersonPersonID IS NULL

GO

 SELECT P.PersonID, 
		P.FullName
FROM Application.People as P
	WHERE  IsSalesPerson = 1  AND PersonID NOT IN 
	(
	select distinct I.SalespersonPersonID
	from Sales.Invoices as I
	where I.InvoiceDate  in ('2015-07-04')
	)

	   	 
/*
2. Выберите товары с минимальной ценой (подзапросом). Сделайте два варианта подзапроса. 
Вывести: ИД товара, наименование товара, цена.
*/

TODO: 

select 
	WS.StockItemID,
	WS.StockItemName,
	Unitprice
from Warehouse.StockItems as WS
where Unitprice IN 
	(
	select min(WS.Unitprice) as MinPrice
	from Warehouse.StockItems as WS
	)

GO

;with CTE_1 (Unitprice) as
(
select min(WS.Unitprice) as MinPrice
from Warehouse.StockItems as WS
)
select	WS.StockItemID,
		WS.StockItemName,
		WS.Unitprice
from Warehouse.StockItems as WS
	right join CTE_1 on WS.Unitprice=CTE_1.Unitprice

/*
3. Выберите информацию по клиентам, которые перевели компании пять максимальных платежей 
из Sales.CustomerTransactions. 
Представьте несколько способов (в том числе с CTE). 
*/

TODO: 

;with Transactions_CTE (CustomerID, MAXAmount) as 
(
	select top 5
			CustomerID, 
			max(TransactionAmount) as MAXAmount
	from Sales.CustomerTransactions group by CustomerID order by MAXAmount desc
)
select * from Sales.Customers as C
	right join Transactions_CTE on
	C.CustomerID = Transactions_CTE.CustomerID

GO

select top 5
	CT.CustomerID,
	SC.CustomerName,
	max(CT.TransactionAmount) as MaxAm
from Sales.CustomerTransactions CT
	left join Sales.Customers SC
	on CT.CustomerID=SC.CustomerID
group by CT.CustomerID, SC.CustomerName
order by MaxAm Desc

/*
4. Выберите города (ид и название), в которые были доставлены товары, 
входящие в тройку самых дорогих товаров, а также имя сотрудника, 
который осуществлял упаковку заказов (PackedByPersonID).
*/

TODO: 
;with Top3PriceStockItemsCTE (UnitPrice, StockItemID) AS 
(
	select top 3 WS.UnitPrice,
			     WS.StockItemID 
	from Warehouse.StockItems as WS order by WS.UnitPrice desc
),
InvoiceLinesCTE AS
(
	SELECT DISTINCT InvoiceID FROM Sales.InvoiceLines WHERE StockItemID IN (SELECT StockItemID FROM Top3PriceStockItemsCTE)
)
SELECT DISTINCT AC.CityID, AC.CityName, AP.FullName FROM Sales.Invoices SI 
	JOIN Sales.Customers SC ON (SI.CustomerID = SC.CustomerID)
	JOIN Application.Cities AC ON (SC.DeliveryCityID = AC.CityID)
	JOIN Application.People AP ON (SI.PackedByPersonID = AP.PersonID)
WHERE SI.InvoiceID IN (SELECT InvoiceID FROM InvoiceLinesCTE)

go


;with Top3PriceStockItemsCTE (UnitPrice, StockItemID) AS 
(
	select top 3 WS.UnitPrice,
			     WS.StockItemID 
	from Warehouse.StockItems as WS order by WS.UnitPrice desc
)
select	DISTINCT 
		AC.CityName,
		AP.PersonID
from Sales.InvoiceLines as SIL
	right join Top3PriceStockItemsCTE on
		SIL.StockItemID = Top3PriceStockItemsCTE.StockItemID
	join Sales.Invoices as SI on
		SIL.InvoiceID = SI.InvoiceID
	join Sales.Customers as SC 
		on SI.CustomerID = SC.CustomerID
	join Application.Cities as AC on
		SC.PostalCityID = AC.CityID
	join Application.People as AP on
		SI.PackedByPersonID = AP.PersonID

-- ---------------------------------------------------------------------------
-- Опциональное задание
-- ---------------------------------------------------------------------------
-- Можно двигаться как в сторону улучшения читабельности запроса, 
-- так и в сторону упрощения плана\ускорения. 
-- Сравнить производительность запросов можно через SET STATISTICS IO, TIME ON. 
-- Если знакомы с планами запросов, то используйте их (тогда к решению также приложите планы). 
-- Напишите ваши рассуждения по поводу оптимизации. 

-- 5. Объясните, что делает и оптимизируйте запрос

SELECT 
	Invoices.InvoiceID, 
	Invoices.InvoiceDate,
	(SELECT People.FullName
		FROM Application.People
		WHERE People.PersonID = Invoices.SalespersonPersonID
	) AS SalesPersonName,
	SalesTotals.TotalSumm AS TotalSummByInvoice, 
	(SELECT SUM(OrderLines.PickedQuantity*OrderLines.UnitPrice)
		FROM Sales.OrderLines
		WHERE OrderLines.OrderId = (SELECT Orders.OrderId 
			FROM Sales.Orders
			WHERE Orders.PickingCompletedWhen IS NOT NULL	
				AND Orders.OrderId = Invoices.OrderId)	
	) AS TotalSummForPickedItems
FROM Sales.Invoices 
	JOIN
	(SELECT InvoiceId, SUM(Quantity*UnitPrice) AS TotalSumm
	FROM Sales.InvoiceLines
	GROUP BY InvoiceId
	HAVING SUM(Quantity*UnitPrice) > 27000) AS SalesTotals
		ON Invoices.InvoiceID = SalesTotals.InvoiceID
ORDER BY TotalSumm DESC

-- --

TODO: /*Вытаскиваем имя продавца из id как поле SalesPersonName, из OrderLines взяли как поле сумму заказа по id, поставили условие, что заказ должен быть со счетом и отдан покупателю, 
взяли новое поле TotalSummByInvoice из временной заново созданной запросом таблицы TotalSumm. В итоге получили таблицу, которая сравнивает по id заказа сумму товаров, 
переданных покупателю и сумму по счетам, сгруппированным по id заказа. Все - для  TotalSumm больше 27 тыс*/

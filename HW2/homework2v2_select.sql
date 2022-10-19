/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.
Занятие "02 - Оператор SELECT и простые фильтры, JOIN".

Задания выполняются с использованием базы данных WideWorldImporters.

Бэкап БД WideWorldImporters можно скачать отсюда:
https://github.com/Microsoft/sql-server-samples/releases/download/wide-world-importers-v1.0/WideWorldImporters-Full.bak

Описание WideWorldImporters от Microsoft:
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-what-is
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-oltp-database-catalog
*/

-- ---------------------------------------------------------------------------
-- Задание - написать выборки для получения указанных ниже данных.
-- ---------------------------------------------------------------------------

USE WideWorldImporters

/*
1. Все товары, в названии которых есть "urgent" или название начинается с "Animal".
Вывести: ИД товара (StockItemID), наименование товара (StockItemName).
Таблицы: Warehouse.StockItems.
*/

select StockItemID, StockItemName
from Warehouse.StockItems 
where [StockItemName] like '%urgent%' or [StockItemName] like 'Animal%'
order by StockItemID asc
/*
2. Поставщиков (Suppliers), у которых не было сделано ни одного заказа (PurchaseOrders).
Сделать через JOIN, с подзапросом задание принято не будет.
Вывести: ИД поставщика (SupplierID), наименование поставщика (SupplierName).
Таблицы: Purchasing.Suppliers, Purchasing.PurchaseOrders.
По каким колонкам делать JOIN подумайте самостоятельно.
*/

SELECT
	A.SupplierID,
	A.SupplierName
FROM Purchasing.Suppliers A
	LEFT JOIN Purchasing.PurchaseOrders B ON
	a.SupplierID=b.SupplierID
WHERE  B.SupplierID IS NULL


/*
3. Заказы (Orders) с ценой товара (UnitPrice) более 100$ 
либо количеством единиц (Quantity) товара более 20 штук
и присутствующей датой комплектации всего заказа (PickingCompletedWhen).
Вывести:
* OrderID
* дату заказа (OrderDate) в формате ДД.ММ.ГГГГ
* название месяца, в котором был сделан заказ
* номер квартала, в котором был сделан заказ
* треть года, к которой относится дата заказа (каждая треть по 4 месяца)
* имя заказчика (Customer)
Добавьте вариант этого запроса с постраничной выборкой,
пропустив первую 1000 и отобразив следующие 100 записей.

Сортировка должна быть по номеру квартала, трети года, дате заказа (везде по возрастанию).

Таблицы: Sales.Orders, Sales.OrderLines, Sales.Customers.
*/

select
	A.OrderID,
	B.OrderLineID,
	C.CustomerName,
	format(A.OrderDate, 'dd.MM.yyyy') as OrderDate_2,
	DATEPART(m, A.OrderDate) as OrderMonth, DATEPART(q, A.OrderDate) as OrderQuarter,
	CASE 
		WHEN MONTH(A.OrderDate)IN (1,2,3,4) THEN 1 
		WHEN MONTH(A.OrderDate) IN (5,6,7,8) THEN 2
		ELSE 3 END AS THIRD,
	B.UnitPrice,
	B.Quantity,
	format(B.PickingCompletedWhen, 'dd.MM.yyyy') as PickingCompletedWhen_2
	from Sales.Orders as A
left join Sales.OrderLines as B
	on A.OrderID = B.OrderID
left join Sales.Customers C
	on A.CustomerID = C.CustomerID
	where B.UnitPrice > 100 or B.Quantity > 20

order by OrderDate, OrderMonth, OrderQuarter asc
offset 1000 rows fetch first 100 rows only

/*
4. Заказы поставщикам (Purchasing.Suppliers),
которые должны быть исполнены (ExpectedDeliveryDate) в январе 2013 года
с доставкой "Air Freight" или "Refrigerated Air Freight" (DeliveryMethodName)
и которые исполнены (IsOrderFinalized).
Вывести:
* способ доставки (DeliveryMethodName)
* дата доставки (ExpectedDeliveryDate)
* имя поставщика
* имя контактного лица принимавшего заказ (ContactPerson)

Таблицы: Purchasing.Suppliers, Purchasing.PurchaseOrders, Application.DeliveryMethods, Application.People.
*/

 select 
	 A.PurchaseOrderID, 
	 D.SupplierName, 
	 A.ExpectedDeliveryDate, 
	 B.DeliveryMethodName,
	 C.FullName as ContactPerson
 from
	Purchasing.PurchaseOrders A
	
	LEFT JOIN 
		Application.DeliveryMethods as B 
		on A.DeliveryMethodID = B.DeliveryMethodID
	LEFT JOIN 
		Application.People as C 
		on A.ContactPersonID = C.PersonID
	LEFT JOIN 
		Purchasing.Suppliers D 
		on A.SupplierID = D.SupplierId
where	year(A.ExpectedDeliveryDate) = 2013 and 
		month(A.ExpectedDeliveryDate) = 1 and
		B.DeliveryMethodID in (8, 9) and 
		A.IsOrderFinalized = 1

/*
5. Десять последних продаж (по дате продажи) с именем клиента и именем сотрудника,
который оформил заказ (SalespersonPerson).
Сделать без подзапросов.
*/

SELECT TOP 10 
	A.OrderID,
	B.CustomerName,
	C.FullName as SalespersonPerson
FROM Sales.Orders A
	JOIN Sales.Customers B
	ON A.CustomerID = B.CustomerID
	JOIN Application.People C 
	ON A.SalespersonPersonID = C.PersonID
WHERE C.IsSalesperson=1
ORDER BY A.OrderDate DESC

/*
6. Все ид и имена клиентов и их контактные телефоны,
которые покупали товар "Chocolate frogs 250g".
Имя товара смотреть в таблице Warehouse.StockItems.
*/

select 
	A.CustomerID, 
	A.CustomerName,
	A.PhoneNumber, 
	C.StockItemName
from Sales.Customers A
	left join Warehouse.StockItemTransactions B
	ON A.CustomerID = B.CustomerID
	left join Warehouse.StockItems C ON B.StockItemID = C.StockItemID
where C.StockItemName like '%Chocolate frogs 250g%'


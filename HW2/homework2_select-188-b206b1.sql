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

select distinct s.SupplierID, s.SupplierName
from Purchasing.Suppliers as s
inner join (select distinct SupplierID from Purchasing.Suppliers
except
select distinct SupplierID from Purchasing.PurchaseOrders) as a
on s.SupplierID = a.SupplierID
order by SupplierID asc

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

select b.OrderID, c.CustomerName, format(b.OrderDate, 'dd.MM.yyyy') as OrderDate_2 , DATEPART(m, b.OrderDate) as OrderMonth, DATEPART(q, b.OrderDate) as OrderQuarter,CASE WHEN MONTH(b.OrderDate)IN (1,2,3,4) THEN 1 WHEN MONTH(b.OrderDate) IN (5,6,7,8) THEN 2 ELSE 3 END AS THIRD, b.AvgUnitPrice, b.SumQuantity, PickingCompletedWhen_2
from 
(
	select o.OrderID, o.customerID, o.OrderDate, month(o.OrderDate) as OrderMonth, a.AvgUnitPrice, a.SumQuantity, format(PickingCompletedWhen, 'dd.MM.yyyy') as PickingCompletedWhen_2
	from Sales.Orders as o
inner join 
	(select l.OrderID, avg(l.UnitPrice) as AvgUnitPrice , sum(l.Quantity) as SumQuantity
	from Sales.OrderLines as l
	group by OrderID) a
on o.OrderID = a.OrderID
) b
left join Sales.Customers c
on b.CustomerID = c.CustomerID
where b.AvgUnitPrice > 100 or b.SumQuantity > 20
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

 select PurchaseOrderID, SupplierName, ExpectedDeliveryDate , DeliveryMethodName, FullName as ContactPerson
 from
	 (select PurchaseOrderID, SupplierId, ExpectedDeliveryDate , DeliveryMethodName, FullName, IsOrderFinalized
		from (select a.PurchaseOrderID, a.SupplierId, a.ExpectedDeliveryDate , a.DeliveryMethodID, m.DeliveryMethodName, a.ContactPersonID, a.IsOrderFinalized
		from 
			(
			select p.PurchaseOrderID, p.SupplierId, p.ExpectedDeliveryDate , p.DeliveryMethodID, p.ContactPersonID, p.IsOrderFinalized
			from Purchasing.PurchaseOrders p
			where year(p.ExpectedDeliveryDate) = 2013 and month(p.ExpectedDeliveryDate) = 1
			and p.DeliveryMethodID in (8, 9) and p.IsOrderFinalized = 1
			) a
		LEFT JOIN Application.DeliveryMethods as m on a.DeliveryMethodID = m.DeliveryMethodID) b
	LEFT JOIN Application.People as ap on b.ContactPersonID = ap.PersonID) c
LEFT JOIN Purchasing.Suppliers ps on ps.SupplierID = c.SupplierId

/*
5. Десять последних продаж (по дате продажи) с именем клиента и именем сотрудника,
который оформил заказ (SalespersonPerson).
Сделать без подзапросов.
*/

SELECT TOP 10 A.OrderID, B.CustomerName, C.FullName as SalespersonPerson
FROM Sales.Orders A
JOIN Sales.Customers B ON A.CustomerID = B.CustomerID
JOIN Application.People C ON A.SalespersonPersonID = C.PersonID
WHERE C.IsSalesperson=1
ORDER BY A.OrderDate DESC

/*
6. Все ид и имена клиентов и их контактные телефоны,
которые покупали товар "Chocolate frogs 250g".
Имя товара смотреть в таблице Warehouse.StockItems.
*/

select A.CustomerID, A.CustomerName, A.PhoneNumber, C.StockItemName
from Sales.Customers A
left join Warehouse.StockItemTransactions B
ON A.CustomerID = B.CustomerID
left join Warehouse.StockItems C ON B.StockItemID = C.StockItemID
where C.StockItemName like '%Chocolate frogs 250g%'


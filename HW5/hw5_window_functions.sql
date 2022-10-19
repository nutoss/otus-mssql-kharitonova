/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "06 - Оконные функции".

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
-- ---------------------------------------------------------------------------

USE WideWorldImporters
/*
1. Сделать расчет суммы продаж нарастающим итогом по месяцам с 2015 года 
(в рамках одного месяца он будет одинаковый, нарастать будет в течение времени выборки).
Выведите: id продажи, название клиента, дату продажи, сумму продажи, сумму нарастающим итогом

Пример:
-------------+----------------------------
Дата продажи | Нарастающий итог по месяцу
-------------+----------------------------
 2015-01-29  | 4801725.31
 2015-01-30	 | 4801725.31
 2015-01-31	 | 4801725.31
 2015-02-01	 | 9626342.98
 2015-02-02	 | 9626342.98
 2015-02-03	 | 9626342.98
Продажи можно взять из таблицы Invoices.
Нарастающий итог должен быть без оконной функции.
*/
SET STATISTICS TIME  ON
SET STATISTICS io  ON
 
SELECT x.[OrderID], p.FullName, x.[InvoiceDate], 
             (SELECT sum(l.UnitPrice*l.[Quantity])
             FROM [Sales].[InvoiceLines] as l
             JOIN [Sales].[Invoices] as y on y.InvoiceID = l.InvoiceID
             WHERE format(y.[InvoiceDate], 'yyyyMM') <= format(x.[InvoiceDate], 'yyyyMM')
             and y.[InvoiceDate] >= '20150101'
             ) as total
from [Sales].[Invoices] as x
JOIN [Application].[People] as p on p.[PersonID] = x.[CustomerID]
WHERE x.[InvoiceDate] >= '20150101'
order by x.[InvoiceDate]

SET STATISTICS IO OFF; 
GO 
2 минуты 14 сек и 100% cost

/*
2. Сделайте расчет суммы нарастающим итогом в предыдущем запросе с помощью оконной функции.
   Сравните производительность запросов 1 и 2 с помощью set statistics time, io on
*/

/*простой вариант*/
SET STATISTICS TIME  ON
SET STATISTICS io  ON
 
SELECT
	inv.InvoiceID, 
	cust.CustomerName, 
	inv.InvoiceDate, 
	line.Quantity * line.UnitPrice as InvoiceSum,
	SUM(Quantity*UnitPrice) OVER(ORDER BY month(inv.InvoiceDate), year(inv.InvoiceDate))  as RunningTotal
FROM Sales.Invoices as inv
JOIN Sales.InvoiceLines as line on inv.InvoiceID=line.InvoiceID
JOIN Sales.Customers as cust ON inv.CustomerID=cust.CustomerID
WHERE inv.InvoiceDate >= '20150101'
ORDER BY InvoiceDate

SET STATISTICS IO OFF; 
GO 
2.2 секунды и 100% cost - так быстрее

/*или*/

select	*,
		sum(TransactionAmount) over (order by DRNK) as RunningTotalMonth
from(
	select  *, 
			Dense_Rank() OVER (order by Date_1) as DRNK
	from 
		(select 
			CT.CustomerTransactionID,
			(SELECT	Customers.CustomerName 
			FROM Sales.Customers
			WHERE Customers.CustomerID = CT.CustomerID
			) AS CustomerName,  
			format(CT.TransactionDate, 'MM.yyyy') as Date_1,
			CT.TransactionAmount,
			sum(TransactionAmount) over (order by CustomerTransactionID,TransactionAmount) as RunningTotalSort
		from Sales.CustomerTransactions as CT
		where Year(CT.TransactionDate)>=2015 and CT.InvoiceID is not null
	
		) as A
	) as B
order by CustomerTransactionID

/*
3. Вывести список 2х самых популярных продуктов (по количеству проданных) 
в каждом месяце за 2016 год (по 2 самых популярных продукта в каждом месяце).
*/
SELECT *
FROM 
	(
		select *, row_number() OVER (partition by MonthInv order by SumMonthQuQuantity desc) as RN
			from(
				select	LI.StockItemID,
						Sum(LI.Quantity) as SumMonthQuQuantity,
						Month(I.InvoiceDate) as MonthInv
				from Sales.InvoiceLines as LI
					Left join Sales.Invoices I on
					LI.InvoiceID = I.InvoiceID
				where Year(I.InvoiceDate) = 2016
				group by LI.StockItemID, Month(I.InvoiceDate)
				) as A
		) as B
		WHERE RN <= 2
Order By MonthInv

/*ИЛИ*/

select top 10 row_number() OVER (partition by MonthInv order by SumMonthQuQuantity desc) AS RN, *
	from(
		select	LI.StockItemID,
				Sum(LI.Quantity) as SumMonthQuQuantity,
				Month(I.InvoiceDate) as MonthInv
		from Sales.InvoiceLines as LI
			Left join Sales.Invoices I on
			LI.InvoiceID = I.InvoiceID
		where Year(I.InvoiceDate) = 2016
		group by LI.StockItemID, Month(I.InvoiceDate)
		) as A
Order By RN, SumMonthQuQuantity desc

/*
4. Функции одним запросом
Посчитайте по таблице товаров (в вывод также должен попасть ид товара, название, брэнд и цена):
* пронумеруйте записи по названию товара, так чтобы при изменении буквы алфавита нумерация начиналась заново
* посчитайте общее количество товаров и выведете полем в этом же запросе
* посчитайте общее количество товаров в зависимости от первой буквы названия товара
* отобразите следующий id товара исходя из того, что порядок отображения товаров по имени 
* предыдущий ид товара с тем же порядком отображения (по имени)
* названия товара 2 строки назад, в случае если предыдущей строки нет нужно вывести "No items"
* сформируйте 30 групп товаров по полю вес товара на 1 шт

Для этой задачи НЕ нужно писать аналог без аналитических функций.
*/

select
		WS.StockItemID, 
		WS.StockItemName, 
		WS.Brand,
		WS.UnitPrice ,
		LEFT(WS.StockItemName, 1)  as First_Leter_ItemName,
		rank() OVER (partition by LEFT(WS.StockItemName, 1) order by StockItemName) as Num,
		count(WS.StockItemID) over () as cnt_all,
		count(WS.StockItemID) over (partition by LEFT(WS.StockItemName, 1) ) as cnt_group,
		LEAD(StockItemID) OVER (ORDER BY StockItemName) AS NextItemID,
		LAG(StockItemID,1,0) OVER (ORDER BY StockItemName) AS PrevItemID , 
		LAG(StockItemName,2,'No items') OVER (ORDER BY StockItemName) AS PrevBack_2_ItemName,
		WS.TypicalWeightPerUnit,
		Ntile(30) over (ORDER BY WS.TypicalWeightPerUnit ) as NtileGr30
from Warehouse.StockItems as WS
order by StockItemName

/*
5. По каждому сотруднику выведите последнего клиента, которому сотрудник что-то продал.
   В результатах должны быть ид и фамилия сотрудника, ид и название клиента, дата продажи, сумму сделки.
*/

select top (1) with ties
			sum(IL.UnitPrice*IL.Quantity) as SumInv, 
			(SELECT People.FullName 
			FROM Application.People
			WHERE People.PersonID = I.SalespersonPersonID
			) AS SalesPersonName,
			(SELECT	Customers.CustomerName 
			FROM Sales.Customers
			WHERE Customers.CustomerID = I.CustomerID
			) AS CustomerName, 
			InvoiceDate,
ROW_NUMBER () over (partition by SalespersonPersonID order by InvoiceDate desc) as RN
from Sales.InvoiceLines as IL
	Left join Sales.Invoices as I on
	IL.InvoiceID = I.InvoiceID
	Group by SalespersonPersonID, CustomerID, InvoiceDate
	order by ROW_NUMBER () over (partition by SalespersonPersonID order by InvoiceDate desc) 

/*
6. Выберите по каждому клиенту два самых дорогих товара, которые он покупал.
В результатах должно быть ид клиета, его название, ид товара, цена, дата покупки.
*/

SELECT distinct *
FROM 
	(
	select I.CustomerID,
					(SELECT	Customers.CustomerName 
					FROM Sales.Customers
					WHERE Customers.CustomerID = I.CustomerID
					) AS CustomerName,	
					IL.StockItemID,
					IL.UnitPrice,
					I.InvoiceDate,
					Dense_Rank() OVER (PARTITION BY CustomerId ORDER BY UnitPrice DESC) AS DRNK
	From Sales.InvoiceLines as IL
		Left Join Sales.Invoices as I on 
	IL.InvoiceID = I.InvoiceID
	) AS tbl
	WHERE DRNK <= 2
ORDER BY CustomerId, UnitPrice DESC

/*Опционально можете для каждого запроса без оконных функций сделать вариант запросов с оконными функциями и сравнить их производительность. */
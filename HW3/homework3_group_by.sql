/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.
Занятие "02 - Оператор SELECT и простые фильтры, GROUP BY, HAVING".

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
1. Посчитать среднюю цену товара, общую сумму продажи по месяцам.
Вывести:
* Год продажи (например, 2015)
* Месяц продажи (например, 4)
* Средняя цена за месяц по всем товарам
* Общая сумма продаж за месяц

Продажи смотреть в таблице Sales.Invoices и связанных таблицах.
*/

select 
	Year(O.PickingCompletedWhen) as Y,
	Month(O.PickingCompletedWhen) as M,
	avg(L.Unitprice) as AvgPrice,
	sum(L.Unitprice * L.Quantity) as Volume
From Sales.Orders as O 
	left join Sales.Invoices as I on O.OrderID = i.OrderID
	left join Sales.InvoiceLines as L on I.InvoiceID = L.InvoiceID
Group by Month(O.PickingCompletedWhen), Year(O.PickingCompletedWhen)
having Year(O.PickingCompletedWhen) is not null
order by Y, M
/*
2. Отобразить все месяцы, где общая сумма продаж превысила 4 600 000

Вывести:
* Год продажи (например, 2015)
* Месяц продажи (например, 4)
* Общая сумма продаж

Продажи смотреть в таблице Sales.Invoices и связанных таблицах.
*/

select 
	Year(O.PickingCompletedWhen) as Y,
	Month(O.PickingCompletedWhen) as M,
	sum(L.Unitprice * L.Quantity) as Volume
From Sales.Orders as O 
	left join Sales.Invoices as I on O.OrderID = i.OrderID
	left join Sales.InvoiceLines as L on I.InvoiceID = L.InvoiceID
Group by Month(O.PickingCompletedWhen), Year(O.PickingCompletedWhen)
having sum(L.Unitprice * L.Quantity) > 4600000
order by Y, M
/*
3. Вывести сумму продаж, дату первой продажи
и количество проданного по месяцам, по товарам,
продажи которых менее 50 ед в месяц.
Группировка должна быть по году,  месяцу, товару.

Вывести:
* Год продажи
* Месяц продажи
* Наименование товара
* Сумма продаж
* Дата первой продажи
* Количество проданного

Продажи смотреть в таблице Sales.Invoices и связанных таблицах.
*/

select 
	S.StockItemName,
	Year(O.PickingCompletedWhen) as Y,
	Month(O.PickingCompletedWhen) as M,
	Min(format(O.PickingCompletedWhen, 'dd.MM.yyyy')) as FirstDate,
	avg(L.Unitprice) as AvgPrice,
	sum(L.Unitprice * L.Quantity) as Volume,
	sum(L.Quantity) as QuantitySum
From Sales.Orders as O 
	left join Sales.Invoices as I on O.OrderID = i.OrderID
	left join Sales.InvoiceLines as L on I.InvoiceID = L.InvoiceID
	left join Warehouse.StockItems as S on L.StockItemID = S.StockItemID
Group by S.StockItemName, Month(O.PickingCompletedWhen), Year(O.PickingCompletedWhen)
having sum(L.Quantity) > 50
order by Y, M

-- ---------------------------------------------------------------------------
-- Опционально
-- ---------------------------------------------------------------------------
/*
Написать запросы 2-3 так, чтобы если в каком-то месяце не было продаж,
то этот месяц также отображался бы в результатах, но там были нули.
*/

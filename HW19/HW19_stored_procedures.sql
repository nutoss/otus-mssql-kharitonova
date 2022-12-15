/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "12 - Хранимые процедуры, функции, триггеры, курсоры".

Задания выполняются с использованием базы данных WideWorldImporters.

Бэкап БД можно скачать отсюда:
https://github.com/Microsoft/sql-server-samples/releases/tag/wide-world-importers-v1.0
Нужен WideWorldImporters-Full.bak

Описание WideWorldImporters от Microsoft:
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-what-is
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-oltp-database-catalog
*/

USE WideWorldImporters;

/*
Во всех заданиях написать хранимую процедуру / функцию и продемонстрировать ее использование.
*/
GO
/*
1) Написать функцию возвращающую Клиента с наибольшей суммой покупки.
*/ -- ЗДЕСЬ НЕТ ВХОДЯЩЕГО ПАРАМЕТРА КРОМЕ САМИХ ДАННЫХ ТАБЛИЦЫ. ЗАДАВАТЬ ВХ ПАРАМЕТР НЕТ СМЫСЛА, ПОДХОДЯЩАЯ ДЛЯ ФУНКЦИИ ТАБЛИЦА ОДНА
CREATE OR ALTER FUNCTION CustomerMAXInvoiceSum () 
RETURNS nvarchar(100) 
as
BEGIN
DECLARE @CustomerMAXInvoiceSum nvarchar(100);
with CTE as  
	(
		select C.CustomerName, SUM(L.UnitPrice*L.Quantity) as [InvoiceSum]
		from Sales.Invoices I
		left join Sales.InvoiceLines L on I.InvoiceID = L.InvoiceID
		left join Sales.Customers C on I.CustomerID = C.CustomerID
		group by C.CustomerName
	
	)
select @CustomerMAXInvoiceSum=CustomerName --, InvoiceSum 
from CTE 
where  CTE.InvoiceSum = (select MAX(CTE.InvoiceSum) from CTE )
Group by CustomerName 
RETURN @CustomerMAXInvoiceSum
END
GO
--Вызов для теста
SELECT [dbo].CustomerMAXInvoiceSum ()
GO
/*
2) Написать хранимую процедуру с входящим параметром СustomerID, выводящую сумму покупки по этому клиенту.
Использовать таблицы :
Sales.Customers
Sales.Invoices
Sales.InvoiceLines
*/

CREATE OR ALTER PROCEDURE InvoiceSum_Of_CustomerID (@CustomerID int)
as BEGIN

	with CTE as  
	(
		select C.CustomerID, SUM(L.UnitPrice*L.Quantity) as [InvoiceSum]
		from Sales.Invoices I
		left join Sales.InvoiceLines L on I.InvoiceID = L.InvoiceID
		left join Sales.Customers C on I.CustomerID = C.CustomerID
		group by C.CustomerID
	
	)
select SUM(InvoiceSum) as InvoiceSum
from CTE 
where  CustomerID = @CustomerID
Group by CustomerID 
ORDER BY CustomerID
END
GO
--Вызов для теста
BEGIN
EXEC InvoiceSum_Of_CustomerID @CustomerID = 10
END
GO
/*
3) Создать одинаковую функцию и хранимую процедуру, посмотреть в чем разница в производительности и почему.
*/

--DROP FUNCTION IF EXISTS FUNC_TEST_1
CREATE OR ALTER FUNCTION FUNC_TEST_1 (@CustomerID int) 
RETURNS decimal(18,2) 
	with RETURNS NULL ON NULL INPUT
as
BEGIN
DECLARE @CustomerIDInvoiceSum nvarchar(100);

with CTE as  
	(
		select C.CustomerID, SUM(L.UnitPrice*L.Quantity) as [InvoiceSum]
		from Sales.Invoices I
		left join Sales.InvoiceLines L on I.InvoiceID = L.InvoiceID
		left join Sales.Customers C on I.CustomerID = C.CustomerID
		group by C.CustomerID
	
	)
select @CustomerIDInvoiceSum = SUM(InvoiceSum)
from CTE 
where  CustomerID = @CustomerID
Group by CustomerID 
ORDER BY CustomerID
RETURN @CustomerIDInvoiceSum

END


GO

--DROP PROCEDURE IF EXISTS PROC_TEST_1
CREATE OR ALTER PROCEDURE PROC_TEST_1 (@CustomerID int)
as BEGIN

	with CTE as  
	(
		select C.CustomerID, SUM(L.UnitPrice*L.Quantity) as [InvoiceSum]
		from Sales.Invoices I
		left join Sales.InvoiceLines L on I.InvoiceID = L.InvoiceID
		left join Sales.Customers C on I.CustomerID = C.CustomerID
		group by C.CustomerID
	
	)
select SUM(InvoiceSum) as InvoiceSum
from CTE 
where  CustomerID = @CustomerID
Group by CustomerID 
ORDER BY CustomerID
END
GO
set statistics time on

--Вызов для теста

SELECT [dbo].FUNC_TEST_1 (10)
/*
(1 row affected)

 Время работы SQL Server:
   Время ЦП = 16 мс, затраченное время = 42 мс.
Время синтаксического анализа и компиляции SQL Server: 
 время ЦП = 12 мс, истекшее время = 12 мс.
*/

--Вызов для теста
BEGIN
EXEC PROC_TEST_1 @CustomerID = 10
END

set statistics time Off
GO

/*
1 row affected)

 Время работы SQL Server:
   Время ЦП = 0 мс, затраченное время = 3 мс.

 Время работы SQL Server:
   Время ЦП = 16 мс, затраченное время = 15 мс.
*/ 

--Сравнение: во 2 случае используются индексы, кол-во возвращаемых строк одинаковое, Query cost разное, нет информации о запросе внутри функции

/*
4) Создайте табличную функцию покажите как ее можно вызвать для каждой строки result set'а без использования цикла. 
*/

GO
CREATE OR ALTER PROCEDURE FOR_RESSET
AS
 
select CAST(CustomerID as nvarchar(100)) + CustomerNAME
FROM Sales.Customers
ORDER BY CustomerID
;
with CTE as  
	(
		select C.CustomerID, SUM(L.UnitPrice*L.Quantity) as [InvoiceSum]
		from Sales.Invoices I
		left join Sales.InvoiceLines L on I.InvoiceID = L.InvoiceID
		left join Sales.Customers C on I.CustomerID = C.CustomerID
		group by C.CustomerID
	
	)
select CustomerID, SUM(InvoiceSum) as InvoiceSum
from CTE 
Group by CustomerID 
ORDER BY CustomerID
RETURN
GO


EXEC FOR_RESSET 
WITH RESULT SETS 
(
	([ID+CustomerName] nvarchar(100)
	),
	([ID] int, [Sum per Customer] decimal(18,2) 
	)
)
GO

/*
5) Опционально. Во всех процедурах укажите какой уровень изоляции транзакций вы бы использовали и почему. 
*/

/*Для CustomerMAXInvoiceSum и InvoiceSum_Of_CustomerID READ COMMITTED SNAPSHOT (для FUNC_TEST_1 и PROC_TEST_1 аналогично), 
чтобы при выполнении нескольких запросов внутри функции не возникло ошибки и несогласованности, 
например если какой-то клиент завершит покупку в моменте или может быть в процессе транзакции покупки непонятно на каком моменте

Для FOR_RESSET REPEATABLE READ, чтобы не допустить появление какого-то нового клиента с новыми покупками, которые мы не сможем соотнести между запросами.
*/

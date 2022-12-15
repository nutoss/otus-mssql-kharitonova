/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "10 - Операторы изменения данных".

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
1. Довставлять в базу пять записей используя insert в таблицу Customers или Suppliers 

*/

declare @CustomerID INT,
		@CustomerName varchar(MAX),
		@BillToCustomerId INT,
		@PrimaryContactPersonID INT,
		@DeliveryCityID INT,
		@PostalCityID INT,
		@AccountOpenedDate DATE,
		@DeliveryPostalCode INT,
		@PostalPostalCode INT,
		@LastEditedBy INT
		;
set @CustomerID = NEXT VALUE FOR Sequences.CustomerID
set @CustomerName = 'NEWCustomerName_1'
set @BillToCustomerId = @CustomerID

Select  @PrimaryContactPersonID =  PrimaryContactPersonID/*+1*/ from Sales.Customers as C
where C.CustomerID = (select MAX(C1.CustomerID) from Sales.Customers as C1)

set @DeliveryCityID = 29158
set @PostalCityID = @DeliveryCityID
set @AccountOpenedDate = GETDATE()
set @DeliveryPostalCode = 90760
set @PostalPostalCode = @DeliveryPostalCode
set @LastEditedBy = 1

DECLARE @I INT = 2

WHILE @I < 6
BEGIN

set @CustomerID = NEXT VALUE FOR Sequences.CustomerID
set @CustomerName = 'NEWCustomerName_' + CONVERT(varchar(max),@I)
set @BillToCustomerId = @CustomerID

--SELECT @CustomerID

insert into Sales.Customers 
           ([CustomerID]
           ,[CustomerName]
           ,[BillToCustomerID]
           ,[CustomerCategoryID]
           ,[BuyingGroupID]
           ,[PrimaryContactPersonID]
           ,[AlternateContactPersonID]
           ,[DeliveryMethodID]
           ,[DeliveryCityID]
           ,[PostalCityID]
           ,[CreditLimit]
           ,[AccountOpenedDate]
           ,[StandardDiscountPercentage]
           ,[IsStatementSent]
           ,[IsOnCreditHold]
           ,[PaymentDays]
           ,[PhoneNumber]
           ,[FaxNumber]
           ,[DeliveryRun]
           ,[RunPosition]
           ,[WebsiteURL]
           ,[DeliveryAddressLine1]
           ,[DeliveryAddressLine2]
           ,[DeliveryPostalCode]
           ,[DeliveryLocation]
           ,[PostalAddressLine1]
           ,[PostalAddressLine2]
           ,[PostalPostalCode]
           ,[LastEditedBy])
OUTPUT inserted.* 

 VALUES
           (@CustomerID
           ,@CustomerName
           ,@BillToCustomerId
           ,1
           ,1
           ,@PrimaryContactPersonID
           ,NULL
           ,3
           ,@DeliveryCityID
           ,@PostalCityID
           ,5000
           ,@AccountOpenedDate
           ,0.00
           ,0
           ,0
           ,7
           ,'(206) 555-0100'
           ,'(206) 555-0101'
           ,NULL
           ,NULL
           ,'http://www.microsoft.com/'
           ,'Shop 55'
           ,'655 Victoria Lane'
           ,@DeliveryPostalCode
           ,0xE6100000010C11154FE2182D4740159ADA087A035FC0
           ,'PO Box 811'
           ,'Milicaville'
           ,@PostalPostalCode
           ,@LastEditedBy
		   )
		   SET @I = @I + 1
END
GO

/*
2. Удалите одну запись из Customers, которая была вами добавлена
*/

delete FROM Sales.Customers where [CustomerName] = 'NEWCustomerName_5'


/*
3. Изменить одну запись, из добавленных через UPDATE
*/

Update Sales.Customers
set [CreditLimit] = 4999 where [CustomerName] = 'NEWCustomerName_4'

/*
4. Написать MERGE, который вставит вставит запись в клиенты, если ее там нет, и изменит если она уже есть
*/

MERGE 
Sales.Customers as trg
using (select * FROM Sales.Customers where [CustomerName] like 'NEWCustomerName_1') as src 
on trg.CustomerName = src.CustomerName
WHEN MATCHED THEN 
UPDATE SET trg.CustomerName = 'NEWCustomerName_101'
WHEN NOT MATCHED THEN 
INSERT (	[CustomerID]
           ,[CustomerName]
           ,[BillToCustomerID]
           ,[CustomerCategoryID]
           ,[BuyingGroupID]
           ,[PrimaryContactPersonID]
           ,[AlternateContactPersonID]
           ,[DeliveryMethodID]
           ,[DeliveryCityID]
           ,[PostalCityID]
           ,[CreditLimit]
           ,[AccountOpenedDate]
           ,[StandardDiscountPercentage]
           ,[IsStatementSent]
           ,[IsOnCreditHold]
           ,[PaymentDays]
           ,[PhoneNumber]
           ,[FaxNumber]
           ,[DeliveryRun]
           ,[RunPosition]
           ,[WebsiteURL]
           ,[DeliveryAddressLine1]
           ,[DeliveryAddressLine2]
           ,[DeliveryPostalCode]
           ,[DeliveryLocation]
           ,[PostalAddressLine1]
           ,[PostalAddressLine2]
           ,[PostalPostalCode]
           ,[LastEditedBy])

VALUES (	src.[CustomerID]
           ,'NEWCustomerName_101'
           ,src.[BillToCustomerID]
           ,src.[CustomerCategoryID]
           ,src.[BuyingGroupID]
           ,src.[PrimaryContactPersonID]
           ,src.[AlternateContactPersonID]
           ,src.[DeliveryMethodID]
           ,src.[DeliveryCityID]
           ,src.[PostalCityID]
           ,src.[CreditLimit]
           ,src.[AccountOpenedDate]
           ,src.[StandardDiscountPercentage]
           ,src.[IsStatementSent]
           ,src.[IsOnCreditHold]
           ,src.[PaymentDays]
           ,src.[PhoneNumber]
           ,src.[FaxNumber]
           ,src.[DeliveryRun]
           ,src.[RunPosition]
           ,src.[WebsiteURL]
           ,src.[DeliveryAddressLine1]
           ,src.[DeliveryAddressLine2]
           ,src.[DeliveryPostalCode]
           ,src.[DeliveryLocation]
           ,src.[PostalAddressLine1]
           ,src.[PostalAddressLine2]
           ,src.[PostalPostalCode]
           ,src.[LastEditedBy]);


/*
5. Напишите запрос, который выгрузит данные через bcp out и загрузить через bulk insert
*/

----Подготовительные мероприятия (SERVERNAME заменен на свякий случай, но код работает)
EXEC sp_configure 'show advanced options', 1;  
GO  
-- To update the currently configured value for advanced options.  
RECONFIGURE;  
GO  
-- To enable the feature.  
EXEC sp_configure 'xp_cmdshell', 1;  
GO  
-- To update the currently configured value for this feature.  
RECONFIGURE;  
GO  

SELECT @@SERVERNAME

----Делаем bcp out 
drop table if exists [dbo].[Sales_FORHW8]

select S.sales_id, S.customer_id, S.item_id 
into Sales_FORHW8 
FROM Sales S 

exec master..xp_cmdshell 'bcp "[WideWorldImporters].dbo.Sales_FORHW8" out  "C:\Intel\Sales_FORHW8.txt" -T -w -t$$$ -S MYSERVER1\SQL2017'

----Делаем простенький bulk insert без первычных ключей

drop table if exists [dbo].[Sales_FORHW8]

CREATE TABLE [dbo].[Sales_FORHW8](
	[sales_id] [int] NOT NULL,
	[customer_id] [int] NOT NULL,
	[item_id] [int] NOT NULL)
	
GO
	BULK INSERT [dbo].[Sales_FORHW8]
				   FROM "C:\Intel\Sales_FORHW8.txt"
				   WITH 
					 (
						BATCHSIZE = 1000, 
						DATAFILETYPE = 'widechar',
						FIELDTERMINATOR = '$$$',
						ROWTERMINATOR ='\n',
						KEEPNULLS,
						TABLOCK        
					  );
----Проверяем результат - работает
select * 
FROM Sales_FORHW8 
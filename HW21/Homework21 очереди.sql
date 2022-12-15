/*
1. �������� ������� ��� ������������ ������� ��� �������� �� ������� Invoices. ��� ������ ��������� ��� �������� ������ � ������� ������ ������������ ������.
2. ��� ��������� ������� ���������� ����� �� ���������� ������� (Orders) �� ������� �� �������� ������ ������� � ����������� ������� ����� � ����� �������.
3. ���������, ��� �� ��������� ���������� � ���������� ������� � � ��� ��� �� �������.
*/



/*
������� ������ ��� �������� ���������. ����� ��������� ��������� ������, ��������� ��������� Service Broker �������� ��� � �������, ��������� �� �������.
*/

--����� �������� WideWorldImporters Options �������� Sevice Broker

USE master
ALTER DATABASE WideWorldImporters
SET ENABLE_BROKER WITH ROLLBACK IMMEDIATE; 

ALTER DATABASE WideWorldImporters SET TRUSTWORTHY ON;

ALTER AUTHORIZATION    
   ON DATABASE::WideWorldImporters TO [sa]; -- ����������� ������������ ������ ���� [sa]

GO
-------�������� ��� ���� ��������� ���� XML ��� ������� � ������
GO
--------Create Message Types for Request and Reply messages
USE WideWorldImporters
-- For Request
CREATE MESSAGE TYPE
[//WWI/SB_HW/Application]
VALIDATION=WELL_FORMED_XML;
GO
-- For Reply
CREATE MESSAGE TYPE
[//WWI/SB_HW/ReplyAppl]
VALIDATION=WELL_FORMED_XML; 
-------�������� ��������
GO
CREATE CONTRACT [//WWISB_HW/Contract_HW]
      ([//WWI/SB_HW/Application]
         SENT BY INITIATOR,
       [//WWI/SB_HW/ReplyAppl]
         SENT BY TARGET
      );
GO
-------������� ��� ���� ��������� ���� XML ��� ������� � ������----------------------------
GO
-------������� 2 ������� � 2 ������� (����������� � ����������)
GO
CREATE QUEUE TargetQueue_HW;

CREATE SERVICE [//WWI/SB/TargetService_HW]
       ON QUEUE TargetQueue_HW
       ([//WWISB_HW/Contract_HW]);
GO

CREATE QUEUE InitiatorQueue_HW;

CREATE SERVICE [//WWI/SB/InitiatorService_HW]
       ON QUEUE InitiatorQueue_HW
       ([//WWISB_HW/Contract_HW]);
GO
-------������� ��� �������: ����� �������: Sevice Broker - Servises � Queues---------------------

-----------------������� ������� ��� ������ (1 ���)
SELECT [CustomerID], count([OrderID]) as CountOrdersByCustomer, GETDATE() as DateOfREP
				into dbo.REPTABLE_HW		
					FROM Sales.Invoices
							WHERE [CustomerID] = 1
							GROUP BY [CustomerID]
		--select * from REPTABLE_HW
	--DROP TABLE IF exists  REPTABLE_HW 
Truncate table REPTABLE_HW

---------------------
GO
-------������� ��������� �������� ��������� ��� ������ �������
GO
CREATE or ALTER PROCEDURE Sales.SendNewApplicationForRep -
	@CustomerID INT 
AS
BEGIN
	SET NOCOUNT ON;

    --Sending a Request Message to the Target	
	DECLARE @InitDlgHandle UNIQUEIDENTIFIER;  --��� - ������������� �������
	DECLARE @RequestMessage NVARCHAR(4000);
	
	BEGIN TRAN 

	--Prepare the Message
	SELECT @RequestMessage = (SELECT N'������� ���-�� ������� �� ����' as Mess, [CustomerID]
							FROM Sales.Invoices as Inv
							WHERE [CustomerID] = @CustomerID
							GROUP BY [CustomerID]
							FOR XML AUTO, root('RequestMessage')); 
	
	--Determine the Initiator Service, Target Service and the Contract 
	BEGIN DIALOG @InitDlgHandle
	FROM SERVICE
	[//WWI/SB/InitiatorService_HW]
	TO SERVICE
	'//WWI/SB/TargetService_HW'
	ON CONTRACT
	[//WWISB_HW/Contract_HW]
	WITH ENCRYPTION=OFF; 

	--Send the Message
	SEND ON CONVERSATION @InitDlgHandle 
	MESSAGE TYPE
	[//WWI/SB_HW/Application]
	(@RequestMessage);
	SELECT @RequestMessage AS SentRequestMessage; --SELECT ��� �������
	COMMIT TRAN 
END
GO
-------��������� �������-------------------------------------------------
GO
-------���������, ������� �������� � ����� �������:2  (SELECT �������� ��� �������, ����� ����� ������, ����� �� �������� log)
GO
-------���������, ������� ����������� �� ������ ����������. � ��� ��������� ������ �� ���������� (END CONVERSATION)
GO
CREATE or ALTER PROCEDURE Sales.GetNewCustomerID
AS
BEGIN

	DECLARE @TargetDlgHandle UNIQUEIDENTIFIER,
			@Message NVARCHAR(4000),
			@MessageType Sysname,
			@ReplyMessage NVARCHAR(4000),
			@ReplyMessageName Sysname,
			@CustomerID INT,
			@xml XML; 
	
	BEGIN TRAN; 
	
	--Receive message from Initiator
	RECEIVE TOP(1)
		@TargetDlgHandle = Conversation_Handle,
		@Message = Message_Body,
		@MessageType = Message_Type_Name
	FROM dbo.TargetQueue_HW; 

	SELECT @Message as RecievedMessage ; --SELECT ��� �������

	SET @xml = CAST(@Message AS XML);

	SELECT @CustomerID = R.Iv.value('@CustomerID[1]','INT')
	FROM @xml.nodes('/RequestMessage/Inv') as R(Iv);
	
	IF EXISTS (SELECT * FROM Sales.Invoices WHERE CustomerID = @CustomerID)
	BEGIN
	insert into REPTABLE_HW 
				SELECT 	[CustomerID], count([OrderID]) as CountOrdersByCustomer, GETDATE() as DateOfREP
							FROM Sales.Invoices
							WHERE [CustomerID] = @CustomerID
							GROUP BY [CustomerID]
			
	END;
	
	SELECT * From REPTABLE_HW; 
	
	-- Confirm and Send a reply
	IF @MessageType= N'//WWI/SB_HW/Application'
	BEGIN
		SET @ReplyMessage =N'<ReplyMessage> Message received, Report row generated in REPTABLE_HW</ReplyMessage>'; 
	
		SEND ON CONVERSATION @TargetDlgHandle
		MESSAGE TYPE
		[//WWI/SB_HW/ReplyAppl]
		(@ReplyMessage);
		END CONVERSATION @TargetDlgHandle;
	END 
	
	SELECT @ReplyMessage AS SentReplyMessage; --SELECT ��� �������

	COMMIT TRAN;
END

-------��������� �������-------------------------------------------------
GO
-------���������, ������� ����������� �� ������ �����������. � ��� ��������� ������ �� ����������� (END CONVERSATION)
GO
CREATE or ALTER PROCEDURE Sales.ConfirmRep
AS
BEGIN
	--Receiving Reply Message from the Target.	
	DECLARE @InitiatorReplyDlgHandle UNIQUEIDENTIFIER,
			@ReplyReceivedMessage NVARCHAR(1000) 
	
	BEGIN TRAN; 

		RECEIVE TOP(1)
			@InitiatorReplyDlgHandle=Conversation_Handle
			,@ReplyReceivedMessage=Message_Body
		FROM dbo.InitiatorQueue_HW; 
		
		END CONVERSATION @InitiatorReplyDlgHandle; 
		
		SELECT @ReplyReceivedMessage AS ReceivedRepliedMessage; --SELECT ��� �������

	COMMIT TRAN; 
END
-------��������� �������-------------------------------------------------
GO
--------------��������� �������
USE [WideWorldImporters]
GO
/****** Object:  ServiceQueue [InitiatorQueueWWI]    Script Date: 6/5/2019 11:57:47 PM ******/
ALTER QUEUE [dbo].[InitiatorQueueWWI] WITH STATUS = ON , RETENTION = OFF , POISON_MESSAGE_HANDLING (STATUS = OFF) 
	, ACTIVATION (   STATUS = OFF ,
        PROCEDURE_NAME = Sales.ConfirmInvoice, MAX_QUEUE_READERS = 1, EXECUTE AS OWNER) ; 

GO
ALTER QUEUE [dbo].[TargetQueueWWI] WITH STATUS = ON , RETENTION = OFF , POISON_MESSAGE_HANDLING (STATUS = OFF)
	, ACTIVATION (  STATUS = OFF ,
        PROCEDURE_NAME = Sales.GetNewInvoice, MAX_QUEUE_READERS = 1, EXECUTE AS OWNER) ; 

GO

-------------ACTIVATION (   STATUS = ON ��� OFF ������ �� ���������

------�� ������ ���� ��� ������� ALTER DATABASE [WideWorldImporters] SET NEW_BROKER WITH ROLLBACK IMMEDIATE;

------------------------------------------------------------------------------------------------------------------------------------

--�������� �������-------------------------------------------------------------

USE [WideWorldImporters];
--Send message
EXEC Sales.SendNewApplicationForRep
	@CustomerID = 11;

SELECT CAST(message_body AS XML),*
FROM dbo.TargetQueue_HW;

SELECT CAST(message_body AS XML),*
FROM dbo.InitiatorQueue_HW;

--Target
EXEC Sales.GetNewCustomerID


--Initiator
EXEC Sales.ConfirmRep;


--�������� ������-------------------------------------------------------------

SELECT * From REPTABLE_HW

----------------------------------------------------------
SELECT * FROM sys.service_contract_message_usages; 
SELECT * FROM sys.service_contract_usages;
SELECT * FROM sys.service_queue_usages;
 
SELECT * FROM sys.transmission_queue;

SELECT * 
FROM dbo.InitiatorQueue_HW;

SELECT * 
FROM dbo.TargetQueue_HW;

select name, is_broker_enabled
from sys.databases;

SELECT conversation_handle, is_initiator, s.name as 'local service', 
far_service, sc.name 'contract', ce.state_desc
FROM sys.conversation_endpoints ce
LEFT JOIN sys.services s
ON ce.service_id = s.service_id
LEFT JOIN sys.service_contracts sc
ON ce.service_contract_id = sc.service_contract_id
ORDER BY conversation_handle;


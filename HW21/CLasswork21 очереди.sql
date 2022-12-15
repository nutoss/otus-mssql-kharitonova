/*1. �������� ������� ��� ������������ ������� ��� �������� �� ������� Invoices. ��� ������ ��������� ��� �������� ������ � ������� ������ ������������ ������.
2. ��� ��������� ������� ���������� ����� �� ���������� ������� (Orders) �� ������� �� �������� ������ ������� � ����������� ������� ����� � ����� �������.
3. ���������, ��� �� ��������� ���������� � ���������� ������� � � ��� ��� �� �������.*/

/*������� ������ ��� �������� ���������. ����� ��������� ��������� ������, ��������� ��������� Service Broker �������� ��� � �������, ��������� �� �������.*/


--����� �������� WideWorldImporters Options �������� Sevice Broker
GO
ALTER TABLE Sales.Invoices
ADD InvoiceConfirmedForProcessing DATETIME;


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
[//WWI/SB/RequestMessage]
VALIDATION=WELL_FORMED_XML;
GO
-- For Reply
CREATE MESSAGE TYPE
[//WWI/SB/ReplyMessage]
VALIDATION=WELL_FORMED_XML; 
-------�������� �������
GO
CREATE CONTRACT [//WWI/SB/Contract]
      ([//WWI/SB/RequestMessage]
         SENT BY INITIATOR,
       [//WWI/SB/ReplyMessage]
         SENT BY TARGET
      );
GO
-------������� ��� ���� ��������� ���� XML ��� ������� � ������----------------------------
GO
-------������� 2 ������� � 2 ������� (����������� � ����������)
GO
CREATE QUEUE TargetQueueWWI;

CREATE SERVICE [//WWI/SB/TargetService]
       ON QUEUE TargetQueueWWI
       ([//WWI/SB/Contract]);
GO

CREATE QUEUE InitiatorQueueWWI;

CREATE SERVICE [//WWI/SB/InitiatorService]
       ON QUEUE InitiatorQueueWWI
       ([//WWI/SB/Contract]);
GO
-------������� ��� �������: ����� �������: Sevice Broker - Servises---------------------
GO
-------������� ��������� �������� ��������� ��� ������ �������
GO
CREATE or ALTER PROCEDURE Sales.SendNewInvoice
	@invoiceId INT
AS
BEGIN
	SET NOCOUNT ON;

    --Sending a Request Message to the Target	
	DECLARE @InitDlgHandle UNIQUEIDENTIFIER;  --��� - ������������� �������
	DECLARE @RequestMessage NVARCHAR(4000);
	
	BEGIN TRAN 

	--Prepare the Message
	SELECT @RequestMessage = (SELECT InvoiceID
							  FROM Sales.Invoices AS Inv
							  WHERE InvoiceID = @invoiceId
							  FOR XML AUTO, root('RequestMessage')); 
	
	--Determine the Initiator Service, Target Service and the Contract 
	BEGIN DIALOG @InitDlgHandle
	FROM SERVICE
	[//WWI/SB/InitiatorService]
	TO SERVICE
	'//WWI/SB/TargetService'
	ON CONTRACT
	[//WWI/SB/Contract]
	WITH ENCRYPTION=OFF; 

	--Send the Message
	SEND ON CONVERSATION @InitDlgHandle 
	MESSAGE TYPE
	[//WWI/SB/RequestMessage]
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
CREATE or ALTER PROCEDURE Sales.GetNewInvoice
AS
BEGIN

	DECLARE @TargetDlgHandle UNIQUEIDENTIFIER,
			@Message NVARCHAR(4000),
			@MessageType Sysname,
			@ReplyMessage NVARCHAR(4000),
			@ReplyMessageName Sysname,
			@InvoiceID INT,
			@xml XML; 
	
	BEGIN TRAN; 

	--Receive message from Initiator
	RECEIVE TOP(1)
		@TargetDlgHandle = Conversation_Handle,
		@Message = Message_Body,
		@MessageType = Message_Type_Name
	FROM dbo.TargetQueueWWI; 

	SELECT @Message; --SELECT ��� �������

	SET @xml = CAST(@Message AS XML);

	SELECT @InvoiceID = R.Iv.value('@InvoiceID','INT')
	FROM @xml.nodes('/RequestMessage/Inv') as R(Iv);

	IF EXISTS (SELECT * FROM Sales.Invoices WHERE InvoiceID = @InvoiceID)
	BEGIN
		UPDATE Sales.Invoices
		SET InvoiceConfirmedForProcessing = GETUTCDATE()
		WHERE InvoiceId = @InvoiceID;
	END;
	
	SELECT @Message AS ReceivedRequestMessage, @MessageType; 
	
	-- Confirm and Send a reply
	IF @MessageType=N'//WWI/SB/RequestMessage'
	BEGIN
		SET @ReplyMessage =N'<ReplyMessage> Message received</ReplyMessage>'; 
	
		SEND ON CONVERSATION @TargetDlgHandle
		MESSAGE TYPE
		[//WWI/SB/ReplyMessage]
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
CREATE or ALTER PROCEDURE Sales.ConfirmInvoice
AS
BEGIN
	--Receiving Reply Message from the Target.	
	DECLARE @InitiatorReplyDlgHandle UNIQUEIDENTIFIER,
			@ReplyReceivedMessage NVARCHAR(1000) 
	
	BEGIN TRAN; 

		RECEIVE TOP(1)
			@InitiatorReplyDlgHandle=Conversation_Handle
			,@ReplyReceivedMessage=Message_Body
		FROM dbo.InitiatorQueueWWI; 
		
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
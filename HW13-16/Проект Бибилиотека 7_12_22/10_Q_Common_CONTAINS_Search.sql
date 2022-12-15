USE [Project_Library]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [dbo].[Q_Common_CONTAINS_Search] (@Author    nvarchar(4000), @Book      nvarchar(4000), @Publisher nvarchar(4000))
RETURNS @RETURN_TABLE TABLE( [id_book] int
							,[Book_name] nvarchar(50)
							,[Authors_Full_all] nvarchar(4000)
							,[Publisher_name] nvarchar(50)
							,[Year_published] int
							,[Availabe_Books_Quantity] int
							)
as BEGIN						

set  @Author	= N'FORMSOF(INFLECTIONAL, N"Пушкина")'
set  @Book		= N'FORMSOF(INFLECTIONAL, N"капитанский")'
set  @Publisher	= N'FORMSOF(INFLECTIONAL, N"феникс")'

insert into @RETURN_TABLE

SELECT [id_book], [Book_name], [Authors_Full_all], [Publisher_name], [Year_published], [Availabe_Books_Quantity]
FROM Available_Books_Search 
WHERE CONTAINS (Authors_Full_all, @Author) 

UNION 

SELECT [id_book], [Book_name], [Authors_Full_all], [Publisher_name], [Year_published], [Availabe_Books_Quantity]
FROM Available_Books_Search 
WHERE CONTAINS (Book_name, @Book)  

UNION 

SELECT [id_book], [Book_name], [Authors_Full_all], [Publisher_name], [Year_published], [Availabe_Books_Quantity]
FROM Available_Books_Search 
WHERE CONTAINS (Publisher_name, @Publisher)  

RETURN

end



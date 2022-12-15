USE [Project_Library]
GO

/****** Object:  UserDefinedFunction [dbo].[Q_Common_CONTAINS_Search]    Script Date: 07.12.2022 13:27:01 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


ALTER FUNCTION [dbo].[Q_Common_CONTAINS_Search] (@Author nvarchar(4000), @Book nvarchar(4000), @Publisher nvarchar(4000))
RETURNS @RETURN_TABLE TABLE( [id_book] int
							,[Book_name] nvarchar(50)
							,[Authors_Full_all] nvarchar(4000)
							,[Publisher_name] nvarchar(50)
							,[Year_published] int
							,[Availabe_Books_Quantity] int
							)
as BEGIN

DECLARE @Author_1    nvarchar(4000)  = CONVERT(nvarchar(4000), N'FORMSOF(INFLECTIONAL,"'+@Author+'")')
DECLARE @Book_1      nvarchar(4000)  = CONVERT(nvarchar(4000), N'FORMSOF(INFLECTIONAL,"'+@Book+'")')
DECLARE @Publisher_1 nvarchar(4000)  = CONVERT(nvarchar(4000), CONCAT(N'FORMSOF(INFLECTIONAL', ',', '"', @Publisher, '"', ')'))


insert into @RETURN_TABLE

SELECT [id_book], [Book_name], [Authors_Full_all], [Publisher_name], [Year_published], [Availabe_Books_Quantity]
FROM Available_Books_Search 
WHERE CONTAINS (Authors_Full_all, @Author_1) 

UNION 

SELECT [id_book], [Book_name], [Authors_Full_all], [Publisher_name], [Year_published], [Availabe_Books_Quantity]
FROM Available_Books_Search 
WHERE CONTAINS (Book_name, @Book_1)  

UNION 

SELECT [id_book], [Book_name], [Authors_Full_all], [Publisher_name], [Year_published], [Availabe_Books_Quantity]
FROM Available_Books_Search 
WHERE CONTAINS (Publisher_name, @Publisher_1)  

RETURN
end
GO

SELECT * FROM [dbo].[Q_Common_CONTAINS_Search] (
   N'толстой'
  ,N'Война'
  ,N'ромашку')
GO


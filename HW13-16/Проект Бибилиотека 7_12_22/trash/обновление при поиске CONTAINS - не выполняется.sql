USE [Project_Library]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

--���������� ������������� ������

DECLARE @RC int
EXECUTE @RC = [dbo].[Refresh_Books_All_Authors] 
GO
DECLARE @RC_1 int
EXECUTE @RC_1 = [dbo].[Refresh_Available_Books_Search] 
GO

-- ���������� Full-Text Index (���� CHANGE_TRACKING != AUTO)
ALTER FULLTEXT INDEX ON Available_Books_Search
START FULL POPULATION
GO


---���� ��������� ������

declare @Author    nvarchar(4000), @Book      nvarchar(4000), @Publisher nvarchar(4000)
				

set  @Author	= 'FORMSOF(INFLECTIONAL, "�������")'
set  @Book		= 'FORMSOF(INFLECTIONAL, "�����������")'
set  @Publisher	= 'FORMSOF(INFLECTIONAL, "������")'




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






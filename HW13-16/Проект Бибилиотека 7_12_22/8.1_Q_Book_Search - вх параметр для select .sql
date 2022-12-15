USE [Project_Library]
GO

ALTER FUNCTION [dbo].[Q_Book_Search] (@Book     nvarchar(4000))
RETURNS @RETURN_TABLE TABLE( [id_book] int
							,[Book_name] nvarchar(50)
							,[Authors_Full_all] nvarchar(4000)
							,[Publisher_name] nvarchar(50)
							,[Year_published] int
							,[Availabe_Books_Quantity] int
							)
as BEGIN						

--set  @Book = N'капитан дочка'
insert into @RETURN_TABLE

SELECT [id_book], [Book_name], [Authors_Full_all], [Publisher_name], [Year_published], [Availabe_Books_Quantity]--, t1.*
FROM Available_Books_Search 
inner join FREETEXTTABLE(Available_Books_Search, Book_name, @Book) as t1
on Available_Books_Search.id_book=t1.[KEY]
order by t1.RANK DESC

RETURN

end
GO

USE [Project_Library]
GO

SELECT * FROM [dbo].[Q_Book_Search] (
   N'Войны')
GO





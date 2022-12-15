USE [Project_Library]
GO

/****** Object:  StoredProcedure [dbo].[Catalogue_Available_Books]    Script Date: 16.11.2022 11:26:08 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[Refresh_Books_All_Authors] as
BEGIN 

TRUNCATE TABLE dbo.[Books_All_Authors];


		with CTE_1 as
		(select distinct BA.id_Book
				,B.Book_name
				,(	
					select concat(AA.Last_name_A, ' ', AA.Name_A, ' ', AA.Second_name_A) 
					from Authors as AA 
					where AA.Last_name_A=A.Last_name_A 
						and
						  AA.Name_A=A.Name_A 
						and
						  AA.Second_name_A=A.Second_name_A
				 ) as Authors_Full 
		from Books_Authors as BA
		inner join [Books] as B on BA.id_Book=B.id_Book
		inner join [Authors] as A on BA.id_Author=A.id_Author
		)

insert into dbo.Books_All_Authors
		select C1.id_Book
			   ,STRING_AGG(Authors_Full,', ') as Authors_Full_all

	
		from CTE_1 as C1
		cross apply (select distinct id_Book from CTE_1) C2 where C1.id_Book=C2.id_Book
		group by C1.id_Book
 END 
GO



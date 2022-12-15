USE [Project_Library]
GO

CREATE PROCEDURE [dbo].[Refresh_Available_Books_Search] as
BEGIN 

TRUNCATE TABLE dbo.[Available_Books_Search];

insert into Available_Books_Search
select BAA.id_book
	   ,B.Book_name
	   ,BAA.Authors_Full_all
	   ,P.Publisher_name
	   ,Year(B.Year_published) as Year_published
	   , (
	      select 
		   sum(BS.Quantity) - isnull(sum(CI.Quantity),0)
		   from Bookstock as BS
		  left join Check_in_out_books as CI on BS.id_book = CI.id_book where CI.Date_in_Fact is null
		  and BS.id_Book = BAA.id_book
		 group by  BS.id_Book
		 ) as Availabe_Books_Quantity

from [Books_All_Authors] as BAA
join Books as B on BAA.id_book=B.id_book
join [Publishers] as P on B.id_Publisher=P.id_Publisher
join [Cities] as C on P.id_City=C.id_City


/*
select * from Availabe_Books_Search
*/

/*
(
	      select 
		   BS.id_Book
		  ,sum(BS.Quantity) as A 
		  ,sum(CI.Quantity) as B
		  ,sum(BS.Quantity) - isnull(sum(CI.Quantity),0)
		   from Bookstock as BS
		  left join Check_in_out_books as CI on BS.id_book = CI.id_book where CI.Date_in_Fact is null
		  and BS.id_Book = 
		 group by  BS.id_Book
		 )
*/

 END 
GO

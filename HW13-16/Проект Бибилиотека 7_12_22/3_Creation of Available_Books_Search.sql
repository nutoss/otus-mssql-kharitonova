USE [Project_Library]
GO	
		

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
into Available_Books_Search
from [Books_All_Authors] as BAA
join Books as B on BAA.id_book=B.id_book
join [Publishers] as P on B.id_Publisher=P.id_Publisher
join [Cities] as C on P.id_City=C.id_City

ALTER TABLE [dbo].[Available_Books_Search] ADD  CONSTRAINT [PK_ABS] PRIMARY KEY CLUSTERED 
(	[id_book] ASC)

USE master; 
GO 
/*IF DB_ID (N'Project_Library') IS NOT NULL 
	DROP DATABASE Project_Library; 
GO 

CREATE DATABASE [Project_Library]*/

USE Project_Library
GO
/*	
	ALTER TABLE [Publishers] DROP CONSTRAINT if exists [FK_Publishers_Cities]
	ALTER TABLE [Books] DROP CONSTRAINT if exists [FK_Books_Authors],  [FK_Books_Publishers]
	ALTER TABLE [Bookstock]  DROP CONSTRAINT if exists  [FK_Bookstock_Books] 
	ALTER TABLE [Books_Authors]  DROP CONSTRAINT if exists  [Books_Books] , [Authors_Authors] 
	DROP INDEX if exists  [Сardholders_INDEX_L_Name_PhNum] ON [dbo].[Сardholders]
	DROP TABLE if exists [Authors],
	[Check_in_out_books], [Cities], [Publishers], [Books],  [Сardholders],[Bookstock], [Books_Authors]
*/
--------------------------------------------------------------------------
---------Таблица Авторы + вставить значения
--------------------------------------------------------------------------
CREATE TABLE [Authors](
	id_Author int not null identity(1, 1)  primary key clustered,
	Last_name_A	nvarchar(50) not null,
	Name_A	nvarchar(50) not null,
	Second_name_A nvarchar(50) not null
)
GO

insert into [Authors] values(N'Пушкин', N'Александр', N'Сергеевич'), 
							(N'Толстой',N'Лев',N'Николаевич'),
							(N'Достоевский', N'Федор', N'Михайлович');

select * from [Authors]



--------------------------------------------------------------------------
---------Таблица ГОРОДА
--------------------------------------------------------------------------
CREATE TABLE [Cities](
	id_City int not null identity(1, 1)  primary key clustered,
	Cityname nvarchar(50) not null,
)
GO

insert into [Cities] values	(N'Москва'), 
							(N'Санкт-Петербург'),
							(N'Екатеринбург');
GO
select * from [Cities]



--------------------------------------------------------------------------
---------Таблица ЧИТАТЕЛИ
--------------------------------------------------------------------------
CREATE TABLE [Сardholders](
	id_Сardholder int not null identity(1, 1) primary key clustered,
	Last_name_C	nvarchar(50) not null,
	Name_C	nvarchar(50) not null,
	Second_name_C nvarchar(50) not null, 
	Phone_number_C nvarchar(20) null,
	Email_C nvarchar(256) null
)
GO

--создадим некластеризованнй индекс для быстрого поиска по номеру телефона и для ограничения уникальности записи (уникальность сочетания фамилии и номера)

CREATE UNIQUE NONCLUSTERED INDEX [Сardholders_INDEX_L_Name_PhNum] ON [dbo].[Сardholders]
(
	Last_name_C ASC,
	Phone_number_C ASC
)

insert into [Сardholders] values(N'Иванов', N'Иван', N'Иванович', '89164593656', N'III@gmail.com'), 
								(N'Петров',N'Петр',N'Петрович', '89167896546', N'PPP@gmail.com'),
								(N'Сидорова', N'Ольга', N'Михайловна', '89157888521', N'SOM@gmail.com');

GO						
select * from [Сardholders]



--------------------------------------------------------------------------
---------Таблица ИЗДАТЕЛЬСТВА
--------------------------------------------------------------------------
CREATE TABLE [Publishers](
	id_Publisher int not null identity(1, 1)  primary key clustered,
	Publisher_name nvarchar(50),
	id_City int
)
GO

insert into [Publishers] values (N'Ромашка', '1'), 
								(N'Росмэн', '3'),
								(N'Феникс', '2');

--создать ограничение по наличию id_Города для таблицы Издательства

ALTER TABLE [Publishers]  WITH CHECK ADD CONSTRAINT [FK_Publishers_Cities] FOREIGN KEY(id_City)
REFERENCES [Cities] (id_City)
GO

GO						
select * from [Publishers]




--------------------------------------------------------------------------
---------Таблица КНИГИ + вставить значения!!!!! + ограничить список Авторов, Издательств, Даты!!!!
--------------------------------------------------------------------------
CREATE TABLE [Books](
	id_Book int not null identity(1, 1)  primary key clustered,
	Book_name nvarchar(50),
	id_Publisher int not null,
	Year_published date not null
)
GO

--создать ограничение по наличию id_Автора, id_Издательства для таблицы Книги

ALTER TABLE [Books]  WITH CHECK ADD CONSTRAINT [FK_Books_Publishers] FOREIGN KEY(id_Publisher)
REFERENCES [Publishers] (id_Publisher)
GO

insert into [Books] values	(N'Капитанская дочка: повести', '3', '2020' ), 
							(N'Война и Мир'               , '1', '2020' ),
							(N'Война и Мир'               , '2', '2020' ),
							(N'Рассказы, сборник'         , '3', '2010' ) 

select * from [Books]

select * from [Authors]

--------------------------------------------------------------------------
---------Таблица КНИГИ_АВТОРЫ
--------------------------------------------------------------------------
CREATE TABLE [Books_Authors](
	id_Book int not null,
	id_Author int not null
)
--создать ограничение на уникальность авторов для таблицы Книги-Авторы в случае, если их несколько

ALTER TABLE [Books_Authors]  WITH CHECK ADD CONSTRAINT [FK_UNIQUE_Authors] UNIQUE (id_Book,id_Author)
GO

--создать ограничение по наличию id_авторов и книг
ALTER TABLE [Books_Authors]  WITH CHECK ADD CONSTRAINT [Books_Books] FOREIGN KEY(id_Book)
REFERENCES [Books] (id_Book)
GO

ALTER TABLE [Books_Authors]  WITH CHECK ADD CONSTRAINT [Authors_Authors] FOREIGN KEY(id_Author)
REFERENCES [Authors] (id_Author)
GO

insert into [Books_Authors] values	('1', '1'), 
									('2', '2'), 
									('3', '2'),
									('4', '1')
									('4', '2')
									
select * from [Books_Authors]




--------------------------------------------------------------------------
---------Таблица СКЛАД книг для библиотеки + ограничить список Книг 
--------------------------------------------------------------------------
CREATE TABLE [Bookstock]( 
	id_Bookitem int not null identity(1, 1)  primary key clustered,
	id_Book int not null,
	Price decimal(18,2) not null,
	Quantity int not null,
	Date_in date not null
	)
--создать ограничение по наличию id_Книги для таблицы Cклад
ALTER TABLE [Bookstock]   WITH CHECK ADD CONSTRAINT [FK_Bookstock_Books] FOREIGN KEY(id_Book)
REFERENCES [Books] (id_Book)
GO

insert into [Bookstock] values	('2', '45', '40', '2022-02-01'),
								('2', '50', '10', '2022-02-10'), 
								('1', '65', '20', '2022-03-07'),
								('3', '70', '50', '2022-06-22'),
								('4', '25', '3', '2022-09-13')

select * from [Bookstock]


--------------------------------------------------------------------------
---------Таблица Выдача книг + вставить значения!!!!! + ограничить список Авторов, Читателей (билетов), ограничения на даты!!!
--------------------------------------------------------------------------
CREATE TABLE [Check_in_out_books](
	id_Check_out int not null identity(1, 1) primary key clustered,
	id_Book	int not null,
	Quantity int not null DEFAULT 1,
	id_Сardholder int not null,
	Date_out	date not null,
	Date_in_plan date not null,
	Date_in_Fact date null
)
GO

--создать ограничение по наличию id_Книги, id_читателя для таблицы Выдача

ALTER TABLE [Check_in_out_books]   WITH CHECK ADD CONSTRAINT [FK_Check_in_out_books_Books] FOREIGN KEY(id_Book)
REFERENCES [Books] (id_Book)
GO

ALTER TABLE [Check_in_out_books]   WITH CHECK ADD CONSTRAINT [FK_Check_in_out_books_Сardholders] FOREIGN KEY(id_Сardholder)
REFERENCES [Сardholders] (id_Сardholder)
GO

insert into [Check_in_out_books] values	('1', '1', '3', GETDATE(), GETDATE(), GETDATE()),
										('1', '1', '3', GETDATE(), '2022-12-01', null)


select * from [Check_in_out_books]
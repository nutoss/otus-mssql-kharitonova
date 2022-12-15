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
	DROP INDEX if exists  [�ardholders_INDEX_L_Name_PhNum] ON [dbo].[�ardholders]
	DROP TABLE if exists [Authors],
	[Check_in_out_books], [Cities], [Publishers], [Books],  [�ardholders],[Bookstock], [Books_Authors]
*/
--------------------------------------------------------------------------
---------������� ������ + �������� ��������
--------------------------------------------------------------------------
CREATE TABLE [Authors](
	id_Author int not null identity(1, 1)  primary key clustered,
	Last_name_A	nvarchar(50) not null,
	Name_A	nvarchar(50) not null,
	Second_name_A nvarchar(50) not null
)
GO

insert into [Authors] values(N'������', N'���������', N'���������'), 
							(N'�������',N'���',N'����������'),
							(N'�����������', N'�����', N'����������');

select * from [Authors]



--------------------------------------------------------------------------
---------������� ������
--------------------------------------------------------------------------
CREATE TABLE [Cities](
	id_City int not null identity(1, 1)  primary key clustered,
	Cityname nvarchar(50) not null,
)
GO

insert into [Cities] values	(N'������'), 
							(N'�����-���������'),
							(N'������������');
GO
select * from [Cities]



--------------------------------------------------------------------------
---------������� ��������
--------------------------------------------------------------------------
CREATE TABLE [�ardholders](
	id_�ardholder int not null identity(1, 1) primary key clustered,
	Last_name_C	nvarchar(50) not null,
	Name_C	nvarchar(50) not null,
	Second_name_C nvarchar(50) not null, 
	Phone_number_C nvarchar(20) null,
	Email_C nvarchar(256) null
)
GO

--�������� ����������������� ������ ��� �������� ������ �� ������ �������� � ��� ����������� ������������ ������ (������������ ��������� ������� � ������)

CREATE UNIQUE NONCLUSTERED INDEX [�ardholders_INDEX_L_Name_PhNum] ON [dbo].[�ardholders]
(
	Last_name_C ASC,
	Phone_number_C ASC
)

insert into [�ardholders] values(N'������', N'����', N'��������', '89164593656', N'III@gmail.com'), 
								(N'������',N'����',N'��������', '89167896546', N'PPP@gmail.com'),
								(N'��������', N'�����', N'����������', '89157888521', N'SOM@gmail.com');

GO						
select * from [�ardholders]



--------------------------------------------------------------------------
---------������� ������������
--------------------------------------------------------------------------
CREATE TABLE [Publishers](
	id_Publisher int not null identity(1, 1)  primary key clustered,
	Publisher_name nvarchar(50),
	id_City int
)
GO

insert into [Publishers] values (N'�������', '1'), 
								(N'������', '3'),
								(N'������', '2');

--������� ����������� �� ������� id_������ ��� ������� ������������

ALTER TABLE [Publishers]  WITH CHECK ADD CONSTRAINT [FK_Publishers_Cities] FOREIGN KEY(id_City)
REFERENCES [Cities] (id_City)
GO

GO						
select * from [Publishers]




--------------------------------------------------------------------------
---------������� ����� + �������� ��������!!!!! + ���������� ������ �������, �����������, ����!!!!
--------------------------------------------------------------------------
CREATE TABLE [Books](
	id_Book int not null identity(1, 1)  primary key clustered,
	Book_name nvarchar(50),
	id_Publisher int not null,
	Year_published date not null
)
GO

--������� ����������� �� ������� id_������, id_������������ ��� ������� �����

ALTER TABLE [Books]  WITH CHECK ADD CONSTRAINT [FK_Books_Publishers] FOREIGN KEY(id_Publisher)
REFERENCES [Publishers] (id_Publisher)
GO

insert into [Books] values	(N'����������� �����: �������', '3', '2020' ), 
							(N'����� � ���'               , '1', '2020' ),
							(N'����� � ���'               , '2', '2020' ),
							(N'��������, �������'         , '3', '2010' ) 

select * from [Books]

select * from [Authors]

--------------------------------------------------------------------------
---------������� �����_������
--------------------------------------------------------------------------
CREATE TABLE [Books_Authors](
	id_Book int not null,
	id_Author int not null
)
--������� ����������� �� ������������ ������� ��� ������� �����-������ � ������, ���� �� ���������

ALTER TABLE [Books_Authors]  WITH CHECK ADD CONSTRAINT [FK_UNIQUE_Authors] UNIQUE (id_Book,id_Author)
GO

--������� ����������� �� ������� id_������� � ����
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
---------������� ����� ���� ��� ���������� + ���������� ������ ���� 
--------------------------------------------------------------------------
CREATE TABLE [Bookstock]( 
	id_Bookitem int not null identity(1, 1)  primary key clustered,
	id_Book int not null,
	Price decimal(18,2) not null,
	Quantity int not null,
	Date_in date not null
	)
--������� ����������� �� ������� id_����� ��� ������� C����
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
---------������� ������ ���� + �������� ��������!!!!! + ���������� ������ �������, ��������� (�������), ����������� �� ����!!!
--------------------------------------------------------------------------
CREATE TABLE [Check_in_out_books](
	id_Check_out int not null identity(1, 1) primary key clustered,
	id_Book	int not null,
	Quantity int not null DEFAULT 1,
	id_�ardholder int not null,
	Date_out	date not null,
	Date_in_plan date not null,
	Date_in_Fact date null
)
GO

--������� ����������� �� ������� id_�����, id_�������� ��� ������� ������

ALTER TABLE [Check_in_out_books]   WITH CHECK ADD CONSTRAINT [FK_Check_in_out_books_Books] FOREIGN KEY(id_Book)
REFERENCES [Books] (id_Book)
GO

ALTER TABLE [Check_in_out_books]   WITH CHECK ADD CONSTRAINT [FK_Check_in_out_books_�ardholders] FOREIGN KEY(id_�ardholder)
REFERENCES [�ardholders] (id_�ardholder)
GO

insert into [Check_in_out_books] values	('1', '1', '3', GETDATE(), GETDATE(), GETDATE()),
										('1', '1', '3', GETDATE(), '2022-12-01', null)


select * from [Check_in_out_books]
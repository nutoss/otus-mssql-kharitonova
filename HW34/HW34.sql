--смотрим какие таблицы партиционированы - было 2
select distinct t.name
from sys.partitions p
inner join sys.tables t
	on p.object_id = t.object_id
where p.partition_number <> 1

--создадим файловую группу
ALTER DATABASE [WideWorldImporters] ADD FILEGROUP [YearData]
GO


--добавляем файл БД
ALTER DATABASE [WideWorldImporters] ADD FILE 
( NAME = N'Years', FILENAME = N'C:\Intel\Yeardata.ndf' , 
SIZE = 1097152KB , FILEGROWTH = 65536KB ) TO FILEGROUP [YearData]
GO

--точности по датам нет, выбираем правое партицонирование, создаем функцию 
CREATE PARTITION FUNCTION YearPartitions_FOR_Inv_2_HW34 (date)
as RANGE RIGHT FOR VALUES ('2013-01-01', '2014-01-01', '2015-01-01', '2016-01-01')

-- партиционируем, используя созданную функцию
CREATE PARTITION SCHEME [schmYearPartition] AS PARTITION [YearPartitions_FOR_Inv_2_HW34] 
ALL TO ([YearData])
GO

--копия таблицы 
select * into Sales.Invoices_2_FOR_HW34_PARTIS from Sales.Invoices

---пошли пр кнопкой мыши на новую таблицу - Storage - Create Partition - Finish - скопировали из скрипта часть, где создается кластерный индекс


CREATE CLUSTERED INDEX [ClusteredIndex_on_schmYearPartition_638149944989750033] ON [Sales].[Invoices_2_FOR_HW34_PARTIS]
(
	[InvoiceDate]
)WITH (SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF) ON [schmYearPartition]([InvoiceDate])

--DROP INDEX [ClusteredIndex_on_schmYearPartition_638149944989750033] ON [Sales].[Invoices_2_FOR_HW34_PARTIS]



--смотрим какие таблицы партиционированы - теперь 3
select distinct t.name
from sys.partitions p
inner join sys.tables t
	on p.object_id = t.object_id
where p.partition_number <> 1


--смотрим как конкретно по диапазонам распределились данные
SELECT  $PARTITION.YearPartitions_FOR_Inv_2_HW34(InvoiceDate) AS Partition
		, COUNT(*) AS [COUNT]
		, MIN(InvoiceDate)
		,MAX(InvoiceDate) 
FROM Sales.Invoices_2_FOR_HW34_PARTIS
GROUP BY $PARTITION.YearPartitions_FOR_Inv_2_HW34(InvoiceDate) 
ORDER BY Partition ;  





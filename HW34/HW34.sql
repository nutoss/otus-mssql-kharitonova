--������� ����� ������� ���������������� - ���� 2
select distinct t.name
from sys.partitions p
inner join sys.tables t
	on p.object_id = t.object_id
where p.partition_number <> 1

--�������� �������� ������
ALTER DATABASE [WideWorldImporters] ADD FILEGROUP [YearData]
GO


--��������� ���� ��
ALTER DATABASE [WideWorldImporters] ADD FILE 
( NAME = N'Years', FILENAME = N'C:\Intel\Yeardata.ndf' , 
SIZE = 1097152KB , FILEGROWTH = 65536KB ) TO FILEGROUP [YearData]
GO

--�������� �� ����� ���, �������� ������ ����������������, ������� ������� 
CREATE PARTITION FUNCTION YearPartitions_FOR_Inv_2_HW34 (date)
as RANGE RIGHT FOR VALUES ('2013-01-01', '2014-01-01', '2015-01-01', '2016-01-01')

-- ��������������, ��������� ��������� �������
CREATE PARTITION SCHEME [schmYearPartition] AS PARTITION [YearPartitions_FOR_Inv_2_HW34] 
ALL TO ([YearData])
GO

--����� ������� 
select * into Sales.Invoices_2_FOR_HW34_PARTIS from Sales.Invoices

---����� �� ������� ���� �� ����� ������� - Storage - Create Partition - Finish - ����������� �� ������� �����, ��� ��������� ���������� ������


CREATE CLUSTERED INDEX [ClusteredIndex_on_schmYearPartition_638149944989750033] ON [Sales].[Invoices_2_FOR_HW34_PARTIS]
(
	[InvoiceDate]
)WITH (SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF) ON [schmYearPartition]([InvoiceDate])

--DROP INDEX [ClusteredIndex_on_schmYearPartition_638149944989750033] ON [Sales].[Invoices_2_FOR_HW34_PARTIS]



--������� ����� ������� ���������������� - ������ 3
select distinct t.name
from sys.partitions p
inner join sys.tables t
	on p.object_id = t.object_id
where p.partition_number <> 1


--������� ��� ��������� �� ���������� �������������� ������
SELECT  $PARTITION.YearPartitions_FOR_Inv_2_HW34(InvoiceDate) AS Partition
		, COUNT(*) AS [COUNT]
		, MIN(InvoiceDate)
		,MAX(InvoiceDate) 
FROM Sales.Invoices_2_FOR_HW34_PARTIS
GROUP BY $PARTITION.YearPartitions_FOR_Inv_2_HW34(InvoiceDate) 
ORDER BY Partition ;  





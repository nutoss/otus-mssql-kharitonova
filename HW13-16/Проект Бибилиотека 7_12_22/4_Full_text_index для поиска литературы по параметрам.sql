USE [Project_Library]
GO
-- ������� �������������� �������
CREATE FULLTEXT CATALOG WWI_FT_Catalog
WITH ACCENT_SENSITIVITY = ON
AS DEFAULT
AUTHORIZATION [dbo]

-- ������� �������������� ������ �� Book_name
CREATE FULLTEXT INDEX ON Available_Books_Search(Book_name, Authors_Full_all LANGUAGE Russian)
KEY INDEX PK_ABS -- ��������� ����
ON (WWI_FT_Catalog)
WITH (
  CHANGE_TRACKING = AUTO, /* AUTO, MANUAL, OFF */
  STOPLIST = SYSTEM /* SYSTEM, OFF ��� ���������������� stoplist */
);
GO
-- DROP FULLTEXT INDEX PK_ABS

-- ���������� Full-Text Index (���� CHANGE_TRACKING != AUTO)
ALTER FULLTEXT INDEX ON Available_Books_Search
START FULL POPULATION



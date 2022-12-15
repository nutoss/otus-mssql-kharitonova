USE [Project_Library]
GO
-- Создаем полнотекстовый каталог
CREATE FULLTEXT CATALOG WWI_FT_Catalog
WITH ACCENT_SENSITIVITY = ON
AS DEFAULT
AUTHORIZATION [dbo]

-- Создаем полнотекстовый индекс на Book_name
CREATE FULLTEXT INDEX ON Available_Books_Search(Book_name, Authors_Full_all LANGUAGE Russian)
KEY INDEX PK_ABS -- первичный ключ
ON (WWI_FT_Catalog)
WITH (
  CHANGE_TRACKING = AUTO, /* AUTO, MANUAL, OFF */
  STOPLIST = SYSTEM /* SYSTEM, OFF или пользовательский stoplist */
);
GO
-- DROP FULLTEXT INDEX PK_ABS

-- Обновление Full-Text Index (если CHANGE_TRACKING != AUTO)
ALTER FULLTEXT INDEX ON Available_Books_Search
START FULL POPULATION



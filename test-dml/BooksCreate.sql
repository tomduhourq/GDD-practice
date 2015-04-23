IF OBJECT_ID ('dbo.BOOKS') IS NOT NULL
    DROP TABLE dbo.BOOKS;
GO

CREATE TABLE BOOKS
(ID INT PRIMARY KEY,
 EDITORIAL VARCHAR(100),
 PRICE INT,
 TITLE VARCHAR(100),
 AUTHOR VARCHAR(100));
 GO
 
 INSERT INTO BOOKS (ID, EDITORIAL, PRICE, TITLE, AUTHOR) VALUES
 (1, 'KAPELUSZ', 20, 'LAS MIL Y UNA NOCHES', NULL),
 (2, 'ARTIMA', 290, 'SCALACHECK', 'RICK NILLS'),
 (3, 'ARTIMA', NULL, 'PROGRAMMING IN SCALA', 'MARTIN ODERSKY, LEX SPOON, BILL VENNERS'),
 (4, 'KAPELUSZ', 300, 'LA LLAVE MAESTRA', 'SARLOMPA'),
 (5, 'HODDER', 22,'IT', 'STEPHEN KING'),
 (6, 'HODDER', NULL, 'SKELETON CREW', 'STEPHEN KING'),
 (7, 'OREILLY', 55, 'LEARNING SPARK', 'MATEI ZAHARIA'),
 (8, 'OREILLY', 123, 'HADOOP: THE DEFINITIVE GUIDE', 'TOM WHITE'),
 (9, 'OREILLY', 1241, 'INTRODUCTION TO SPARK', 'PACO NATHAN');
 
  
 
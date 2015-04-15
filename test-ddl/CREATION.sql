IF OBJECT_ID('dbo.PERSONA') IS NOT NULL
BEGIN
	DROP TABLE PERSONA;
END;

IF OBJECT_ID('dbo.PAIS') IS NOT NULL
BEGIN
	DROP TABLE PAIS;
END;

CREATE TABLE PAIS
(ID		INT	PRIMARY KEY,
 NOMBRE CHAR(100) NOT NULL);
 
 

CREATE TABLE PERSONA
(ID INT PRIMARY KEY,
 NOMBRE CHAR(100) NOT NULL,
 ID_HIJO INT REFERENCES PERSONA(ID),
 ID_PAIS_NAC INT NOT NULL REFERENCES PAIS(ID),
 ID_PAIS_RES INT NOT NULL REFERENCES PAIS(ID),
 CONSTRAINT CHK_UNIQUE_HIJO UNIQUE(ID, ID_HIJO));

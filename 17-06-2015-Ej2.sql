/* Implemente el/los objetos de base de datos para actualizar la columna 
empl_ventas_historicas (decimal(12,2) para un vendedor,
la sumatoria de las facturas que vendió ante una operación de DML*/
IF COL_LENGTH('Empleado', 'empl_ventas_historicas') IS NOT NULL
BEGIN
	ALTER TABLE Empleado DROP COLUMN empl_ventas_historicas
END
GO

ALTER TABLE Empleado ADD empl_ventas_historicas decimal(12,2) default 0.0

IF OBJECT_ID('dbo.updateHistorico') IS NOT NULL
BEGIN
	DROP TRIGGER dbo.updateHistorico;
END;
GO

CREATE TRIGGER dbo.updateHistorico ON Factura AFTER INSERT,UPDATE,DELETE
AS BEGIN TRANSACTION
	-- Necesito saber si solo se insertó, o borró o actualizó la tabla
	DECLARE @numInserted int = (SELECT COUNT(*) FROM inserted)
	DECLARE @numDeleted int = (SELECT COUNT(*) FROM deleted)
	DECLARE @total decimal(12,2)
	DECLARE @vendedor numeric(6)
	
	-- Solo inserté
	IF @numInserted > 0 AND @numDeleted = 0
	BEGIN
		DECLARE ins_curs CURSOR FOR (SELECT fact_vendedor, SUM(fact_total) FROM inserted GROUP BY fact_vendedor)
		OPEN ins_curs
		
		FETCH NEXT FROM ins_curs INTO @vendedor, @total
		WHILE @@FETCH_STATUS = 0
		BEGIN
			UPDATE Empleado 
			SET empl_ventas_historicas = empl_ventas_historicas + @total
			WHERE empl_codigo = @vendedor
			
			FETCH NEXT FROM ins_curs INTO @vendedor, @total
		END
		
		CLOSE ins_curs
		DEALLOCATE ins_curs
	END
	-- Update
	ELSE IF @numInserted > 0 AND @numDeleted > 0
	BEGIN
		DECLARE @vendedor1 numeric(6)
		DECLARE @total1 decimal(12,2)
		DECLARE ins_curs CURSOR FOR (SELECT fact_vendedor, SUM(fact_total) FROM inserted GROUP BY fact_vendedor)
		DECLARE del_curs CURSOR FOR (SELECT fact_vendedor, SUM(fact_total) FROM deleted GROUP BY fact_vendedor)
		
		OPEN ins_curs
		OPEN del_curs
		
		FETCH NEXT FROM ins_curs INTO @vendedor, @total
		FETCH NEXT FROM del_curs INTO @vendedor1, @total1
		
		WHILE @@FETCH_STATUS = 0
		BEGIN
			UPDATE Empleado 
			SET empl_ventas_historicas = empl_ventas_historicas + (@total - @total1)
			WHERE empl_codigo = @vendedor
			
			FETCH NEXT FROM ins_curs INTO @vendedor, @total
			FETCH NEXT FROM del_curs INTO @vendedor1, @total1
		END
		
		CLOSE ins_curs
		CLOSE del_curs
		DEALLOCATE ins_curs
		DEALLOCATE del_curs
	END
	ELSE 
	BEGIN
		-- Delete only
		DECLARE del_curs CURSOR FOR (SELECT fact_vendedor, SUM(fact_total) FROM deleted GROUP BY fact_vendedor)
		OPEN del_curs
		
		FETCH NEXT FROM del_curs INTO @vendedor, @total
		
		WHILE @@FETCH_STATUS = 0
		BEGIN
			UPDATE Empleado
			SET empl_ventas_historicas = empl_ventas_historicas - @total
			WHERE empl_codigo = @vendedor
			
			FETCH NEXT FROM del_curs INTO @vendedor, @total
		END
		
		CLOSE del_curs
		DEALLOCATE del_curs
	END
	
COMMIT
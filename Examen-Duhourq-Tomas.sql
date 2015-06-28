use GESTION_1C2015
-- Ej. 1
(SELECT * FROM
(SELECT TOP 10 d.depo_codigo, 
		d.depo_detalle,
		COUNT(*) as productos_distintos, -- Hay una fila por producto por depósito
		e.empl_codigo,
		(CASE WHEN e.empl_codigo NOT IN 
		(SELECT empl_jefe 
		 FROM Empleado 
		 WHERE empl_jefe IS NOT NULL) THEN 'S' ELSE 'N' END) es_empleado,
		(SELECT TOP 1 stoc_producto 
		FROM STOCK s2 
		WHERE s2.stoc_deposito = s.stoc_deposito 
		ORDER BY stoc_proxima_reposicion) as proximo_reponer
FROM DEPOSITO d
INNER JOIN Zona z
ON d.depo_zona = z.zona_codigo
INNER JOIN Departamento dep
ON z.zona_codigo = dep.depa_zona
INNER JOIN Empleado e
ON dep.depa_codigo = e.empl_departamento
INNER JOIN STOCK s
ON s.stoc_deposito = d.depo_codigo -- Este join garantiza que haya mínimo un producto en el depósito
GROUP BY d.depo_codigo, d.depo_detalle, e.empl_codigo, s.stoc_deposito
ORDER BY COUNT(*) DESC) as top_10)
UNION
(SELECT  * FROM
(SELECT TOP 5 d.depo_codigo, 
		d.depo_detalle,
		COUNT(*) as productos_distintos, -- Hay una fila por producto por depósito
		e.empl_codigo,
		(CASE WHEN e.empl_codigo NOT IN 
		(SELECT empl_jefe 
		 FROM Empleado 
		 WHERE empl_jefe IS NOT NULL) THEN 'S' ELSE 'N' END) es_empleado,
		(SELECT TOP 1 stoc_producto 
		FROM STOCK s2 
		WHERE s2.stoc_deposito = s.stoc_deposito 
		ORDER BY stoc_proxima_reposicion) as proximo_reponer
FROM DEPOSITO d
INNER JOIN Zona z
ON d.depo_zona = z.zona_codigo
INNER JOIN Departamento dep
ON z.zona_codigo = dep.depa_zona
INNER JOIN Empleado e
ON dep.depa_codigo = e.empl_departamento
INNER JOIN STOCK s
ON s.stoc_deposito = d.depo_codigo -- Este join garantiza que haya mínimo un producto en el depósito
GROUP BY d.depo_codigo, d.depo_detalle, e.empl_codigo, s.stoc_deposito
ORDER BY COUNT(*)) as worst_5)
GO

-- Solución Fran (Sin select en el from)
SELECT d.depo_codigo, d.depo_detalle,
		(SELECT COUNT(*) FROM Producto p, STOCK s WHERE p.prod_codigo = s.stoc_producto AND s.stoc_deposito = d.depo_codigo) AS Total_Prods_distintos,
		(SELECT TOP 1 (CASE WHEN e.empl_jefe is not NULL THEN 'N' ELSE 'S' END) FROM Empleado e WHERE e.empl_codigo = d.depo_encargado) AS Empl_Es_Jefe,
		(SELECT TOP 1 p.prod_codigo FROM Producto p, STOCK s WHERE p.prod_codigo = s.stoc_producto AND s.stoc_deposito = d.depo_codigo ORDER BY s.stoc_proxima_reposicion ASC) AS Proxmo_Prod_Reposicion


FROM DEPOSITO d
WHERE d.depo_codigo IN (
						SELECT TOP 10 d1.depo_codigo
						FROM DEPOSITO d1, STOCK s1, Producto p1
						WHERE p1.prod_codigo = s1.stoc_producto AND s1.stoc_deposito = d1.depo_codigo
							AND p1.prod_codigo IN (SELECT DISTINCT p3.prod_codigo
													FROM Producto p3)
						GROUP BY d1.depo_codigo, d1.depo_detalle
						HAVING COUNT(p1.prod_codigo) > 1
						ORDER BY COUNT(p1.prod_codigo) DESC
						UNION
						SELECT TOP 5 d2.depo_codigo
						FROM DEPOSITO d2, STOCK s2, Producto p2
						WHERE p2.prod_codigo = s2.stoc_producto AND s2.stoc_deposito = d2.depo_codigo
							AND p2.prod_codigo IN (SELECT DISTINCT p4.prod_codigo
													FROM Producto p4)
						GROUP BY d2.depo_codigo, d2.depo_detalle
						HAVING COUNT(p2.prod_codigo) > 1
						ORDER BY COUNT(p2.prod_codigo) ASC
						)
GROUP BY d.depo_codigo, d.depo_detalle, d.depo_encargado

-- Ej.2

IF OBJECT_ID('dbo.t_updateCliente') IS NOT NULL
BEGIN
	DROP TRIGGER dbo.t_updateCliente;
END;
GO

CREATE TRIGGER dbo.t_updateCliente ON Cliente INSTEAD OF UPDATE
AS BEGIN TRANSACTION
	-- Solo se puede hacer un update, si hay un update masivo saco un mensaje de error
	-- Con verificar en inserted ya me basta, porque el trigger se hace sobre un update
	DECLARE @numInserted int = (SELECT COUNT(*) FROM inserted)
	
	IF @numInserted > 1 
	BEGIN
		PRINT 'No se puede efectuar un update masivo sobre la tabla de CLIENTES'
		ROLLBACK TRANSACTION
	END
	ELSE BEGIN
		DECLARE @codigoViejo char(6) = (SELECT clie_codigo FROM deleted)
		DECLARE @codigoNuevo char(6) = (SELECT clie_codigo FROM inserted)
		
		IF @codigoNuevo IN (SELECT clie_codigo FROM Cliente)
		BEGIN
			PRINT 'El código ingresado ya existe en la base, elija otro'
			ROLLBACK TRANSACTION
		END
		
		INSERT INTO Cliente
		SELECT @codigoNuevo, 
				clie_razon_social,
				clie_telefono,
				clie_domicilio,
				clie_limite_credito,
				clie_vendedor
		 FROM inserted 
		 WHERE clie_codigo = @codigoNuevo
		 
		UPDATE Factura
		SET fact_cliente = @codigoNuevo
		WHERE fact_cliente = @codigoViejo
		
		DELETE Cliente WHERE clie_codigo = @codigoViejo
	END

COMMIT -- Funciona bien

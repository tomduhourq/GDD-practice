USE GESTION_1C2015
/* 1)Hacer una función que dado un articulo y un deposito devuelva un string que
indique el estado del deposito según el articulo. Si la cantidad almacenada es menor
al limite retornar “OCUPACION DEL DEPOSITO XX %” siendo XX el % de
ocupación. Si la cantidad almacenada es mayor o igual al límite retornar
“DEPOSITO COMPLETO”. */
IF OBJECT_ID('dbo.f_OcupacionDepo') IS NOT NULL
BEGIN
	DROP FUNCTION dbo.f_OcupacionDepo;
END
GO

CREATE FUNCTION dbo.f_OcupacionDepo (@producto char(8), @deposito char(2))
RETURNS varchar(50) AS BEGIN

	DECLARE @maximo decimal(12,2)
	DECLARE @almacenado decimal(12,2)
	
	(SELECT @almacenado = stoc_cantidad
		   ,@maximo = stoc_stock_maximo
	FROM STOCK 
	WHERE stoc_producto = @producto AND 
		  stoc_deposito = @deposito)
		  
	IF @almacenado < @maximo BEGIN
		RETURN 'OCUPACION DEL DEPOSITO: ' + CONVERT(varchar(25),100 * (@almacenado/@maximo)) + '%'
	END
	ELSE BEGIN
		RETURN 'DEPOSITO COMPLETO'
	END
	RETURN 'ERROR'	
END
GO

/* 2) Realizar una función que dado un artículo y una fecha, retorne el stock que existía a esa fecha. */
IF OBJECT_ID('dbo.f_StockFecha') IS NOT NULL
BEGIN
	DROP FUNCTION dbo.f_StockFecha;
END
GO

CREATE FUNCTION dbo.f_StockFecha (@producto char(8), @fecha char(10)) 
RETURNS decimal(12, 2) AS BEGIN
	DECLARE @fechaReal smalldatetime = CONVERT(smalldatetime, CONVERT(datetime, @fecha))
	RETURN (SELECT SUM(stoc_cantidad) 
	FROM STOCK 
	WHERE stoc_producto = @producto AND 
		  -- El stock tiene que estar entre el mínimo menor a la fecha dada y la fecha dada como máximo
		  stoc_proxima_reposicion in (
		  (SELECT TOP 1 stoc_proxima_reposicion 
			FROM STOCK  
			WHERE stoc_proxima_reposicion <= @fechaReal AND
				  stoc_producto = @producto),  @fechaReal))
END
GO

/* 3) Cree el/los objetos de base de datos necesarios para corregir la tabla empleado en
caso que sea necesario.
Se sabe que debería existir un único gerente general (debería ser el único empleado
sin jefe). Si detecta que hay más de un empleado sin jefe deberá elegir entre ellos el
gerente general, el cual será seleccionado por mayor salario. Si hay más de uno se
seleccionara el de mayor antigüedad en la empresa.
Al finalizar la ejecución del objeto la tabla deberá cumplir con la regla de un único
empleado sin jefe (el gerente general) y deberá retornar la cantidad de empleados
que había sin jefe antes de la ejecución. */

-- Solo pueden ponerse expresiones escalares en el body de los constraints, por eso no se puede usar un constraint
IF OBJECT_ID('dbo.unicoJefe') IS NOT NULL
BEGIN
	DROP PROCEDURE dbo.unicoJefe;
END;
GO

-- No se habla en ningún momento de que se debe cumplir siempre, solo a demanda => SP no TRIGGER
CREATE PROCEDURE dbo.unicoJefe
AS
	DECLARE @cantidadSinJefe int = (SELECT COUNT(*) FROM Empleado WHERE empl_jefe IS NULL)
	DECLARE	@empl_codigo numeric(6,0)
		
	IF @cantidadSinJefe > 1 
	BEGIN
		-- SELECCION DE JEFE
		SELECT @empl_codigo = empl_codigo 
		FROM Empleado 
		WHERE empl_jefe IS NULL AND
			  empl_salario = (SELECT MAX(empl_salario) FROM Empleado WHERE empl_jefe IS NULL) AND
			  empl_ingreso = (SELECT MIN(empl_ingreso) FROM Empleado WHERE empl_jefe IS NULL);
			  
		-- SETEAR A TODOS LOS POTENCIALES JEFES ABAJO DEL GERENTE GENERAL
		UPDATE Empleado 
		SET empl_jefe = @empl_codigo 
		WHERE empl_codigo != @empl_codigo AND empl_jefe IS NULL
	END
	
	SELECT @cantidadSinJefe
GO

/* 4) Cree el/los objetos de base de datos necesarios para actualizar la columna de
empleado empl_comision con la sumatoria del total de lo vendido por ese empleado
a lo largo del ultimo año. Se deberá retornar el código del vendedor que más vendió
(en monto) a lo largo del último año. */

-- Se puede resolver con un trigger, el tema es que es una operación muy costosa si es para todo el año cada vez que inserto.
-- Lo ideal sería llamar a un SP cuando se tienen todos los registros por primera vez, calcular la comision,
-- y luego en cada insert sumar la comision individual con el trigger

-- O un SP que se ejecuta a fin de año
IF OBJECT_ID('dbo.calcularComisiones') IS NOT NULL
BEGIN
	DROP PROCEDURE dbo.calcularComisiones;
END;
GO

CREATE PROCEDURE dbo.calcularComisiones @anio int AS
	DECLARE @comision decimal(12, 2);
	DECLARE @id numeric(6,0);
	DECLARE comisiones_curs CURSOR FOR 
	(SELECT fact_vendedor, SUM(item_cantidad * item_precio)
	FROM Factura 
	INNER JOIN Item_Factura
	ON fact_tipo = item_tipo AND
	   fact_sucursal = item_sucursal AND
	   fact_numero = item_numero
	 WHERE YEAR(fact_fecha) = @anio
	 GROUP BY fact_vendedor);
	 
	 OPEN comisiones_curs;
	 
	 FETCH NEXT FROM comisiones_curs INTO @id, @comision;
	 
	 WHILE @@FETCH_STATUS = 0
	 BEGIN
		UPDATE Empleado
		SET empl_comision = @comision
		WHERE empl_codigo = @id;
		
		FETCH NEXT FROM comisiones_curs INTO @id, @comision;
	 END
	 
	 CLOSE comisiones_curs;
	 DEALLOCATE comisiones_curs;
	 
	 SELECT TOP 1 empl_codigo FROM Empleado ORDER BY empl_comision DESC;
GO

-- 5) Transact

IF OBJECT_ID('dbo.Fact_table') IS NOT NULL
BEGIN
	DROP TABLE dbo.Fact_table;
END;

GO
CREATE TABLE Fact_table(
 anio char(4) NOT NULL,
 mes char(2) NOT NULL,
 familia char(3) NOT NULL,
 rubro char(4) NOT NULL,
 zona char(3) NOT NULL,
 cliente char(6) NOT NULL,
 producto char(8) NOT NULL,
 cantidad decimal(12, 2) NOT NULL,
 monto decimal(12, 2) NOT NULL
);

GO

ALTER TABLE Fact_table ADD CONSTRAINT pk_Fact PRIMARY KEY(anio, mes, familia, rubro, zona, cliente, producto);

GO 

IF OBJECT_ID('dbo.Fill_Fact') IS NOT NULL
BEGIN
	DROP PROCEDURE dbo.Fill_Fact;
END;

GO

CREATE PROCEDURE dbo.Fill_Fact
AS BEGIN 
	DELETE dbo.Fact_table;
	INSERT INTO dbo.Fact_table(anio, mes, familia, rubro, zona, cliente, producto, cantidad, monto)
	SELECT YEAR(f.fact_fecha), MONTH(f.fact_fecha), fam.fami_id, r.rubr_id, z.zona_codigo, c.clie_codigo, p.prod_codigo, SUM(i.item_cantidad), SUM(i.item_cantidad * i.item_precio)
	FROM Cliente c
	INNER JOIN Factura f
	ON c.clie_codigo = f.fact_cliente
	INNER JOIN Item_Factura i
	ON f.fact_sucursal = i.item_sucursal AND
	   f.fact_numero = i.item_numero
	INNER JOIN Producto p
	ON i.item_producto = p.prod_codigo
	INNER JOIN Rubro r
	ON p.prod_rubro = r.rubr_id
	INNER JOIN Familia fam
	ON p.prod_familia = fam.fami_id
	INNER JOIN Empleado e
	ON f.fact_vendedor = e.empl_codigo
	INNER JOIN Departamento d
	ON e.empl_departamento = d.depa_codigo
	INNER JOIN Zona z
	ON d.depa_zona = z.zona_codigo
	GROUP BY  YEAR(f.fact_fecha), MONTH(f.fact_fecha),fam.fami_id, r.rubr_id, z.zona_codigo, c.clie_codigo, p.prod_codigo
END

GO
EXEC dbo.Fill_Fact;
GO

SELECT * FROM Fact_table;
GO

/* 6) Realizar un procedimiento que verifique si en alguna factura se facturaron componentes que
conforman un combo determinado (o sea que juntos componen otro producto de
mayor nivel), en cuyo caso se deberán reemplazar las filas correspondientes a dichos 
productos por una sola fila con el producto que componen con la cantidad de dicho
producto que corresponda. */

-- TYPE no se puede tirar SELECT, pensar workaround

/*
CREATE TYPE FacturaReducida AS TABLE
 (                     
    tipo char(1) NOT NULL,                
    sucursal char(4) NOT NULL,                
    numero char(8) NOT NULL,
    producto char(8) NOT NULL,
    cantidad decimal(12, 2) NOT NULL
 )
GO

IF OBJECT_ID('dbo.revisarFacturaCompuestos') IS NOT NULL
BEGIN
	DROP PROCEDURE dbo.revisarFacturaCompuestos;
END;
GO

CREATE PROCEDURE dbo.revisarFacturaCompuestos @factura FacturaReducida READONLY AS
	-- Recorrer la tabla intentando matchear contra los compuestos
	DECLARE @cantidad_necesaria decimal(12,2);
	DECLARE @componente char(8);
	DECLARE @compuesto char(8);
	DECLARE @cantidad_necesaria1 decimal(12,2);
	DECLARE @componente1 char(8);
	DECLARE @compuesto1 char(8);
	DECLARE composicion_curs CURSOR FOR (SELECT comp_cantidad, comp_producto, comp_componente FROM Composicion);
	
	OPEN composicion_curs;
	
	FETCH NEXT FROM composicion_curs INTO @cantidad_necesaria, @compuesto, @componente;
	WHILE @@FETCH_STATUS = 0
	BEGIN
		FETCH NEXT FROM composicion_curs INTO @cantidad_necesaria1, @compuesto1, @componente1
		-- Si ya el compuesto cambió, tengo que evaluar si la factura lo incluye y realizar las acciones
		-- ¿Cómo hago si el compuesto tiene más de dos componentes?
		IF @compuesto1 != @compuesto 
		BEGIN
			-- Si mi factura tiene los componentes necesarios y las cantidades, realizar el insert y los delete
			IF dbo.poseeCompuesto(@factura, @componente, @cantidad_necesaria, @componente1, @cantidad_necesaria1) = 1
			BEGIN
				DELETE FROM Item_Factura 
				WHERE item_tipo in (SELECT tipo FROM factura) AND
					  item_sucursal in (SELECT sucursal FROM factura) AND
					  item_numero in (SELECT numero FROM factura) AND
					  item_producto in (SELECT producto FROM factura)
				INSERT INTO Item_Factura VALUES (
				(SELECT TOP 1 tipo FROM factura), 
				(SELECT TOP 1 sucursal FROM factura),
				(SELECT TOP 1 numero FROM factura),
				@compuesto,
				1,
				(SELECT prod_precio FROM Producto WHERE prod_codigo = @compuesto))
			END
		END
	END
	
IF OBJECT_ID('dbo.reemplazarCombos') IS NOT NULL
BEGIN
	DROP PROCEDURE dbo.reemplazarCombos;
END;
GO

CREATE PROCEDURE dbo.reemplazarCombos AS
	-- Item_Factura agrupado por pk y lo meto en un cursor. Inserto en una temporal el resultado, y cuando
	-- cambio de factura lo mando a una función que updatee y deletee Item_Factura
	DECLARE @tipo char(1);
	DECLARE @sucursal char(4);
	DECLARE @numero char(8);
	DECLARE @producto char(8);
	DECLARE @cantidad decimal(12,2);
	DECLARE @tipo1 char(1);
	DECLARE @sucursal1 char(4);
	DECLARE @numero1 char(8);
	DECLARE @producto1 char(8);
	DECLARE @cantidad1 decimal(12,2);
	DECLARE @tmp AS FacturaReducida;
	DECLARE facturas_curs CURSOR FOR 
	(SELECT item_tipo, item_sucursal, item_numero, item_producto, item_cantidad 
	FROM Item_Factura);
	
	OPEN facturas_curs;
	
	FETCH NEXT FROM facturas_curs INTO @tipo, @sucursal, @numero, @producto, @cantidad;
	INSERT INTO @tmp VALUES (@tipo, @sucursal, @numero, @producto, @cantidad);
	
	WHILE @@FETCH_STATUS = 0
	BEGIN
		FETCH NEXT FROM facturas_curs INTO @tipo1, @sucursal1, @numero1, @producto1, @cantidad1;
		
		IF @tipo1 != @tipo OR @sucursal1 != @sucursal OR @numero1 != @numero 
		BEGIN 
			SET @tipo = @tipo1;
			SET @sucursal = @sucursal1 ;
			SET @numero = @numero1;
			EXEC dbo.revisarFacturaCompuestos tmp;
			DELETE FROM @tmp;
			INSERT INTO @tmp VALUES (@tipo, @sucursal, @numero, @producto1, @cantidad1);
		END
	END

	CLOSE facturas_curs;
	DEALLOCATE facturas_curs;*/

/* 7) Hacer un procedimiento que dadas dos fechas complete la tabla Ventas. Debe
insertar una línea por cada artículo con los movimientos de stock realizados entre
esas fechas. La tabla se encuentra creada y vacía.*/
IF OBJECT_ID('dbo.Ventas') IS NOT NULL
BEGIN
	DROP TABLE dbo.Ventas;
END;
GO

CREATE TABLE Ventas(
	codigo char(8),
	detalle char(50),
	movimientos decimal(12,2),
	precio decimal(12,2),
	renglon int,
	ganancia decimal(12,2)
)
GO

IF OBJECT_ID('dbo.ventasEntre') IS NOT NULL
BEGIN
	DROP PROCEDURE dbo.ventasEntre;
END;
GO


CREATE PROCEDURE dbo.ventasEntre @fecha1 char(10), @fecha2 char(10) AS
	DECLARE @f1 smalldatetime = CONVERT(smalldatetime, CONVERT(datetime, @fecha1))
	DECLARE @f2 smalldatetime = CONVERT(smalldatetime, CONVERT(datetime, @fecha2))
	DECLARE @codigo char(8)
	DECLARE @detalle char(50)
	DECLARE @movimientos decimal(12,2)
	DECLARE @precio decimal(12,2)
	DECLARE @renglon int
	DECLARE @ganancia decimal(12,2)
	DECLARE ventas_curs CURSOR FOR
	(SELECT p.prod_codigo as codigo,
	   p.prod_detalle as detalle,
	   SUM(i.item_cantidad) as movimientos,
	   AVG(i.item_precio) as precio,
	   ROW_NUMBER() OVER(ORDER BY i.item_producto ASC) as renglon,
	   SUM(i.item_precio) - (SUM(i.item_cantidad) * p.prod_precio) as ganancia
	FROM Item_Factura i
	INNER JOIN Factura f
	ON f.fact_numero = i.item_numero AND
	   f.fact_tipo = i.item_tipo AND
	   f.fact_sucursal = i.item_sucursal
	INNER JOIN Producto p
	ON p.prod_codigo = i.item_producto
	WHERE f.fact_fecha BETWEEN @f1 AND @f2
	GROUP BY p.prod_codigo, p.prod_detalle, p.prod_precio, i.item_producto)
	
	DELETE FROM Ventas
	
	OPEN ventas_curs
	
	FETCH NEXT FROM ventas_curs INTO @codigo, @detalle, @movimientos, @precio, @renglon, @ganancia
	
	WHILE @@FETCH_STATUS = 0
	BEGIN
		INSERT INTO Ventas VALUES (@codigo, @detalle, @movimientos, @precio, @renglon, @ganancia)
		FETCH NEXT FROM ventas_curs INTO @codigo, @detalle, @movimientos, @precio, @renglon, @ganancia
	END
	
	CLOSE ventas_curs
	DEALLOCATE ventas_curs
	
	SELECT * FROM Ventas
	
-- EXEC dbo.ventasEntre '2011-27-12', '2012-18-02'

/* 8) Realizar un procedimiento que complete la tabla Diferencias de precios, para los
productos facturados (que aparezcan en Item_Factura) que tengan composición y en los cuales el precio de
facturación sea diferente al precio del cálculo de los precios unitarios por cantidad
de sus componentes, se aclara que un producto que compone a otro, también puede
estar compuesto por otros y así sucesivamente, la tabla se debe crear y esta formada
por las siguientes columnas:*/	
IF OBJECT_ID('dbo.Diferencias') IS NOT NULL
BEGIN
	DROP TABLE dbo.Diferencias;
END;
GO

CREATE TABLE Diferencias(
	codigo char(8),
	detalle char(50),
	cant_componentes decimal(12,2),		-- COUNT(comp_componente) FROM Composicion WHERE comp_producto = compuesto
	precio_comp decimal(12, 2), -- SUM(prod_precio) WHERE comp_producto = compuesto
	precio_facturado decimal(12,2) -- AVG(item_precio)
)
GO

IF OBJECT_ID('dbo.PrecioUnitario') IS NOT NULL
BEGIN
	DROP FUNCTION dbo.PrecioUnitario;
END;
GO

CREATE FUNCTION dbo.PrecioUnitario(@compuesto char(8))
RETURNS decimal(12, 2) AS 
BEGIN
	DECLARE @precio decimal(12, 2) = 0.0
	DECLARE @componente char(8)
	DECLARE componentes CURSOR FOR (SELECT comp_componente FROM Composicion WHERE comp_producto = @compuesto)
	
	OPEN componentes
	FETCH NEXT FROM componentes INTO @componente
	
	WHILE @@FETCH_STATUS = 0
	BEGIN
		-- Si el componente es compuesto, volver a llamar recursivamente a la función
		IF (SELECT COUNT(*) FROM Composicion WHERE comp_producto = @componente) > 0 BEGIN
			SET @precio = @precio + dbo.PrecioUnitario(@componente)
		END
		ELSE BEGIN
			SET @precio = @precio + (SELECT prod_precio FROM Producto WHERE prod_codigo = @componente)
		END
		FETCH NEXT FROM componentes INTO @componente
	END
	
	CLOSE componentes
	DEALLOCATE componentes
	
	RETURN @precio
END

IF OBJECT_ID('dbo.Fill_Diferencias') IS NOT NULL
BEGIN
	DROP PROCEDURE dbo.Fill_Diferencias;
END;
GO

CREATE PROCEDURE dbo.Fill_Diferencias AS
	DECLARE @codigo char(8)
	DECLARE @detalle char(50)
	DECLARE @precioFact decimal(12, 2)
	-- Adentro de un cursor tengo los compuestos con el precio de facturacion
	DECLARE compFacturados_curs CURSOR FOR
	(SELECT p.prod_codigo, 
	        p.prod_detalle,
	        AVG(i.item_precio)
	FROM Item_Factura i
	INNER JOIN Producto p
	ON p.prod_codigo = i.item_producto
	INNER JOIN Composicion c
	ON c.comp_componente = p.prod_codigo OR c.comp_producto = p.prod_codigo
	WHERE item_producto in (SELECT DISTINCT comp_producto FROM Composicion)
	GROUP BY p.prod_codigo, p.prod_detalle)
	
	DELETE FROM Diferencias
	OPEN compFacturados_curs 
	
	FETCH NEXT FROM compFacturados_curs INTO @codigo, @detalle, @precioFact
	
	WHILE @@FETCH_STATUS = 0
	BEGIN
		INSERT INTO Diferencias VALUES 
		(@codigo, 
		 @detalle,
		 (SELECT SUM(comp_cantidad) FROM Composicion WHERE comp_producto = @codigo),
		 dbo.PrecioUnitario(@codigo),
		 @precioFact)
		 FETCH NEXT FROM compFacturados_curs INTO @codigo, @detalle, @precioFact
	END

	CLOSE compFacturados_curs
	DEALLOCATE compFacturados_curs
	
	SELECT * FROM Diferencias
	
-- EXEC dbo.Fill_Diferencias
	
/* 9)  Hacer un trigger que ante alguna modificación de un ítem que se encuentra en Item_Factura de un artículo
compuesto realice el movimiento de sus correspondientes componentes. */

-- El movimiento se va a hacer en el depósito del vendedor de la factura cuando se modifique
-- un compuesto y a su vez, la cantidad varíe. Si solo pasa eso, se efectivizará el movimiento.
IF OBJECT_ID('dbo.updateStockCompuesto') IS NOT NULL
BEGIN
	DROP PROCEDURE dbo.updateStockCompuesto;
END;
GO

CREATE PROCEDURE dbo.updateStockCompuesto @producto char(8), @deposito char(2), @diferencia decimal(12, 2) AS
	DECLARE @cantidad decimal(12,2)
	DECLARE @componente char(8)
	DECLARE componentes CURSOR FOR 
	(SELECT comp_cantidad, comp_componente 
	 FROM Composicion 
	 WHERE comp_producto = @producto)
	 
	 OPEN componentes
	 
	 FETCH NEXT FROM componentes INTO @cantidad, @componente
	 
	 WHILE @@FETCH_STATUS = 0
	 BEGIN
		-- Si la diferencia es mayor a 0, tenía más antes => Devuelvo la diferencia
		IF @diferencia > 0
		BEGIN
			UPDATE STOCK
			SET stoc_cantidad = stoc_cantidad + (@cantidad * @diferencia)
			WHERE stoc_producto = @componente AND stoc_deposito = @deposito
		END
		-- Sino resto la diferencia
		ELSE
		BEGIN
			UPDATE STOCK
			SET stoc_cantidad = stoc_cantidad - (@cantidad * @diferencia)
			WHERE stoc_producto = @componente AND stoc_deposito = @deposito
		END 
	 END
	 
	 

IF OBJECT_ID('dbo.updateStockCompuestos') IS NOT NULL
BEGIN
	DROP TRIGGER dbo.updateStockCompuestos;
END;
GO

CREATE TRIGGER dbo.updateStockCompuestos ON Item_Factura AFTER UPDATE 
AS BEGIN TRANSACTION
	-- Tengo que ir comparando uno por uno si en deleted cambió la cantidad respecto de inserted.
	-- Lo hago con dos cursores
	DECLARE @diferencia decimal(12,2)
	DECLARE @prodDel char(8)
	DECLARE @cantDel decimal(12,2)
	DECLARE @depoDel char(2)
	DECLARE @prodIns char(8)
	DECLARE @cantIns decimal(12,2)
	DECLARE @depoIns char(2)
	DECLARE deleted_curs CURSOR FOR
	(SELECT i.item_producto as compuesto,
		   SUM(i.item_cantidad) as cantidad,
		   d.depo_codigo as deposito
	FROM deleted i
	INNER JOIN Factura f
	ON f.fact_tipo = i.item_tipo AND
	   f.fact_sucursal = i.item_sucursal AND
	   f.fact_numero = i.item_numero
	INNER JOIN Empleado e
	ON e.empl_codigo = f.fact_vendedor
	INNER JOIN DEPOSITO d
	ON d.depo_codigo = e.empl_codigo
	INNER JOIN Producto p
	ON p.prod_codigo = i.item_producto
	INNER JOIN Composicion c
	ON p.prod_codigo = c.comp_producto
	GROUP BY d.depo_codigo, i.item_producto)
	
	DECLARE inserted_curs CURSOR FOR
	(SELECT i.item_producto as compuesto,
		   SUM(i.item_cantidad) as cantidad,
		   d.depo_codigo as deposito
	FROM inserted i
	INNER JOIN Factura f
	ON f.fact_tipo = i.item_tipo AND
	   f.fact_sucursal = i.item_sucursal AND
	   f.fact_numero = i.item_numero
	INNER JOIN Empleado e
	ON e.empl_codigo = f.fact_vendedor
	INNER JOIN DEPOSITO d
	ON d.depo_codigo = e.empl_codigo
	INNER JOIN Producto p
	ON p.prod_codigo = i.item_producto
	INNER JOIN Composicion c
	ON p.prod_codigo = c.comp_producto
	GROUP BY d.depo_codigo, i.item_producto)
	
	OPEN deleted_curs
	OPEN inserted_curs
	
	FETCH NEXT FROM deleted_curs INTO @prodDel, @cantDel, @depoDel
	FETCH NEXT FROM inserted_curs INTO @prodIns, @cantIns, @depoIns
	
	WHILE @@FETCH_STATUS = 0
	BEGIN
		-- Si la cantidad insertada es distinta de 0, obtener componentes y actualizar stock para el depósito
		SET @diferencia = @cantDel - @cantIns
		
		IF @diferencia != 0 BEGIN
			EXEC dbo.updateStockCompuesto @prodDel , @depoDel, @diferencia
		END
		
		-- No pasa nada si no tengo diferencias, solo se pide diferencias
		FETCH NEXT FROM deleted_curs INTO @prodDel, @cantDel, @depoDel
		FETCH NEXT FROM inserted_curs INTO @prodIns, @cantIns, @depoIns
	END
	
	CLOSE deleted_curs
	CLOSE inserted_curs
	DEALLOCATE deleted_curs
	DEALLOCATE inserted_curs
COMMIT
  
/* 10) Hacer un trigger que ante el intento de borrar un artículo verifique que no exista
stock. Si es así, borrar ese producto, en caso contrario que emita un mensaje de error. */

IF OBJECT_ID('dbo.verificarStock') IS NOT NULL
BEGIN
	DROP TRIGGER dbo.verificarStock;
END;
GO

CREATE TRIGGER dbo.verificarStock ON Producto INSTEAD OF DELETE 
AS BEGIN TRANSACTION
	-- No puedo hacer el caso individual, tengo que recorrer deleted entera
	DECLARE @codigo char(8)
	DECLARE del_curs CURSOR FOR (SELECT prod_codigo FROM DELETED)
	
	OPEN del_curs
	
	FETCH NEXT FROM del_curs INTO @codigo
	
	WHILE @@FETCH_STATUS = 0
	BEGIN
		IF EXISTS (SELECT 1 FROM STOCK WHERE stoc_producto = '00001707' AND stoc_cantidad > 0)
		BEGIN
			PRINT 'El producto con código' + @codigo + ' no puede eliminarse por haber stock exitente del mismo'
			ROLLBACK
		END
		ELSE BEGIN
			DELETE FROM Producto WHERE prod_codigo = @codigo
		END
	END
COMMIT

 /* 11) Cree el/los objetos de base de datos necesarios para que dado un código de
empleado se retorne la cantidad de empleados que este tiene a su cargo (directa o
indirectamente). Solo contar aquellos empleados (directos o indirectos) que sean
menores que su jefe directo. */

-- Esta es la función GET_EMPLEADOS con una condición por edad, bastaría comparar por fechas de nacimiento
IF OBJECT_ID('dbo.EmpleadosMenores') IS NOT NULL
BEGIN
	DROP FUNCTION dbo.EmpleadosMenores
END;
GO

CREATE FUNCTION dbo.EmpleadosMenores( @jefe numeric(6)) RETURNS INT
AS BEGIN
RETURN 0
END

GO

ALTER FUNCTION dbo.EmpleadosMenores (@jefe numeric(6)) RETURNS INT
BEGIN
	DECLARE @fechaNac smalldatetime = (SELECT empl_nacimiento FROM Empleado WHERE empl_codigo = @jefe)
	DECLARE @empleados int
	-- Si tiene a alguien a cargo (mínimo 1)
	IF EXISTS (SELECT 1 FROM Empleado WHERE empl_jefe = @jefe)
	BEGIN
		SELECT @empleados = (SELECT COUNT(*) + 
								(SELECT SUM(dbo.EmpleadosMenores(empl_codigo))
								 FROM Empleado 
								 WHERE empl_jefe = @jefe
								 GROUP BY empl_jefe)
							FROM Empleado WHERE empl_jefe = @jefe AND empl_nacimiento < @fechaNac) -- Solo jefe directo
	END
	ELSE BEGIN
		SELECT @empleados = 0
	END
	RETURN @empleados
END

GO
-- 12) Transact
IF OBJECT_ID('dbo.chk_empleados') IS NOT NULL
BEGIN
	ALTER TABLE Empleado DROP CONSTRAINT chk_empleados;
END;
GO

IF OBJECT_ID('dbo.CHECK_JEFES_OK') IS NOT NULL
BEGIN
	DROP FUNCTION dbo.CHECK_JEFES_OK;
END;
GO

IF OBJECT_ID('dbo.GET_EMPLEADOS') IS NOT NULL
BEGIN
	DROP FUNCTION dbo.GET_EMPLEADOS;
END;
GO
CREATE FUNCTION GET_EMPLEADOS(@cod_emp numeric(6)) RETURNS INT AS 
BEGIN
RETURN 0
END

GO

ALTER FUNCTION GET_EMPLEADOS(@cod_emp numeric(6)) RETURNS INT AS
BEGIN 
	declare @empleados int;
	--VEO SI TIENE AL MENOS UN EMPLEADO
	IF EXISTS ( SELECT 1 FROM Empleado WHERE empl_jefe = @cod_emp)
	BEGIN
		SELECT @empleados = 
			(SELECT COUNT(*) + 
				(SELECT SUM(DBO.GET_EMPLEADOS(empl_codigo)) 
					FROM Empleado WHERE empl_jefe = @cod_emp GROUP BY empl_jefe)
			FROM Empleado WHERE  empl_jefe = @cod_emp);
	END
	ELSE
	BEGIN
		SELECT @empleados = 0
	END
	RETURN @empleados
END
GO

CREATE FUNCTION CHECK_JEFES_OK(@jefe_id numeric(6)) RETURNS int AS
BEGIN
	RETURN 1
END
GO

ALTER FUNCTION CHECK_JEFES_OK(@jefe_id numeric(6)) RETURNS int AS
BEGIN
	DECLARE @result  int 
	set @result = 1
	IF (@jefe_id IS NOT NULL) 
	BEGIN
		if 
		(select  dbo.GET_EMPLEADOS(empl_codigo)  FROM Empleado WHERE empl_codigo = @jefe_id ) < 9 and  
		(SELECT dbo.CHECK_JEFES_OK(empl_jefe) FROM Empleado Where empl_codigo = @jefe_id) = 1 
		begin

		SELECT @result = 1

		END
		ELSE
		BEGIN
			SELECT @result = 0
		END
	END
	RETURN @result
END
GO

ALTER TABLE Empleado ADD CONSTRAINT chk_empleados CHECK (dbo.CHECK_JEFES_OK(empl_jefe) = 1)

/* 13) Cree el/los objetos de base de datos necesarios para que nunca un producto pueda
ser compuesto por sí mismo.
Se sabe que en la actualidad dicha regla se cumple y que la base de datos es
accedida por n aplicaciones de diferentes tipos y tecnologías.
No se conoce la cantidad de niveles de composición existentes. */

-- Trigger instead of insert o update
IF OBJECT_ID('dbo.checkCompuesto') IS NOT NULL
BEGIN
	DROP TRIGGER dbo.checkCompuesto;
END;
GO

CREATE TRIGGER dbo.checkCompuesto ON Composicion INSTEAD OF INSERT,UPDATE
AS BEGIN TRANSACTION
	-- El update o insert podría haber sido masivo
	
	-- Primero verificar si fue update o insert, de cualquiera de las dos formas inserted se va a usar
	DECLARE @cod_compuesto char(8)
	DECLARE @cod_componente char(8)
	DECLARE @cantidad_comp decimal(12, 2)
	DECLARE ins_curs CURSOR FOR (SELECT * FROM inserted)
	OPEN ins_curs
	
	IF (SELECT COUNT(*) FROM deleted) > 0 
	BEGIN -- update
		DECLARE @cod_compuesto_viejo char(8)
		DECLARE @cod_componente_viejo char(8)
		DECLARE @cantidad_comp_viejo decimal(12, 2)
		DECLARE del_curs CURSOR FOR (SELECT * FROM deleted)
		
		OPEN del_curs
		
		FETCH NEXT FROM del_curs INTO @cod_compuesto_viejo, @cod_componente_viejo, @cantidad_comp_viejo
		FETCH NEXT FROM ins_curs INTO @cod_compuesto, @cod_componente, @cantidad_comp
		
		WHILE @@FETCH_STATUS = 0
		BEGIN
		
			IF @cod_compuesto = @cod_componente
			
			BEGIN
				PRINT 'El producto está compuesto por sí mismo'
				ROLLBACK TRANSACTION
			END
			
			ELSE 
			BEGIN
				UPDATE Composicion 
				SET comp_producto = @cod_compuesto, 
					comp_componente = @cod_componente, 
					comp_cantidad = @cantidad_comp
			END
			
			FETCH NEXT FROM del_curs INTO @cod_compuesto_viejo, @cod_componente_viejo, @cantidad_comp_viejo
			FETCH NEXT FROM ins_curs INTO @cod_compuesto, @cod_componente, @cantidad_comp
		END
		
		CLOSE del_curs
		DEALLOCATE del_curs
	END
	ELSE -- insert
	BEGIN
		FETCH NEXT FROM ins_curs INTO @cod_compuesto, @cod_componente, @cantidad_comp
		
		WHILE @@FETCH_STATUS = 0
		BEGIN
		
			IF @cod_compuesto = @cod_componente
			
			BEGIN
				PRINT 'El producto está compuesto por sí mismo'
				ROLLBACK TRANSACTION
			END
			
			ELSE 
			BEGIN
				INSERT INTO Composicion VALUES (@cod_compuesto, @cod_componente, @cantidad_comp)
			END
			
			FETCH NEXT FROM ins_curs INTO @cod_compuesto, @cod_componente, @cantidad_comp
		END
	END
	
	CLOSE ins_curs
	DEALLOCATE ins_curs
COMMIT

/* 14) Cree el/los objetos de base de datos necesarios para implantar la siguiente regla
“Ningún jefe puede tener un salario mayor al 20% de las suma de los salarios de sus
empleados totales (directos + indirectos)”. Se sabe que en la actualidad dicha regla
se cumple y que la base de datos es accedida por n aplicaciones de diferentes tipos y
tecnologías */
IF OBJECT_ID('dbo.checkJefeSalario') IS NOT NULL
BEGIN
	DROP TRIGGER dbo.checkJefeSalario;
END;
GO

-- Hay que hacer un trigger que se fije con una función el salario de los jefes insertados o actualizados.
-- Rollbackear si no se cumple el constraint propuesto.

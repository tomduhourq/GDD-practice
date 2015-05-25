USE GESTION_1C2015;
-- 6) Para todos los rubros de artículos mostrar código, detalle, cantidad de artículos de
-- ese rubro y stock total de ese rubro. Solo tener en cuenta artículo con Stock > artículo
-- '00000000' en el depósito '00'
SELECT rubr_id, 
	   rubr_detalle, 
	   COUNT(DISTINCT prod_codigo) as 'Cantidad artículos en rubro',
	   SUM(stoc_cantidad) as 'Stock total del rubro'
FROM Rubro
INNER JOIN Producto
ON prod_rubro = rubr_id
INNER JOIN STOCK
ON stoc_producto = prod_codigo
WHERE stoc_cantidad > (SELECT SUM(stoc_cantidad) 
					   FROM STOCK 
					   WHERE stoc_producto = '00000000' AND
							 stoc_deposito = '00')
GROUP BY rubr_id, rubr_detalle;

-- 7) Para cada artículo código, detalle, mayor precio, menor precio, %diferencia de precios,
-- Mostrar solo aquellos artículos que posean stock.
-- Nota: saco los que tienen precio > 0.02 para que tenga un poco más de sentido.
SELECT prod_codigo, 
	   prod_detalle, 
	   (SELECT MAX(prod_precio) FROM Producto WHERE prod_precio > 0.02) as Máximo, 
	   (SELECT MIN(prod_precio) FROM Producto WHERE prod_precio > 0.02) as Mínimo,
	   (SELECT (MAX(prod_precio) / MIN(prod_precio)) * 100 FROM Producto WHERE prod_precio > 0.02) as Diferencia   
FROM Producto
INNER JOIN STOCK
ON stoc_producto = prod_codigo
WHERE stoc_cantidad > 0 AND 
	  prod_precio > 0.02
GROUP BY prod_codigo, prod_detalle; 

-- 8) Para el o los artículos que tengan stock en todos los depósitos mostrar detalle,
-- y stock del depósito que más stock tiene
-- Nota: no devuelve filas porque el WHERE no cumple nunca => No existe en la base
-- ningún artículo que tenga stock en todos los depósitos.
SELECT prod_detalle, 
	   MAX(stoc_cantidad)
FROM Producto
INNER JOIN STOCK
ON prod_codigo = stoc_producto
INNER JOIN DEPOSITO
ON depo_codigo = stoc_deposito
WHERE -- cantidad de depositos en donde aparece este artículo
	  (SELECT COUNT(*) FROM STOCK WHERE stoc_producto = prod_codigo)
	  =
	  -- Cantidad total de depósitos
	  (SELECT COUNT(*) FROM DEPOSITO)
GROUP BY prod_detalle;

-- 9) Mostrar código de jefe, código del empleado que lo tiene como jefe, nombre del mismo,
-- cantidad de depósitos que ambos tienen asignados
SELECT DISTINCT Jefe.empl_codigo as 'Jefe', 
				Emp.empl_codigo as 'Empleado', 
				Emp.empl_nombre + ' ' + Emp.empl_apellido as 'Nombre del empleado',
				(SELECT COUNT(*) FROM DEPOSITO WHERE depo_encargado = Jefe.empl_codigo) as 'Cantidad Depósitos Jefe',
				(SELECT COUNT(*) FROM DEPOSITO WHERE depo_encargado = Emp.empl_codigo) as 'Cantidad Depósitos Empleado' 
FROM Empleado Jefe
INNER JOIN Empleado Emp
ON Jefe.empl_codigo = Emp.empl_jefe;

-- 10) Mostrar los 10 productos más vendidos en la historia y también los 10 productos
-- menos vendidos en la historia. Además mostrar de esos productos, quien fue el
-- cliente que mayor compra realizó. 
-- NO SIRVE UNION PORQUE TENGO 1 SOLO ORDER BY PARA TODO EL QUERY, but ...
SELECT *
FROM (SELECT TOP 10
	  prod_codigo,
	  prod_detalle,
	  SUM(item_cantidad) as 'Total Ventas',
	   (SELECT TOP 1 clie_codigo FROM Cliente
	    INNER JOIN Factura 
	    ON clie_codigo = fact_cliente
	    INNER JOIN Item_Factura
	    ON fact_numero = item_numero AND
	    fact_sucursal = item_sucursal AND
	    fact_tipo = item_tipo
	    GROUP BY clie_codigo
	    ORDER BY SUM(item_cantidad) DESC) AS 'Cliente que más compró'
     FROM Producto
     INNER JOIN Item_Factura
     ON item_producto = prod_codigo
     GROUP BY prod_codigo, prod_detalle
     ORDER BY 3 DESC) as Top10
UNION
SELECT * FROM
	(SELECT TOP 10
	 prod_codigo,
	 prod_detalle,
	 SUM(item_cantidad) as 'Total ventas',
	 (SELECT TOP 1 clie_codigo FROM Cliente
	  INNER JOIN Factura 
	  ON clie_codigo = fact_cliente
	  INNER JOIN Item_Factura
	  ON fact_numero = item_numero AND
	  fact_sucursal = item_sucursal AND
	  fact_tipo = item_tipo
	  GROUP BY clie_codigo
	  ORDER BY SUM(item_cantidad) DESC) AS 'Cliente que más compró'
   FROM Producto
   INNER JOIN Item_Factura
   ON item_producto = prod_codigo
   GROUP BY prod_codigo, prod_detalle
   ORDER BY 3) as Worst10;

-- 11) Detalle flia, cantidad de diferentes productos vendidos (para esa familia), monto de las ventas sin imp.
-- ordenar de mayor a menor por familia que más productos diferentes vendidos tenga,
-- solo se deben mostrar las familias que tengan una venta superior a $20000 para el 2012
SELECT fami_detalle,
	  COUNT(DISTINCT item_producto) 
	  as 'Productos Diferentes vendidos',
	  SUM(fact_total - fact_total_impuestos)
	  as 'Monto de ventas sin impuestos'
FROM Familia
INNER JOIN Producto
ON prod_familia = fami_id
INNER JOIN Item_Factura
ON item_producto = prod_codigo
INNER JOIN Factura
ON fact_tipo = item_tipo AND
   fact_sucursal = item_sucursal AND
   fact_numero = item_numero
WHERE -- Total de ventas en el 2012 de esta familia > 20000 
(SELECT SUM(item_cantidad * item_precio) 
	   FROM Item_Factura
	   WHERE YEAR(fact_fecha) = 2012 AND
			 prod_familia = fami_id) > 20000
GROUP BY fami_detalle
ORDER BY 2 DESC;

-- 12) nombre de producto, cantidad de clientes distintos que lo compraron, importe promedio pagado por el producto,
-- cantidad de depósitos en los cuales hay stock de este producto, stock actual del producto en todos los depósitos.
-- Seleccionar aquellos que hayan tenido operaciones en el 2012 y ordenar de mayor a menor por monto vendido del producto.
SELECT prod_detalle,
	   COUNT(DISTINCT clie_codigo) as 'Clientes que compraron',
	   AVG(item_precio) as 'Promedio pagado',
	   COUNT(DISTINCT stoc_deposito) as 'Depósitos en los cuales hay stock',
	   SUM(stoc_cantidad) as 'Stock actual en todos los depósitos' 
FROM Producto
INNER JOIN STOCK
ON stoc_producto = prod_codigo
INNER JOIN Item_Factura
ON item_producto = prod_codigo
INNER JOIN Factura
ON fact_tipo = item_tipo AND
   fact_sucursal = item_sucursal AND
   fact_numero = item_numero
INNER JOIN Cliente
ON fact_cliente = clie_codigo
WHERE YEAR(fact_fecha) = 2012 and stoc_cantidad > 0
GROUP BY prod_detalle
ORDER BY SUM(item_cantidad * item_precio) DESC;

-- 13) para cada producto compuesto, nombre, precio, precio de la sumatoria del precio de cada producto que lo compone.
-- Mostrar solo los que estén compuestos por más de dos productos y ordenar desc por cantidad de productos que
-- lo componen. 
-- Preguntar ...
SELECT prod_detalle,
	   prod_precio,
	   (SELECT SUM(prod_precio) FROM Producto WHERE comp_componente = prod_codigo) as 'Precio por separado'
FROM Producto
INNER JOIN Composicion
ON comp_producto = prod_codigo
WHERE (SELECT SUM(comp_cantidad) FROM Composicion WHERE comp_producto = prod_codigo) > 2
GROUP BY prod_detalle, prod_precio, comp_cantidad, comp_componente
ORDER BY SUM(comp_cantidad) DESC;

-- 14) Estadística: código cliente, cantidad de veces que compró en el último año, promedio por compra en el último año,
-- Cantidad de productos diferentes en el último año, monto de la mayor compra que realizó en el último año,
-- Retornar todos los clientes ordenados por la cantidad de veces que compraron en el último año. Ningún null.
-- Resuelto en clase, no compila.
SELECT clie_codigo,
	   COUNT(*) as 'Cantidad de compras en el último año',
	   ISNULL(AVG(fact_total), 0) as 'Promedio en el último año',
	   (SELECT COUNT(DISTINCT item_producto)
	    FROM Factura
	    INNER JOIN Item_Factura
	    ON fact_cliente = clie_codigo AND
	    fact_numero = item_numero AND
	    fact_sucursal = item_sucursal AND
	    fact_tipo = item_tipo
	    WHERE YEAR(fact_fecha) = 
	    (SELECT ISNULL(MAX(YEAR(fact_fecha)), 0)
	     FROM Factura
	     WHERE fact_fecha = clie_codigo)) as 'Cantidad de productos distintos comprados en el último año',
	     ISNULL(MAX(fact_total), 0) as 'Máxima compra en el último año'
FROM Cliente
LEFT JOIN Factura
ON clie_codigo = fact_cliente
WHERE YEAR(fact_fecha) = 
	  (SELECT ISNULL(MAX(YEAR(fact_fecha)), 0)
	   FROM Factura
	   WHERE fact_fecha = clie_codigo)
GROUP BY clie_codigo
ORDER BY 2 DESC;
	  
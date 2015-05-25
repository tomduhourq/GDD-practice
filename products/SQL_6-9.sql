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



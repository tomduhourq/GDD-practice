USE GESTION_1C2015;
-- 6) Para todos los rubros de art�culos mostrar c�digo, detalle, cantidad de art�culos de
-- ese rubro y stock total de ese rubro. Solo tener en cuenta art�culo con Stock > art�culo
-- '00000000' en el dep�sito '00'
SELECT rubr_id, 
	   rubr_detalle, 
	   COUNT(DISTINCT prod_codigo) as 'Cantidad art�culos en rubro',
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

-- 7) Para cada art�culo c�digo, detalle, mayor precio, menor precio, %diferencia de precios,
-- Mostrar solo aquellos art�culos que posean stock.
-- Nota: saco los que tienen precio > 0.02 para que tenga un poco m�s de sentido.
SELECT prod_codigo, 
	   prod_detalle, 
	   (SELECT MAX(prod_precio) FROM Producto WHERE prod_precio > 0.02) as M�ximo, 
	   (SELECT MIN(prod_precio) FROM Producto WHERE prod_precio > 0.02) as M�nimo,
	   (SELECT (MAX(prod_precio) / MIN(prod_precio)) * 100 FROM Producto WHERE prod_precio > 0.02) as Diferencia   
FROM Producto
INNER JOIN STOCK
ON stoc_producto = prod_codigo
WHERE stoc_cantidad > 0 AND 
	  prod_precio > 0.02
GROUP BY prod_codigo, prod_detalle; 

-- 8) Para el o los art�culos que tengan stock en todos los dep�sitos mostrar detalle,
-- y stock del dep�sito que m�s stock tiene
-- Nota: no devuelve filas porque el WHERE no cumple nunca => No existe en la base
-- ning�n art�culo que tenga stock en todos los dep�sitos.
SELECT prod_detalle, 
	   MAX(stoc_cantidad)
FROM Producto
INNER JOIN STOCK
ON prod_codigo = stoc_producto
INNER JOIN DEPOSITO
ON depo_codigo = stoc_deposito
WHERE -- cantidad de depositos en donde aparece este art�culo
	  (SELECT COUNT(*) FROM STOCK WHERE stoc_producto = prod_codigo)
	  =
	  -- Cantidad total de dep�sitos
	  (SELECT COUNT(*) FROM DEPOSITO)
GROUP BY prod_detalle;

-- 9) Mostrar c�digo de jefe, c�digo del empleado que lo tiene como jefe, nombre del mismo,
-- cantidad de dep�sitos que ambos tienen asignados
SELECT DISTINCT Jefe.empl_codigo as 'Jefe', 
				Emp.empl_codigo as 'Empleado', 
				Emp.empl_nombre + ' ' + Emp.empl_apellido as 'Nombre del empleado',
				(SELECT COUNT(*) FROM DEPOSITO WHERE depo_encargado = Jefe.empl_codigo) as 'Cantidad Dep�sitos Jefe',
				(SELECT COUNT(*) FROM DEPOSITO WHERE depo_encargado = Emp.empl_codigo) as 'Cantidad Dep�sitos Empleado' 
FROM Empleado Jefe
INNER JOIN Empleado Emp
ON Jefe.empl_codigo = Emp.empl_jefe;



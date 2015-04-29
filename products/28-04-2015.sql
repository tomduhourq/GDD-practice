-- 1) Todos los empleados, sus tareas y fecha de ingreso a la empresa
SELECT empl_nombre, empl_tareas, empl_ingreso FROM Empleado;

-- 2) Listado anterior cuya tarea sea 'Vendedor'
SELECT empl_nombre, empl_ingreso FROM Empleado
WHERE empl_tareas = 'Vendedor';

-- 3) Productos cuyo precio supere los $6, ordenado por producto
SELECT prod_codigo, prod_detalle, prod_precio FROM Producto
WHERE prod_precio > 6
ORDER BY prod_codigo;

-- 4) Código del producto con detalle 'MERCADERIAS VARIAS' Y sus composiciones
SELECT * FROM Composicion
INNER JOIN Producto 
ON prod_codigo = comp_producto;

-- 5) Cantidad de productos que componen una familia y el precio máximo.
SELECT prod_familia, COUNT( prod_codigo ) as Cantidad, MAX( prod_precio ) 
FROM Producto
GROUP BY prod_familia;

-- 6) Códigos de productos distintos que se hayan vendido alguna vez ordenados desc.
SELECT DISTINCT prod_codigo FROM Producto P
INNER JOIN Item_Factura I
ON P.prod_codigo = I.item_producto
ORDER BY 1 DESC;

-- 7) Listar productos vendidos y cantidad vendida
SELECT item_producto, SUM( item_cantidad ) FROM Item_Factura
GROUP BY item_producto;

-- 8) Depósitos con más de 150 items en stock
SELECT stoc_deposito FROM STOCK
GROUP BY stoc_deposito
HAVING SUM( stoc_cantidad ) > 150;

-- 9) Cantidad ventas diarias (facturas emitidas en cada fecha) y el precio total promedio.
SELECT fact_fecha, COUNT(*) AS 'FACTURAS EMITIDAS', AVG( fact_total ) AS PROMEDIO FROM Factura
GROUP BY fact_fecha;

-- 10) Empleados según expertise
SELECT  empl_codigo,
		(CASE WHEN empl_salario < 8500 THEN 'JUNIOR'
			  WHEN empl_salario > 10000 THEN 'SENIOR'
			  ELSE 'SEMI SENIOR' END) AS EXPERTISE
FROM Empleado;

-- 11) Todos los empleados que sean jefe
SELECT (E1.empl_nombre + ' ' + E1.empl_apellido) AS 'NOMBRE Y APELLIDO'
FROM Empleado E1
LEFT JOIN Empleado E2
ON E1.empl_codigo = E2.empl_jefe;

-- 12) Cantidad de empleados que realizan la misma tarea con promedio de salario > 4500
SELECT empl_tareas, COUNT(empl_codigo) AS 'CANTIDAD' FROM Empleado
GROUP BY empl_tareas
HAVING AVG(empl_salario) > 4500;

-- 13) Monto máximo que abonó cada cliente en su compra, por vendedores 1,2,3,5,6
SELECT fact_cliente, MAX(fact_total) AS MAXIMO FROM Factura
WHERE fact_vendedor IN (1,2,3,5,6)
GROUP BY fact_cliente;

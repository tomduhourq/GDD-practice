-- 1) Mostrar el c�digo, raz�n social de todos los clientes cuyo l�mite de cr�dito sea
-- mayor o igual a $ 1000 ordenado por c�digo de cliente. 
SELECT clie_codigo, clie_razon_social FROM Cliente
WHERE clie_limite_credito >= 1000
ORDER BY 1;

-- 2) Mostrar el c�digo, detalle de todos los art�culos vendidos en el a�o 2012 ordenados
-- por cantidad vendida. SELECT prod_codigo, 	   prod_detalleFROM ProductoINNER JOIN Item_FacturaON item_producto = prod_codigoINNER JOIN FacturaON item_tipo = fact_tipo AND item_sucursal = fact_sucursal ANDitem_numero = fact_numeroWHERE YEAR(fact_fecha) = 2012GROUP BY prod_codigo, prod_detalle -- si no lo pongo, aparece el mismo item en dos facturas  ORDER BY SUM(item_cantidad);	   -- y me lo muestra, hay que explicitar la suma de de lo que quiero.-- 3) Realizar una consulta que muestre c�digo de producto, nombre de producto y el
-- stock total, sin importar en que deposito se encuentre, los datos deben ser ordenados
-- por nombre del art�culo de menor a mayor. 
SELECT prod_codigo, 
	   prod_detalle,
	   CONVERT(NUMERIC, SUM(stoc_cantidad)) AS 'Cantidad entre dep�sitos' 
FROM Producto
INNER JOIN STOCK
ON stoc_producto = prod_codigo
GROUP BY prod_codigo, prod_detalle
ORDER BY prod_detalle DESC;

-- 4) Realizar una consulta que muestre para todos los art�culos c�digo, detalle y cantidad
-- de art�culos que lo componen. Mostrar solo aquellos art�culos para los cuales el
-- stock promedio por dep�sito sea mayor a 100. 
SELECT stoc_producto, 
	   prod_detalle, 
	   (SELECT COUNT(*) FROM Composicion WHERE stoc_producto = comp_componente) as 'Cantidad Componentes',
	   SUM(stoc_cantidad)
FROM Producto
INNER JOIN STOCK
ON stoc_producto = prod_codigo
GROUP BY stoc_producto, prod_detalle
HAVING AVG(stoc_cantidad) > 100;

-- 5) Realizar una consulta que muestre c�digo de art�culo, detalle y cantidad de egresos
-- de stock que se realizaron para ese art�culo en el a�o 2012 (egresan los productos
-- que fueron vendidos). Mostrar solo aquellos que hayan tenido m�s egresos que en el 2011.
 SELECT prod_codigo, 
		prod_detalle, 
		SUM(item_cantidad) as 'Cantidad vendida en 2012'
 FROM Producto
 INNER JOIN Item_Factura
 ON item_producto = prod_codigo
 INNER JOIN Factura
 ON item_tipo = fact_tipo AND 
 item_numero = fact_numero AND
 item_sucursal = fact_sucursal
 WHERE YEAR(fact_fecha) = 2012
 GROUP BY prod_codigo, prod_detalle
-- Falta el having

-- 10) Mostrar los 10 productos m�s vendidos en la historia y tambi�n los 10 productos
-- menos vendidos en la historia. Adem�s mostrar de esos productos, quien fue el
-- cliente que mayor compra realiz�. 
-- NO SIRVE UNION PORQUE TENGO 1 SOLO ORDER BY PARA TODO EL QUERY.
SELECT TOP 10
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
	 ORDER BY SUM(item_cantidad) DESC) AS 'Cliente que m�s compr�'
FROM Producto
INNER JOIN Item_Factura
ON item_producto = prod_codigo
GROUP BY prod_codigo, prod_detalle
ORDER BY 3 DESC;

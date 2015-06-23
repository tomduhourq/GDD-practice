/* Se ha detectado que existen productos cargados con rubro erróneo.
Para todos los productos: codigo, detalle, codigo rubro, detalle rubro, codigo rubro sugerido, detalle rubro sugerido
El rubro sugerido para un producto es el que posee la mayoría (qué carajo es la mayoría?) de los productos cuyo detalle
coincide en los primeros 10 caracteres.
En caso de que 2 o más rubros queden, deberá ser seleccionado el de menor código 

Solo mostrar los que el rubro sugerido es distinto del sugerido ordenado por detalle
*/
SELECT prod_codigo, 
	   prod_detalle,
	   rubr_id,
	   rubr_detalle, 
	   (SELECT TOP 1 rubr_id 
		FROM Rubro 
		WHERE LEFT(prod_detalle, 10) = LEFT(rubr_detalle,10) 
		ORDER BY rubr_id) as codigo_sugerido,
	   (SELECT TOP 1 rubr_detalle 
	    FROM Rubro 
	    WHERE LEFT(prod_detalle, 10) = LEFT(rubr_detalle,10) 
	    ORDER BY rubr_id) as detalle_sugerido
FROM Producto 
INNER JOIN Rubro
ON rubr_id = prod_codigo
WHERE rubr_id != (SELECT TOP 1 rubr_id 
				  FROM Rubro 
				  WHERE LEFT(prod_detalle, 10) = LEFT(rubr_detalle,10) 
				  ORDER BY rubr_id)
GROUP BY prod_codigo, prod_detalle, rubr_id, rubr_detalle
ORDER BY prod_detalle ASC


SELECT P.prod_codigo PROD_COD, P.prod_detalle PROD_DET, F.rubr_id rub_COD_ACT, F.rubr_detalle rub_DET_ACT,
(
SELECT TOP 1  F2.rubr_id
FROM Producto P2 LEFT JOIN Rubro F2 ON (P2.prod_rubro=F2.rubr_id)
WHERE LEFT(P2.prod_detalle,10) = LEFT(P.prod_detalle,10)
GROUP BY F2.rubr_id, F2.rubr_detalle
ORDER BY COUNT(*) DESC, F2.rubr_id -- El COUNT(*) es el 'la mayoría'
) rub_COD_SUG,
(
SELECT TOP 1  F2.rubr_detalle
FROM Producto P2 LEFT JOIN Rubro F2 ON (P2.prod_rubro=F2.rubr_id)
WHERE LEFT(P2.prod_detalle,10) = LEFT(P.prod_detalle,10)
GROUP BY F2.rubr_id, F2.rubr_detalle
ORDER BY COUNT(*) DESC, F2.rubr_id
)rub_DET_SUG
FROM Producto P LEFT JOIN Rubro F ON (P.prod_rubro=F.rubr_id)
WHERE P.prod_rubro <>
(
SELECT TOP 1  F2.rubr_id
FROM Producto P2 LEFT JOIN Rubro F2 ON (P2.prod_rubro=F2.rubr_id)
WHERE LEFT(P2.prod_detalle,10) = LEFT(P.prod_detalle,10)
GROUP BY F2.rubr_id, F2.rubr_detalle
ORDER BY COUNT(*) DESC, F2.rubr_id
)
ORDER BY P.prod_detalle asc
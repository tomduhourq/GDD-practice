-- QUANTITY OF BOOKS OF EACH EDITORIAL
SELECT EDITORIAL, COUNT(*) AS 'QUANTITY'
FROM BOOKS
GROUP BY EDITORIAL

-- QUANTITY OF BOOKS GROUPED BY EDITORIAL WITH NOT NULL PRICE
SELECT EDITORIAL, COUNT(PRICE) AS 'QUANTITY'
FROM BOOKS
WHERE PRICE IS NOT NULL
GROUP BY EDITORIAL

-- GROUP BY EDITORIAL WITH MORE THAN TWO BOOKS
SELECT COUNT(*) 'QUANTITY', EDITORIAL
FROM BOOKS
GROUP BY EDITORIAL
HAVING COUNT(*) > 2

-- EDITORIALS WHICH AVG PRICE IS > 25
SELECT EDITORIAL, AVG(PRICE) AS 'AVERAGE PRICE'
FROM BOOKS
GROUP BY EDITORIAL
HAVING AVG(PRICE) > 25

-- 2 APPROACHES TO GETTING ALL EDITORIALS WITHOUT 'KAPELUSZ'
-- FIRST FILTER THEN GROUP
SELECT EDITORIAL, COUNT(*) 'BOOKS'
FROM BOOKS
WHERE EDITORIAL <> 'KAPELUSZ'
GROUP BY EDITORIAL

-- FIRST GROUP THEN FILTER
SELECT EDITORIAL, COUNT(*) 'BOOKS'
FROM BOOKS
GROUP BY EDITORIAL
HAVING EDITORIAL <> 'KAPELUSZ'

-- QUANTITY OF BOOKS WITH PRICE > 50 AND EDITORIAL SHOULD HAVE MORE THAN 2 BOOKS
SELECT COUNT(*) 'QUANTITY', EDITORIAL
FROM BOOKS
WHERE PRICE > 50
GROUP BY EDITORIAL
HAVING COUNT(*) > 2

-- MAX VALUE OF A BOOK FROM EACH EDITORIAL AND PRICE SHOULD BE <= 1000 AND >= 190
SELECT MAX(PRICE) 'MAX PRICE IN RANGE', EDITORIAL
FROM BOOKS
WHERE PRICE BETWEEN 190 AND 1000
GROUP BY EDITORIAL

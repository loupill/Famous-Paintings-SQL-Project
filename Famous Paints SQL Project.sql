--Fetch all the paintings which are not displayed on any museums?
SELECT name
FROM dbo.work
WHERE museum_id IS NULL


-- Are there any mueseums without paintings
SELECT * 
FROM dbo.museum m
WHERE NOT EXISTS (
SELECT *
FROM work w
WHERE w.museum_id=m.museum_id)


-- How many paintings have an asking price of more than their regular price?
SELECT *
FROM dbo.product_size
WHERE sale_price > regular_price


-- Identify the paintings whose asking price is less than 50% of its regular price
SELECT *
FROM dbo.product_size
WHERE sale_price < (regular_price * 0.5)


-- Which canvas size costs the most?
SELECT f.size_id, f.sale_price
FROM (SELECT p.sale_price, c.size_id,
		RANK() OVER(ORDER BY p.sale_price DESC) as rnk
		FROM dbo.canvas_size c
		JOIN dbo.product_size p
		ON c.size_id = p.size_id) as f
WHERE rnk = 1


-- Identify the museums with invalid city information in the given dataset
SELECT *
FROM museum
WHERE city like '%[0-9]%'


-- Fetch the top 10 most famous painting subject
SELECT TOP 10 *
FROM (
	SELECT s.subject, count(s.subject) as 'no_paintings',
	RANK() OVER(ORDER BY count(s.subject) DESC)  as "rank"
	FROM work w
	JOIN subject s 
	ON s.work_id = w.work_id
	group by s.subject
	) x 
WHERE "rank" < 10


--Identify the museums which are open on both Sunday and Monday. Display museum name, city.
SELECT m.name, m.city
FROM museum m
JOIN museum_hours mh
ON m.museum_id = mh.museum_id
WHERE day = 'Sunday'
AND EXISTS (SELECT mh2.museum_id
			FROM museum_hours mh2
			WHERE mh2.museum_id = mh.museum_id
			AND mh2.day = 'Monday')
-- Exist clause is checking if there if the ID being returned from the subquery (looking for mondays) that also exists in the outer query (looking for sundays)


-- How many museums are open every single day?
SELECT COUNT(museum_id)
FROM (SELECT museum_id, count(1) as 'day_cnt'
		FROM museum_hours
		GROUP BY museum_id
		HAVING count(1) >= 7
) x;


-- Which are the top 5 most popular museum? (Popularity is defined based on most no of paintings in a museum)
SELECT TOP 5 *
FROM (
	SELECT m.name, COUNT(1) as 'Cnt_work_per_mus'
	FROM work w 
	JOIN museum m 
	ON m.museum_id = w.museum_id
	WHERE w.museum_id IS NOT NULL
	GROUP BY m.name
	) x
ORDER BY 'Cnt_work_per_mus' DESC


-- Who are the top 5 most popular artist? (Popularity is defined based on most no of paintings done by an artist)
SELECT j.full_name , j.rnk, j.cnt_works
FROM
	(SELECT a.full_name, a.artist_id, COUNT(w.work_id) as 'cnt_works',
	RANK() OVER(ORDER BY COUNT(w.work_id) DESC) as "rnk"
	FROM dbo.work w
	JOIN artist a
	ON a.artist_id = w.artist_id
	GROUP BY a.artist_id, a.full_name) j
WHERE rnk <= 5
ORDER BY rnk ASC


-- Display the 3 least popular canva sizes
SELECT cs.label, cs.cnt_works, cs.rnk
FROM
	(SELECT c.label, c.size_id, COUNT(p.work_id) as "cnt_works",
	DENSE_RANK() OVER(ORDER BY COUNT(p.work_id)) as "rnk"
	FROM product_size p
	JOIN canvas_size c
	ON p.size_id = c.size_id
	GROUP BY c.size_id, c.label) cs
WHERE cs.rnk <= 3
ORDER BY cs.rnk ASC


-- Which museum is open for the longest during a day. Dispay museum name, hours open and which day?
SELECT x.name, x."day", x."Hours_open", x.rnk
FROM 
	(SELECT m.name, h."day",
	DATEDIFF(SECOND, CAST(h."open" AS DATETIME), CAST(h."close" AS DATETIME)) AS "Hours_open",
	RANK() OVER(ORDER BY DATEDIFF(SECOND, CAST(h."close" AS DATETIME), CAST(h."open" AS DATETIME))) AS "rnk"
	FROM dbo.museum m
	JOIN dbo.museum_hours h
	ON m.museum_id = h.museum_id) as x
WHERE "rnk" = 1


-- Which museum has the most no of most popular painting style?
WITH PopStyle AS (
	SELECT
		COUNT(work_id) as cnt_work,
		style,
		RANK() OVER (ORDER BY COUNT(work_id) DESC) as pop_rnk
	FROM 
		work
	GROUP BY 
		style
)
SELECT
	m.name,
	COUNT(w.work_id), 
	w.style
FROM work w
JOIN museum m
	ON m.museum_id = w.museum_id
JOIN PopStyle ps
	ON ps.style = w.style
GROUP BY m.name, w.style
ORDER BY COUNT(w.work_id) DESC


-- Identify the artists whose paintings are displayed in multiple countries
WITH Artist_number_of_countries AS (
	SELECT DISTINCT a.full_name, m.country
	FROM artist a
	JOIN work w
	ON a.artist_id = w.artist_id
	JOIN museum m
	ON m.museum_id = w.museum_id
	)
SELECT full_name, COUNT(full_name)
FROM Artist_number_of_countries
GROUP BY full_name
HAVING COUNT(full_name) > 1


--Display the country and the city with most no of museums. Output 2 seperate columns to mention the city and country. 
WITH Country_cte AS (
		SELECT country, count(1) as cnt_country,
		RANK() OVER(ORDER BY COUNT(1) DESC) as country_rnk
		FROM museum
		GROUP BY country
		),
	City_cte as (
		SELECT city, count(1) as cnt_city,
		RANK() OVER(ORDER BY COUNT(1) DESC) as city_rnk
		FROM museum
		GROUP BY city)
SELECT country, city 
FROM Country_cte
CROSS JOIN City_cte
WHERE country_rnk = 1
AND city_rnk = 1
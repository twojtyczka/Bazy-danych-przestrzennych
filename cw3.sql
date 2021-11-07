-- 3. Zaimportuj pliki shapefile do bazy danych wykorzystując wtyczkę PostGIS DBF Loader.

CREATE EXTENSION postgis;

-- 4. Wyznacz liczbę budynków (tabela: popp, atrybut: f_codedesc, reprezentowane, jako punkty) położonych w odległości mniejszej niż 1000 m od głównych rzek. Budynki spełniające to kryterium zapisz do osobnej tabeli tableB.

SELECT COUNT(popp) FROM popp, majrivers WHERE popp.f_codedesc = 'Building' AND ST_Distance(popp.geom, majrivers.geom) < 1000;
SELECT popp.* INTO tableB FROM popp, majrivers WHERE popp.f_codedesc = 'Building' AND ST_Distance(popp.geom, majrivers.geom) < 1000;
SELECT * from tableB;

-- 5. Utwórz tabelę o nazwie airportsNew. Z tabeli airports do zaimportuj nazwy lotnisk, ich geometrię, a także atrybut elev, reprezentujący wysokość n.p.m.

SELECT name, elev, geom INTO airportsNew FROM airports;

-- a) Znajdź lotnisko, które położone jest najbardziej na zachód i najbardziej na wschód.  

-- najbardziej oddalone na zachód

SELECT name,ST_X(geom) from airportsNew 
ORDER BY ST_X(geom) ASC LIMIT 1;

-- najbardziej oddalone na wschód

SELECT name, ST_X(geom) FROM airportsNew
ORDER BY ST_X(geom) DESC LIMIT 1;

-- b) Do tabeli airportsNew dodaj nowy obiekt - lotnisko, które położone jest w punkcie środkowym drogi pomiędzy lotniskami znalezionymi w punkcie a. Lotnisko nazwij airportB. Wysokość n.p.m. przyjmij dowolną.
-- Uwaga: geodezyjny układ współrzędnych prostokątnych płaskich (x – oś pionowa, y – oś pozioma)

INSERT INTO airportsNew(name,elev,geom) VALUES
	('airportB', 200,(SELECT ST_Centroid(ST_ShortestLine(
		(SELECT geom FROM airportsNew WHERE name = 'ANNETTE ISLAND'), 
		(SELECT geom FROM airportsNew WHERE name = 'ATKA'))))
	);

SELECT * FROM airportsNew;

-- 6. Wyznacz pole powierzchni obszaru, który oddalony jest mniej niż 1000 jednostek od najkrótszej linii łączącej jezioro o nazwie ‘Iliamna Lake’ i lotnisko o nazwie „AMBLER”

SELECT ST_Area(ST_Buffer(ST_ShortestLine(airports.geom, lakes.geom), 1000)) FROM airports, lakes
WHERE lakes.names='Iliamna Lake' AND airports.name='AMBLER';

-- 7.	Napisz zapytanie, które zwróci sumaryczne pole powierzchni poligonów reprezentujących poszczególne typy drzew znajdujących się na obszarze tundry i bagien (swamps).

SELECT SUM(ST_Area(trees.geom)), trees.vegdesc FROM trees, tundra, swamp 
WHERE ST_Contains(tundra.geom, trees.geom) OR ST_Contains(swamp.geom, trees.geom) 
GROUP BY trees.vegdesc;
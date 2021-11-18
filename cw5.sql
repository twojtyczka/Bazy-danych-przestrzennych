-- Utwórz tabelę obiekty. W tabeli umieść nazwy i geometrie obiektów przedstawionych poniżej. Układ odniesienia ustal jako niezdefiniowany.

CREATE EXTENSION postgis;

CREATE TABLE obiekty (
    id INT PRIMARY KEY,
	name VARCHAR(30),
    geometry GEOMETRY
)

INSERT INTO obiekty VALUES
	(1, 'obiekt1', ST_GeomFromText('MULTICURVE((0 1, 1 1), CIRCULARSTRING(1 1, 2 0, 3 1), CIRCULARSTRING(3 1, 4 2, 5 1), (5 1, 6 1))'));

INSERT INTO obiekty VALUES
	(2, 'obiekt2', ST_GeomFromText('CURVEPOLYGON(COMPOUNDCURVE((10 6, 14 6), CIRCULARSTRING(14 6, 16 4, 14 2), CIRCULARSTRING(14 2, 12 0, 10 2), (10 2, 10 6)), CIRCULARSTRING(11 2, 13 2, 11 2))'));
	
INSERT INTO obiekty VALUES
	(3, 'obiekt3', ST_GeomFromText('POLYGON((7 15, 10 17, 12 13, 7 15))'));
	
INSERT INTO obiekty VALUES
	(4, 'obiekt4', ST_GeomFromText('LINESTRING(20 20, 25 25, 27 24, 25 22, 26 21, 22 19, 20.5 19.5)'));
	
INSERT INTO obiekty VALUES
	(5, 'obiekt5', ST_GeomFromText('MULTIPOINT(30 30 59, 38 32 234)'));
	
INSERT INTO obiekty VALUES
	(6, 'obiekt5', ST_GeomFromText('GEOMETRYCOLLECTION(LINESTRING(1 1,3 2), POINT(4 2))'));
	
-- 1. Wyznacz pole powierzchni bufora o wielkości 5 jednostek, który został utworzony wokół najkrótszej linii łączącej obiekt 3 i 4.

SELECT ST_Area(ST_Buffer(ST_ShortestLine((SELECT geometry FROM obiekty WHERE name = 'obiekt3'), (SELECT geometry FROM obiekty WHERE name = 'obiekt4')), 5));

-- 2. Zamień obiekt4 na poligon. Jaki warunek musi być spełniony, aby można było wykonać to zadanie? Zapewnij te warunki.

-- Wszystkie linestringi w tabeli muszą być zamknięte poprzez dodanie punktu.

SELECT ST_GeometryType(ST_LineMerge(ST_CurveToLine(geometry))) FROM obiekty WHERE name = 'obiekt4';

SELECT ST_AddPoint(ST_LineMerge(ST_CurveToLine(geometry)), ST_StartPoint(ST_LineMerge(ST_CurveToLine(geometry)))) FROM obiekty WHERE name = 'obiekt4';

SELECT ST_MakePolygon(ST_AddPoint(ST_LineMerge(ST_CurveToLine(geometry)), ST_StartPoint(ST_LineMerge(ST_CurveToLine(geometry))))) FROM obiekty WHERE name = 'obiekt4';

-- 3. W tabeli obiekty, jako obiekt7 zapisz obiekt złożony z obiektu 3 i obiektu 4.

INSERT INTO obiekty VALUES
	(7, 'obiekt7', ST_Collect((SELECT geometry FROM obiekty WHERE name = 'obiekt3'), (SELECT geometry FROM obiekty WHERE name = 'obiekt4')));
	
-- 4.  Wyznacz pole powierzchni wszystkich buforów o wielkości 5 jednostek, które zostały utworzone wokół obiektów nie zawierających łuków.

SELECT ST_Area(ST_Buffer(geometry, 5)) FROM obiekty WHERE NOT ST_HasArc(geometry);

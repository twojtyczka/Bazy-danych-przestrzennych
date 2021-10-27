-- 3. Dodaj funkcjonalności PostGIS’a do bazy poleceniem CREATE EXTENSION postgis;

CREATE EXTENSION postgis;

-- 4. Na podstawie poniższej mapy utwórz trzy tabele: buildings (id, geometry, name), roads (id, geometry, name), poi (id, geometry, name).

CREATE TABLE buildings(id int PRIMARY KEY NOT NULL, geometry GEOMETRY, name VARCHAR(30));
CREATE TABLE roads(id int PRIMARY KEY NOT NULL, geometry GEOMETRY, name VARCHAR(30));
CREATE TABLE poi(id int PRIMARY KEY NOT NULL, geometry GEOMETRY, name VARCHAR(30));

-- 5. Współrzędne obiektów oraz nazwy (np. BuildingA) należy odczytać z mapki umieszczonej poniżej. Układ współrzędnych ustaw jako niezdefiniowany.

INSERT INTO buildings VALUES
	(1, ST_GeomFromText('POLYGON((8 4, 10.5 4, 10.5 1.5, 8 1.5, 8 4))', 0), 'BuildingA'),
 	(2, ST_GeomFromText('POLYGON((4 7, 6 7, 6 5, 4 5, 4 7))', 0), 'BuildingB'),
 	(3, ST_GeomFromText('POLYGON((3 8, 5 8, 5 6, 3 6, 3 8))', 0), 'BuildingC'),
 	(4, ST_GeomFromText('POLYGON((9 9, 10 9, 10 8, 9 8, 9 9))', 0), 'BuildingD'),
 	(5, ST_GeomFromText('POLYGON((1 2, 2 2, 2 1, 1 1, 1 2))', 0), 'BuildingF');
	
INSERT INTO roads VALUES
	(1, ST_GeomFromText('LINESTRING(0 4.5, 12 4.5)', 0), 'RoadX'),
	(2, ST_GeomFromText('LINESTRING(7.5 0, 7.5 10.5)', 0), 'RoadY');
	
INSERT INTO poi VALUES
 	(1, ST_GeomFromText('POINT(1 3.5)', 0), 'G'),
  	(2, ST_GeomFromText('POINT(5.5 1.5)', 0), 'H'),
  	(3, ST_GeomFromText('POINT(9.5 6)', 0), 'I'),
  	(4, ST_GeomFromText('POINT(6.5 6)', 0), 'J'),
  	(5, ST_GeomFromText('POINT(6 9.5)', 0), 'K');
	
-- 6. Na bazie przygotowanych tabel wykonaj poniższe polecenia:

-- a) Wyznacz całkowitą długość dróg w analizowanym mieście.

SELECT SUM(ST_Length(geometry)) FROM roads;

-- b) Wypisz geometrię (WKT), pole powierzchni oraz obwód poligonu reprezentującego budynek o nazwie BuildingA.

SELECT ST_AsText(geometry), ST_Area(geometry), ST_Perimeter(geometry)  FROM buildings WHERE name = 'BuildingA';

-- c) Wypisz nazwy i pola powierzchni wszystkich poligonów w warstwie budynki. Wyniki posortuj alfabetycznie.

SELECT name, ST_Area(geometry) FROM buildings ORDER BY name;

-- d) Wypisz nazwy i obwody 2 budynków o największej powierzchni.

SELECT name, ST_Perimeter(geometry) FROM buildings ORDER BY ST_Area(geometry) DESC LIMIT 2;

-- e) Wyznacz najkrótszą odległość między budynkiem BuildingC a punktem G.

SELECT ST_Distance(buildings.geometry, poi.geometry) FROM buildings, poi WHERE buildings.name = 'BuildingC' AND poi.name = 'G';

-- f) Wypisz pole powierzchni tej części budynku BuildingC, która znajduje się w odległości większej niż 0.5 od budynku BuildingB.

SELECT ST_Area(ST_Difference((SELECT geometry FROM buildings WHERE name = 'BuildingC'), ST_Buffer(geometry, 0.5))) FROM buildings WHERE name = 'BuildingB';

-- g) Wybierz te budynki, których centroid (ST_Centroid) znajduje się powyżej drogi o nazwie RoadX.

SELECT buildings.name FROM buildings, roads WHERE ST_Y(ST_Centroid(buildings.geometry)) > ST_Y(ST_Centroid(roads.geometry)) AND roads.name = 'RoadX';

-- h) Oblicz pole powierzchni tych części budynku BuildingC i poligonu o współrzędnych (4 7, 6 7, 6 8, 4 8, 4 7), które nie są wspólne dla tych dwóch obiektów.

SELECT ST_Area(ST_SymDifference(ST_GeomFromText('POLYGON((4 7, 6 7, 6 8, 4 8, 4 7))'), geometry)) FROM buildings WHERE name = 'BuildingC';


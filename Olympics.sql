CREATE TABLE olympics(
id VARCHAR,
Name VARCHAR,
Sex CHAR,
Age VARCHAR,
Height VARCHAR,
Weight VARCHAR,
Team VARCHAR,
NOC VARCHAR,
Games VARCHAR,
Year VARCHAR,
Season VARCHAR,
City VARCHAR,
Sport VARCHAR,
Event VARCHAR,
Medal VARCHAR
)

COPY olympics
FROM 'G:\pgAdmin 4\v5\athlete_events.csv'
DELIMITER ','
CSV HEADER

SELECT * FROM olympics

--Which Athlete has won most medals till date
SELECT Name,Medal,COUNT(Medal) AS Total_Medals,Sport,Team FROM olympics
WHERE (Medal='Gold') OR (Medal='Silver') OR (Medal='Bronze')
GROUP BY Name,Medal,Team,Sport,Team
ORDER BY 3 DESC

--Which Country has won most medals till date
SELECT Team, COUNT(Medal) AS Total_Medals FROM olympics
WHERE ((Medal='Gold') OR (Medal='Silver') OR (Medal='Bronze'))
GROUP BY Team
ORDER BY 2 DESC

--Finding Duplicates
SELECT Name,Year,Event,COUNT(Event),Medal,Season,Games FROM olympics
WHERE ((Medal='Gold') OR (Medal='Silver') OR (Medal='Bronze'))
GROUP BY Name,Year,Event,Medal,Season,Games
HAVING (COUNT(Event)>1)
ORDER BY 3 DESC
--Deleting Duplicates
DELETE FROM olympics
WHERE id IN
    (SELECT id
    FROM 
        (SELECT id,
         ROW_NUMBER() OVER( PARTITION BY Event,Name,Year
        ORDER BY  Year ) AS row_num
        FROM olympics ) t
        WHERE t.row_num > 1 );

--Which athlete has won the most 'Gold' medals in various games
SELECT Name,Team, COUNT(Medal) FROM olympics
WHERE (Medal='Gold')
GROUP BY Name,Team
ORDER BY 3 DESC

SELECT DISTINCT (Sport),Name,Team,COUNT(Medal) AS cnt FROM olympics
WHERE (Medal='Gold') 
GROUP BY Team,Sport,Name
ORDER BY 4 DESC

DROP TABLE IF EXISTS Top;
CREATE TABLE Top(
Sport VARCHAR,
Name VARCHAR,
Team VARCHAR,
cnt INT
);
INSERT INTO Top(
SELECT DISTINCT (Sport),Name,Team,COUNT(Medal) AS cnt FROM olympics
WHERE (Medal='Gold') 
GROUP BY Team,Sport,Name
ORDER BY 4 DESC
);
SELECT DISTINCT ON (Sport)
Sport,Team,cnt  
FROM   Top
ORDER  BY Sport,cnt DESC;

-- Which Country has the highest Number of Total medals in various games
DROP TABLE IF EXISTS Top1;
CREATE TABLE Top1(
Sport VARCHAR,
Name VARCHAR,
Team VARCHAR,
cnt INT
);
INSERT INTO Top1(
SELECT DISTINCT (Sport),Name,Team,COUNT(Medal) AS cnt FROM olympics
WHERE ((Medal='Gold') OR (Medal='Silver') OR (Medal='Bronze'))
GROUP BY Team,Sport,Name
ORDER BY 4 DESC
);

SELECT DISTINCT ON (Sport)
Sport,Team,cnt  
FROM   Top1
ORDER  BY Sport,cnt DESC;

--Which country has the highest participants in 'London Olympics 2012'
SELECT Team, COUNT(DISTINCT(Name)) AS Number_of_participants FROM olympics
WHERE (Year='2012')
GROUP BY Team
ORDER BY 2 DESC

--Youngest Athlete in Olympics till date
SELECT DISTINCT ON (Age)
Year,MIN(Age) AS Youngest_Athlete,Name FROM olympics
GROUP BY Age,Name,Year
ORDER BY Age,Year ASC
LIMIT 10;

--Which Cities have hosted the Olympics for more than once
SELECT City,COUNT(DISTINCT City) AS Number,Games FROM olympics
GROUP BY City,Games

DROP TABLE IF EXISTS Host_City;
CREATE TABLE Host_City(
City VARCHAR,
Number INT,
Games VARCHAR
);
INSERT INTO Host_City(
SELECT City,COUNT(DISTINCT City) AS Number,Games FROM olympics
GROUP BY City,Games
);

SELECT City,SUM(Number) AS Number_of_times_hosted FROM Host_City
GROUP BY City,Number
ORDER BY Number_of_times_hosted DESC;




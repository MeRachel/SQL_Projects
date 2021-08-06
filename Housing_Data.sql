CREATE TABLE Housing_Data(
UniqueID FLOAT ,ParcelID VARCHAR,
LandUse VARCHAR,PropertyAddress VARCHAR,SaleDate DATE,
SalePrice VARCHAR,LegalReference VARCHAR,SoldAsVacant VARCHAR,OwnerName VARCHAR,
OwnerAddress VARCHAR,Acreage FLOAT,TaxDistrict VARCHAR,LandValue FLOAT,BuildingValue FLOAT,TotalValue FLOAT,
YearBuilt FLOAT,Bedrooms FLOAT,FullBath FLOAT,HalfBath FLOAT
);
COPY Housing_Data 
FROM 'G:\pgAdmin 4\v5\Nashville Housing Data for Data Cleaning.csv'
DELIMITER ';'
CSV HEADER;

SELECT * FROM Housing_Data

--POPULATE THE PROPERTY ADDRESS
SELECT PropertyAddress,ParcelID FROM Housing_Data
ORDER BY ParcelID

SELECT a.ParcelID,a.PropertyAddress,b.ParcelID,b.PropertyAddress, COALESCE(a.PropertyAddress,b.PropertyAddress) AS Property_Address
FROM Housing_Data a JOIN Housing_Data b 
ON a.ParcelID = b.ParcelID
AND a.UniqueID <> b.UniqueID
WHERE a.PropertyAddress IS NULL;

UPDATE Housing_Data
SET PropertyAddress=COALESCE(a.PropertyAddress,b.PropertyAddress)
FROM Housing_Data a JOIN Housing_Data b 
ON a.ParcelID = b.ParcelID
AND a.UniqueID <> b.UniqueID
WHERE a.PropertyAddress IS NULL

-- DIVIDE ADDRESS INTO INDIVIDUAL COLUMNS OF ADDRESS, CITY AND STATE
SELECT OwnerAddress FROM Housing_Data

SELECT SPLIT_PART(OwnerAddress,',','2')
FROM Housing_Data

--CREATE NEW ADDITIONAL COLUMNS
ALTER TABLE Housing_Data
ADD COLUMN Owner_Address VARCHAR,
ADD COLUMN Owner_City VARCHAR,
ADD COLUMN Owner_State VARCHAR

--UPDATE THE NEW COLUMNS
UPDATE Housing_Data
SET Owner_Address=SPLIT_PART(OwnerAddress,',','1')
UPDATE Housing_Data
SET Owner_City=SPLIT_PART(OwnerAddress,',','2')
UPDATE Housing_Data
SET Owner_State=SPLIT_PART(OwnerAddress,',','3')

--CHANGING ALL THE Y AND N TO 'YES' AND 'NO' RESPECTIVELY
SELECT DISTINCT(SoldAsVacant),COUNT(SoldAsVacant) FROM Housing_Data
GROUP BY SoldAsVacant
ORDER BY SoldAsVacant

SELECT 
CASE SoldAsVacant
WHEN 'Y' THEN 'YES'
WHEN 'N' THEN 'NO'
ELSE SoldAsVacant
END
FROM Housing_Data

UPDATE Housing_Data
SET SoldAsVacant=CASE SoldAsVacant
WHEN 'Y' THEN 'Yes'
WHEN 'N' THEN 'No'
ELSE SoldAsVacant
END

--DELETE DUPLICATE ROWS
DELETE FROM Housing_Data
WHERE UniqueID IN
    (SELECT UniqueID
    FROM 
        (SELECT UniqueID,
         ROW_NUMBER() OVER(PARTITION BY ParcelID,
						   PropertyAddress,
				 		   SalePrice,
						   SaleDate,
				 		   LegalReference
		ORDER BY UniqueID) AS row_num
        FROM Housing_Data ) t
        WHERE t.row_num > 1 );
		
--DROP UNUSED COLUMNS
ALTER TABLE Housing_Data
DROP COLUMN OwnerAddress,
DROP COLUMN TaxDistrict,  
DROP COLUMN SaleDate

--FINAL TABLE
SELECT * FROM Housing_Data

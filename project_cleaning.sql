SELECT *
FROM housing_data; 

-- %M matches the full month name (e.g., January, February, ... December).
-- %d matches the day of the month as a numeric value.
-- %Y matches the four-digit year.
SELECT SaleDate, STR_TO_DATE(SaleDate, '%M %d, %Y')
FROM housing_data; 

UPDATE housing_data
SET SaleDate = STR_TO_DATE(SaleDate, '%M %d, %Y');

-- we find if a person has same parcelid, they tend to have some propertyaddress(where sometimes it is empty)
-- we want to fill in those empty address in this condition using self-join or window function
-- Method1:
SELECT ParcelID, PropertyAddress, MAX(PropertyAddress) OVER (PARTITION BY ParcelID) AS new_PropertyAddress
FROM housing_data;

-- Method2:
SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, IFNULL(nullif(a.PropertyAddress, ''), b.PropertyAddress) AS new_propertyAddress_m2
FROM housing_data a
JOIN housing_data b
	ON a.ParcelID = b.ParcelID
	AND a.UniqueID != b.UniqueID
WHERE a.PropertyAddress = '';


UPDATE housing_data h
JOIN (
    SELECT ParcelID, MAX(PropertyAddress) AS MaxAddress
    FROM housing_data
    GROUP BY ParcelID
) AS max_addresses ON h.ParcelID = max_addresses.ParcelID
SET h.PropertyAddress = max_addresses.MaxAddress
WHERE h.PropertyAddress = '';

-- breaking out address individual columns (Address, city, state)
SELECT SUBSTR(PropertyAddress,1, POSITION(',' IN PropertyAddress) - 1) AS Address,
		SUBSTR(PropertyAddress, POSITION(',' IN PropertyAddress) + 1, LENGTH(PropertyAddress)) AS state
FROM housing_data;

-- add two columns into housing_data
ALTER TABLE housing_data
ADD PropertySplitAddress Nvarchar(225);

UPDATE housing_data
SET PropertySplitAddress = SUBSTR(PropertyAddress,1, POSITION(',' IN PropertyAddress) - 1);

ALTER TABLE housing_data
ADD PropertySplitCity Nvarchar(225);

UPDATE housing_data
SET PropertySplitCity = SUBSTR(PropertyAddress, POSITION(',' IN PropertyAddress) + 1, LENGTH(PropertyAddress));

-- simplier way than using substring
SELECT SUBSTRING_INDEX(SUBSTRING_INDEX(OwnerAddress, ',',1),',', -1),
		SUBSTRING_INDEX(SUBSTRING_INDEX(OwnerAddress, ',',2),',', -1),
        SUBSTRING_INDEX(SUBSTRING_INDEX(OwnerAddress, ',',3),',', -1)
FROM housing_data;

ALTER TABLE housing_data
ADD OwnerSplitAddress Nvarchar(225),
ADD OwnerSplitCity Nvarchar(225),
ADD OwnerSplitState Nvarchar(225);

UPDATE housing_data
SET OwnerSplitAddress = SUBSTRING_INDEX(SUBSTRING_INDEX(OwnerAddress, ',',1),',', -1), 
	OwnerSplitCity = SUBSTRING_INDEX(SUBSTRING_INDEX(OwnerAddress, ',',2),',', -1),
	OwnerSplitState = SUBSTRING_INDEX(SUBSTRING_INDEX(OwnerAddress, ',',3),',', -1);

-- we found there are 4 types in SoldAsVacant: No, N, Yes, Y, and also Yes/No are more popular
-- change Y and N to Yes and No in SoldAsVacant
SELECT DISTINCT(SoldAsVacant), COUNT(SoldAsVacant) 
FROM housing_data
GROUP by SoldAsVacant;

SELECT CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
			WHEN SoldAsVacant = 'N' THEN 'No'
            ELSE SoldAsVacant END AS new_SoldAsVacant
FROM housing_data;

UPDATE housing_data
SET SoldAsVacant = CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
						WHEN SoldAsVacant = 'N' THEN 'No'
						ELSE SoldAsVacant END;

-- remove duplicates (don't do it in row data in work)
WITH RowNUmberCTE AS(
SELECT *, 
		ROW_NUMBER() OVER (PARTITION BY parcelID, PropertyAddress, SalePrice, SaleDate, LegalReference
							ORDER BY UniqueID) AS row_num
FROM housing_data
ORDER BY parcelID)

DELETE hd
FROM housing_data hd
JOIN (
	SELECT *
	FROM RowNUmberCTE 
	WHERE row_num > 1
) duplicates ON hd.UniqueID = duplicates.UniqueID;

-- Delete unused column (don't do it in row data in work)
ALTER TABLE housing_data
DROP COLUMN OwnerAddress, 
DROP COLUMN TaxDistrict, 
DROP COLUMN PropertyAddress; 






--1. Convert SaleDate (datetime) into Date type
SELECT saleDate, CONVERT(Date, saleDate)
FROM Portfolio.dbo.NashvilleHousing;

ALTER TABLE NashvilleHousing
ADD saleDateConvert Date;

UPDATE Portfolio.dbo.NashvilleHousing
SET saleDateConvert = CONVERT(Date, saleDate);

SELECT TOP 10 *
FROM Portfolio.dbo.NashvilleHousing;

----------------------------------------------------------------------------------------------------------------------
--2. Populate Proporty Address Data

SELECT *
FROM Portfolio.dbo.NashvilleHousing
WHERE PropertyAddress is null;

--Seems that the same ParcelID, same PropertyAddress
--Self JOIN the table

SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, ISNULL(a.PropertyAddress,b.PropertyAddress)
FROM Portfolio.dbo.NashvilleHousing a
JOIN Portfolio.dbo.NashvilleHousing b
   ON a.ParcelID = b.ParcelID
   AND a.[UniqueID ] <> b.[UniqueID ] -- the same record won't join
WHERE a.PropertyAddress is null;

Update a
Set PropertyAddress = ISNULL(a.PropertyAddress,b.PropertyAddress)
FROM Portfolio.dbo.NashvilleHousing a
JOIN Portfolio.dbo.NashvilleHousing b
   ON a.ParcelID = b.ParcelID
   AND a.[UniqueID ] <> b.[UniqueID ] -- the same record won't join
WHERE a.PropertyAddress is null;

----------------------------------------------------------------------------------------------------------------------
--3. Break out the Address into individual columns (Address, City, States)

--3.1 PropertyAddress

SELECT PropertyAddress
FROM Portfolio.dbo.NashvilleHousing;

SELECT
   PropertyAddress, SUBSTRING(PropertyAddress,1,CHARINDEX(',',PropertyAddress)-1) AS Address,
   SUBSTRING(PropertyAddress,CHARINDEX(',',PropertyAddress)+1,LEN(PropertyAddress)) AS City,CHARINDEX(',',PropertyAddress) AS positionofcomma
FROM Portfolio.dbo.NashvilleHousing;


ALTER TABLE NashvilleHousing
ADD PropertySplitAddress nvarchar(255);

UPDATE Portfolio.dbo.NashvilleHousing
SET PropertySplitAddress = SUBSTRING(PropertyAddress,1,CHARINDEX(',',PropertyAddress)-1);

ALTER TABLE NashvilleHousing
ADD PropertySplitCity nvarchar(255);

UPDATE Portfolio.dbo.NashvilleHousing
SET PropertySplitCity = SUBSTRING(PropertyAddress,CHARINDEX(',',PropertyAddress)+1,LEN(PropertyAddress));

--3.2 OnwerAddress

SELECT 
parsename(REPLACE(OwnerAddress,',','.'),3) AS Address,
parsename(REPLACE(OwnerAddress,',','.'),2) AS city,
parsename(REPLACE(OwnerAddress,',','.'),1) AS State
FROM Portfolio.dbo.NashvilleHousing;

ALTER TABLE Portfolio.dbo.NashvilleHousing
Add OwnerSplitAddress varchar(255),OwnerSplitCity varchar(255), OwnerSplitState varchar(255);

Update Portfolio.dbo.NashvilleHousing
Set OwnerSplitAddress = parsename(REPLACE(OwnerAddress,',','.'),3),
    OwnerSplitCity = parsename(REPLACE(OwnerAddress,',','.'),2),
	OwnerSplitState = parsename(REPLACE(OwnerAddress,',','.'),1);

----------------------------------------------------------------------------------------------------------------------
--4. Change Y and N to Yes and No correspondingly in "Sold as Vacant" field

SELECT DISTINCT SoldAsVacant, COUNT(SoldAsVacant)
FROM Portfolio.dbo.NashvilleHousing
Group by SoldAsVacant
Order by 2

SELECT SoldAsVacant, 
   CASE WHEN SoldAsVacant = 'Y' then 'Yes'
        WHEN SoldAsVacant = 'N' then 'No'
		ELSE SoldAsVacant
		END AS SoldAsVacant
FROM Portfolio.dbo.NashvilleHousing


Update Portfolio.dbo.NashvilleHousing
Set SoldAsVacant = CASE WHEN SoldAsVacant = 'Y' then 'Yes'
        WHEN SoldAsVacant = 'N' then 'No'
		ELSE SoldAsVacant
		END

----------------------------------------------------------------------------------------------------------------------
--5. Remove Duplicate 

--Check
WITH row_numCTE AS
(SELECT *,
	ROW_NUMBER() OVER (PARTITION BY ParcelID, PropertyAddress, SaleDate, SalePrice, LegalReference ORDER BY UniqueID) row_num
FROM Portfolio.dbo.NashvilleHousing
)
SELECT * 
FROM row_numCTE 
WHERE row_num >1

--Assign row-number to identical records
WITH row_numCTE AS
(SELECT *,
	ROW_NUMBER() OVER (PARTITION BY ParcelID, PropertyAddress, SaleDate, SalePrice, LegalReference ORDER BY UniqueID) row_num
FROM Portfolio.dbo.NashvilleHousing
)
DELETE 
FROM row_numCTE 
WHERE row_num >1

----------------------------------------------------------------------------------------------------------------------
--6. Delete unused column 

SELECT *
FROM Portfolio.dbo.NashvilleHousing

ALTER TABLE Portfolio.dbo.NashvilleHousing
DROP COLUMN OwnerAddress, TaxDistrict, PropertyAddress, SaleDate


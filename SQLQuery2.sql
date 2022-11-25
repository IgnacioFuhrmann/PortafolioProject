-- Cleaning Data in SQL Queries

SELECT *
FROM PortfolioProject.dbo.NashvilleHousing


-- Standarize Date Format

SELECT SaleDateConverted, CONVERT(Date, SaleDate)
FROM PortfolioProject.dbo.NashvilleHousing

Update NashvilleHousing
SET SaleDate = CONVERT(Date, SaleDate)

ALTER TABLE NashvilleHousing
Add SaleDateConverted Date;

Update NashvilleHousing
SET SaleDateConverted = CONVERT(Date, SaleDate)

-------------------------------------------------------

-- Populate Property Address data

SELECT *
FROM PortfolioProject.dbo.NashvilleHousing
Order by ParcelID

SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM PortfolioProject.dbo.NashvilleHousing a
JOIN PortfolioProject.dbo.NashvilleHousing b
	on a.ParcelID = b.ParcelID
	AND a.[UniqueID] <> B.[UniqueID]
Where a.PropertyAddress is null

Update a
Set PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM PortfolioProject.dbo.NashvilleHousing a
JOIN PortfolioProject.dbo.NashvilleHousing b
	on a.ParcelID = b.ParcelID
	AND a.[UniqueID] <> B.[UniqueID]
Where a.PropertyAddress is null

---------------------------------------------

-- Breaking out Address into Individual Column (Address, City, State)
-- Option 1 (harder)

SELECT PropertyAddress
FROM PortfolioProject.dbo.NashvilleHousing
-- Where PropertyAddress is null
-- Order by ParcelID

Select
SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1) as Address,
SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) +1, LEN(PropertyAddress)) as Address
FROM PortfolioProject.dbo.NashvilleHousing

ALTER TABLE NashvilleHousing
Add PropertySplitAddress Nvarchar(225);

Update NashvilleHousing
SET PropertySplitAddress  = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1)

ALTER TABLE NashvilleHousing
Add PropertySplitCity Nvarchar(225);

Update NashvilleHousing
SET PropertySplitCity   = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) +1, LEN(PropertyAddress))

SELECT *
FROM PortfolioProject.dbo.NashvilleHousing

-------------------------------------------------

-- Option 2 (easy)

SELECT OwnerAddress
FROM PortfolioProject.dbo.NashvilleHousing

Select
PARSENAME(REPLACE(OwnerAddress, ',', '.') ,3),            -- parsername (divide name) work with '.' thats why we replace ',' for '.'
PARSENAME(REPLACE(OwnerAddress, ',', '.') ,2), 
PARSENAME(REPLACE(OwnerAddress, ',', '.') ,1) 
FROM PortfolioProject.dbo.NashvilleHousing

ALTER TABLE NashvilleHousing
Add OwnerSplitAddress Nvarchar(225);

Update NashvilleHousing
SET OwnerSplitAddress  = PARSENAME(REPLACE(OwnerAddress, ',', '.') ,3)

ALTER TABLE NashvilleHousing
Add OwnerSplitCity Nvarchar(225);

Update NashvilleHousing
SET OwnerSplitCity   = PARSENAME(REPLACE(OwnerAddress, ',', '.') ,2)

ALTER TABLE NashvilleHousing
Add OwnerSplitState Nvarchar(225);

Update NashvilleHousing
SET OwnerSplitState   = PARSENAME(REPLACE(OwnerAddress, ',', '.') ,1)

SELECT *
FROM PortfolioProject.dbo.NashvilleHousing

---------------------------------------

--Change Y and N to Yes and No in "Sold as Vacant" field

SELECT Distinct (SoldAsVacant), Count(SoldAsVacant)
FROM PortfolioProject.dbo.NashvilleHousing
Group by SoldAsVacant
Order by 2

SELECT SoldAsVacant,
CASE When SoldAsVacant = 'Y' THEN 'YES'
	When SoldAsVacant = 'N' THEN 'No'
	Else SoldAsVacant
	END
FROM PortfolioProject.dbo.NashvilleHousing

Update NashvilleHousing
SET SoldAsVacant = CASE When SoldAsVacant = 'Y' THEN 'YES'
	When SoldAsVacant = 'N' THEN 'No'
	Else SoldAsVacant
	END

-------------------------------------

-- Remove Duplicates

WITH RowNumCTE AS(
SELECT *,
 ROW_NUMBER() OVER(
 PARTITION BY ParcelID,
			  PropertyAddress,
			  SaleDate,
			  LegalReference
			  Order by
			   UniqueID
			   ) row_num

FROM PortfolioProject.dbo.NashvilleHousing
 )
Delete 
FROM RowNumCTE
Where row_num > 1

-- to check

WITH RowNumCTE AS(
SELECT *,
 ROW_NUMBER() OVER(
 PARTITION BY ParcelID,
			  PropertyAddress,
			  SaleDate,
			  LegalReference
			  Order by
			   UniqueID
			   ) row_num

FROM PortfolioProject.dbo.NashvilleHousing
 )
Select *
FROM RowNumCTE
Where row_num > 1
Order by PropertyAddress

----------------------

--Delete Unused Columns

SELECT *
FROM PortfolioProject.dbo.NashvilleHousing

Alter Table PortfolioProject.dbo.NashvilleHousing
DROP COLUMN OwnerAddress, TaxDistrict, PropertyAddress, SaleDate

-- Thanks for Reading --
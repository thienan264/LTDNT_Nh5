IF OBJECT_ID('Roles') IS NULL CREATE TABLE Roles(Id int IDENTITY PRIMARY KEY,Name nvarchar(30) NOT NULL UNIQUE,Description nvarchar(255));
IF OBJECT_ID('Users') IS NULL CREATE TABLE Users(Id int IDENTITY PRIMARY KEY,FullName nvarchar(150) NOT NULL,Email nvarchar(255) NOT NULL UNIQUE,PasswordHash nvarchar(255) NOT NULL,PhoneNumber nvarchar(30),Address nvarchar(500),AvatarUrl nvarchar(1000),IsActive bit NOT NULL DEFAULT 1,CreatedAt datetime2 NOT NULL DEFAULT SYSUTCDATETIME(),UpdatedAt datetime2);
IF OBJECT_ID('UserRoles') IS NULL CREATE TABLE UserRoles(UserId int REFERENCES Users(Id),RoleId int REFERENCES Roles(Id),PRIMARY KEY(UserId,RoleId));
IF OBJECT_ID('Categories') IS NULL CREATE TABLE Categories(Id int IDENTITY PRIMARY KEY,Name nvarchar(100) NOT NULL UNIQUE,Description nvarchar(max),ImageUrl nvarchar(1000),DisplayOrder int NOT NULL DEFAULT 0,IsActive bit NOT NULL DEFAULT 1,CreatedAt datetime2 NOT NULL DEFAULT SYSUTCDATETIME(),UpdatedAt datetime2);
IF OBJECT_ID('Units') IS NULL CREATE TABLE Units(Id int IDENTITY PRIMARY KEY,Name nvarchar(255) NOT NULL,Address nvarchar(500) NOT NULL,PhoneNumber nvarchar(30),ContactPerson nvarchar(150),Email nvarchar(255),IsActive bit NOT NULL DEFAULT 1,CreatedAt datetime2 NOT NULL DEFAULT SYSUTCDATETIME());
IF OBJECT_ID('Devices') IS NULL CREATE TABLE Devices(Id int IDENTITY PRIMARY KEY,SerialNumber nvarchar(100) NOT NULL UNIQUE,Name nvarchar(255) NOT NULL,CategoryId int NOT NULL REFERENCES Categories(Id),UnitId int REFERENCES Units(Id),Status int NOT NULL DEFAULT 0 CHECK(Status BETWEEN 0 AND 3),RentalPricePerDay decimal(18,2) NOT NULL CHECK(RentalPricePerDay>=0),ImageUrl nvarchar(1000),QrCode nvarchar(255),Description nvarchar(max),IsActive bit NOT NULL DEFAULT 1,CreatedAt datetime2 NOT NULL DEFAULT SYSUTCDATETIME(),UpdatedAt datetime2);
IF OBJECT_ID('Rentals') IS NULL CREATE TABLE Rentals(Id int IDENTITY PRIMARY KEY,ContractCode nvarchar(50) NOT NULL UNIQUE,UserId int NOT NULL REFERENCES Users(Id),UnitId int REFERENCES Units(Id),StartDate datetime2 NOT NULL,ExpectedEndDate datetime2 NOT NULL,ActualEndDate datetime2,TotalAmount decimal(18,2) NOT NULL,TotalDeposit decimal(18,2) NOT NULL,Status int NOT NULL CHECK(Status BETWEEN 0 AND 4),ShippingAddress nvarchar(500),PhoneNumber nvarchar(30),Notes nvarchar(max),CreatedAt datetime2 NOT NULL DEFAULT SYSUTCDATETIME(),UpdatedAt datetime2);
IF OBJECT_ID('RentalItems') IS NULL CREATE TABLE RentalItems(Id int IDENTITY PRIMARY KEY,RentalId int NOT NULL REFERENCES Rentals(Id),DeviceId int NOT NULL REFERENCES Devices(Id),DailyRate decimal(18,2) NOT NULL,RentalDays int NOT NULL CHECK(RentalDays BETWEEN 1 AND 365),ConditionOnDelivery nvarchar(max),ConditionOnReturn nvarchar(max),UNIQUE(RentalId,DeviceId));
IF NOT EXISTS(SELECT 1 FROM Roles WHERE Name='Admin') INSERT INTO Roles(Name) VALUES('Admin');
IF NOT EXISTS(SELECT 1 FROM Roles WHERE Name='Member') INSERT INTO Roles(Name) VALUES('Member');
IF NOT EXISTS(SELECT 1 FROM Categories) INSERT INTO Categories(Name,Description) VALUES(N'Thiết bị đo đạc',N'Máy đo và khảo sát'),(N'Thiết bị công trình',N'Máy thi công'),(N'Thiết bị văn phòng',N'Thiết bị trình chiếu');
IF NOT EXISTS(SELECT 1 FROM Units) INSERT INTO Units(Name,Address,ContactPerson,PhoneNumber) VALUES(N'Kho trung tâm',N'TP. Hồ Chí Minh',N'Nhân viên kho','0901234567');
IF NOT EXISTS(SELECT 1 FROM Devices)
BEGIN
 DECLARE @category int=(SELECT MIN(Id) FROM Categories);
 INSERT INTO Devices(SerialNumber,Name,CategoryId,RentalPricePerDay,QrCode) VALUES('LEICA-001',N'Máy toàn đạc Leica',@category,450000,'DEV-LEICA-001'),('SOKKIA-001',N'Máy thủy bình Sokkia',@category,150000,'DEV-SOKKIA-001');
END;

IF OBJECT_ID('HandoverLogs') IS NULL CREATE TABLE HandoverLogs(Id int IDENTITY PRIMARY KEY,RentalId int NOT NULL REFERENCES Rentals(Id),LogType nvarchar(10) NOT NULL,HandledBy nvarchar(150) NOT NULL,SignerName nvarchar(150) NOT NULL,SignatureData nvarchar(max) NOT NULL,Notes nvarchar(max),CreatedAt datetime2 NOT NULL DEFAULT SYSUTCDATETIME());

-- Ngày thu hồi từng máy, cho phép trả một phần hợp đồng nhiều thiết bị.
IF COL_LENGTH('RentalItems','ActualReturnDate') IS NULL ALTER TABLE RentalItems ADD ActualReturnDate datetime2 NULL;

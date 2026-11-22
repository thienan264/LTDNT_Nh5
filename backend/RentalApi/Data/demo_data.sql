-- Dữ liệu minh họa. Thêm theo serial để chạy lại không bị trùng.
-- Không ghi đè tên/giá/ảnh do người dùng đã chỉnh sửa.
IF NOT EXISTS(SELECT 1 FROM Categories WHERE Name=N'Thiết bị đo đạc')
    INSERT INTO Categories(Name,Description) VALUES(N'Thiết bị đo đạc',N'Máy đo và khảo sát');
IF NOT EXISTS(SELECT 1 FROM Categories WHERE Name=N'Thiết bị công trình')
    INSERT INTO Categories(Name,Description) VALUES(N'Thiết bị công trình',N'Máy thi công');
IF NOT EXISTS(SELECT 1 FROM Categories WHERE Name=N'Thiết bị văn phòng')
    INSERT INTO Categories(Name,Description) VALUES(N'Thiết bị văn phòng',N'Thiết bị trình chiếu');

DECLARE @samples TABLE(SerialNumber nvarchar(100),Name nvarchar(255),CategoryName nvarchar(100),Price decimal(18,2),ImageUrl nvarchar(1000),Description nvarchar(max));
INSERT INTO @samples VALUES
('LEICA-001',N'Máy toàn đạc Leica TS07',N'Thiết bị đo đạc',450000,'/images/demo/leica-ts07.jpg',N'Thiết bị khảo sát và bố trí công trình, kèm hộp đựng.'),
('SOKKIA-001',N'Máy thủy bình Sokkia B40A',N'Thiết bị đo đạc',150000,'/images/demo/sokkia-b40a.jpg',N'Thiết bị đo cao độ phục vụ thi công.'),
('WACKER-001',N'Máy phát điện Wacker Neuson GP5600A',N'Thiết bị công trình',350000,'/images/demo/wacker-gp5600a.jpg',N'Máy phát điện di động phục vụ công trường.'),
('MAKITA-001',N'Máy khoan bê tông Makita HR2470',N'Thiết bị công trình',120000,'/images/demo/makita-hr2470.jpg',N'Máy khoan búa cầm tay, kèm tay cầm phụ và hộp đựng.'),
('EPSON-001',N'Máy chiếu Epson PowerLite FH52',N'Thiết bị văn phòng',250000,'/images/demo/epson-fh52.jpg',N'Máy chiếu phục vụ phòng họp và sự kiện.');

INSERT INTO Devices(SerialNumber,Name,CategoryId,RentalPricePerDay,QrCode,ImageUrl,Description)
SELECT s.SerialNumber,s.Name,c.Id,s.Price,'DEV-'+s.SerialNumber,s.ImageUrl,s.Description
FROM @samples s JOIN Categories c ON c.Name=s.CategoryName
WHERE NOT EXISTS(SELECT 1 FROM Devices d WHERE d.SerialNumber=s.SerialNumber);

-- Bổ sung ảnh cho đúng 2 dòng seed cũ đang thiếu ảnh.
UPDATE d SET ImageUrl=s.ImageUrl,Name=s.Name,Description=COALESCE(d.Description,s.Description)
FROM Devices d JOIN @samples s ON s.SerialNumber=d.SerialNumber
WHERE NULLIF(d.ImageUrl,'') IS NULL
AND d.Name IN(s.Name,N'Máy toàn đạc Leica',N'Máy thủy bình Sokkia');

UPDATE Categories SET ImageUrl='/images/demo/leica-ts07.jpg'
WHERE Name=N'Thiết bị đo đạc' AND NULLIF(ImageUrl,'') IS NULL;
UPDATE Categories SET ImageUrl='/images/demo/wacker-gp5600a.jpg'
WHERE Name=N'Thiết bị công trình' AND NULLIF(ImageUrl,'') IS NULL;
UPDATE Categories SET ImageUrl='/images/demo/epson-fh52.jpg'
WHERE Name=N'Thiết bị văn phòng' AND NULLIF(ImageUrl,'') IS NULL;

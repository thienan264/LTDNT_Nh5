#!/usr/bin/env python3
"""Dọn fixture của test_api.py trong SQL Server local, giữ dữ liệu người dùng."""
import argparse
from pathlib import Path
import subprocess

ROOT = Path(__file__).resolve().parents[1]

def sql(query):
    command = ['docker', 'exec', '-i', 'equipment_rental_sqlserver', 'sh', '-c',
               'export SQLCMDPASSWORD="$MSSQL_SA_PASSWORD"; exec /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -C -d EquipmentRentalDb -b -h -1 -W -w 65535']
    return subprocess.run(command, input=query, text=True, capture_output=True, check=True).stdout

def cleanup(suffix=None):
    if suffix is not None and not suffix.isdigit():
        raise ValueError('Suffix test phải là số')
    serial = f"d.SerialNumber IN ('AUDIT-{suffix}','DELETE-{suffix}','AUDIT-{suffix}-2')" if suffix else "(d.SerialNumber LIKE 'AUDIT-[0-9]%' OR d.SerialNumber LIKE 'DELETE-[0-9]%')"
    # Chỉ chọn thiết bị có cả serial và tên fixture, không xóa theo tên chung.
    selection = f"SELECT d.Id FROM Devices d WHERE {serial} AND d.Name IN ('AUDIT device','AUDIT delete')"
    images = sql(f"SET NOCOUNT ON; SELECT ImageUrl FROM Devices WHERE Id IN ({selection}) AND ImageUrl LIKE '/uploads/%';")
    category = f"Name IN ('AUDIT-{suffix}','AUDIT-{suffix} edited','AUDIT empty {suffix}')" if suffix else "(Name LIKE 'AUDIT-[0-9]%' OR Name LIKE 'AUDIT empty [0-9]%')"
    email = f"Email IN ('audit-{suffix}@rental.com','other-{suffix}@rental.com')" if suffix else "(Email LIKE 'audit-[0-9]%@rental.com' OR Email LIKE 'other-[0-9]%@rental.com')"
    result = sql(f"""
SET NOCOUNT ON; SET XACT_ABORT ON;
BEGIN TRANSACTION;
DECLARE @devices TABLE(Id int PRIMARY KEY);
INSERT INTO @devices {selection};
DECLARE @rentals TABLE(Id int PRIMARY KEY);
INSERT INTO @rentals SELECT r.Id FROM Rentals r
WHERE r.ShippingAddress IN ('Test','Race')
AND EXISTS(SELECT 1 FROM RentalItems ri JOIN @devices d ON d.Id=ri.DeviceId WHERE ri.RentalId=r.Id)
AND NOT EXISTS(SELECT 1 FROM RentalItems ri WHERE ri.RentalId=r.Id AND ri.DeviceId NOT IN(SELECT Id FROM @devices));
DELETE FROM HandoverLogs WHERE RentalId IN(SELECT Id FROM @rentals);
DELETE FROM RentalItems WHERE RentalId IN(SELECT Id FROM @rentals);
DELETE FROM Rentals WHERE Id IN(SELECT Id FROM @rentals);
DELETE FROM Devices WHERE Id IN(SELECT Id FROM @devices) AND NOT EXISTS(SELECT 1 FROM RentalItems WHERE DeviceId=Devices.Id);
SELECT CONCAT('Removed ',@@ROWCOUNT,' unused test devices.');
-- Giữ máy test đã được người dùng thuê để bảo toàn lịch sử.
UPDATE Devices SET IsActive=0 WHERE Id IN(SELECT Id FROM @devices);
DELETE FROM Categories WHERE {category} AND NOT EXISTS(SELECT 1 FROM Devices WHERE CategoryId=Categories.Id);
UPDATE Categories SET IsActive=0 WHERE {category} AND NOT EXISTS(SELECT 1 FROM Devices WHERE CategoryId=Categories.Id AND Id NOT IN(SELECT Id FROM @devices));
DELETE FROM UserRoles WHERE UserId IN(SELECT Id FROM Users WHERE {email} AND FullName IN(N'Kiểm thử',N'Other') AND NOT EXISTS(SELECT 1 FROM Rentals WHERE UserId=Users.Id));
DELETE FROM Users WHERE {email} AND FullName IN(N'Kiểm thử',N'Other') AND NOT EXISTS(SELECT 1 FROM Rentals WHERE UserId=Users.Id);
COMMIT;
""")
    # Chỉ xóa file test sau khi database không còn tham chiếu.
    webroot = (ROOT/'backend/RentalApi/wwwroot').resolve()
    for line in images.splitlines():
        url = line.strip()
        if not url.startswith('/uploads/') or "'" in url:
            continue
        used = sql(f"SET NOCOUNT ON; SELECT (SELECT COUNT(*) FROM Devices WHERE ImageUrl=N'{url}')+(SELECT COUNT(*) FROM Categories WHERE ImageUrl=N'{url}');").strip()
        path = (webroot/url.lstrip('/')).resolve()
        if used == '0' and webroot in path.parents:
            path.unlink(missing_ok=True)
    print(result.strip())

if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument('--suffix')
    group.add_argument('--all-tests', action='store_true')
    args = parser.parse_args()
    cleanup(args.suffix)

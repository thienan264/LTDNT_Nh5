using System.Data;
using Dapper;
using RentalApi.DTOs;
using RentalApi.Entities;

namespace RentalApi.Models;

public class DeviceRepository : BaseRepository
{
    public DeviceRepository(IDbConnection connection)
        : base(connection) { }

    private const string Select =
        "SELECT d.*,c.Name CategoryName,u.Name UnitName,CAST(CASE WHEN mine.Status IS NULL THEN 0 ELSE 1 END AS bit) IsRentedByMe,mine.Status MyRentalStatus FROM Devices d JOIN Categories c ON c.Id=d.CategoryId LEFT JOIN Units u ON u.Id=d.UnitId OUTER APPLY(SELECT TOP(1) r.Status FROM RentalItems ri JOIN Rentals r ON r.Id=ri.RentalId WHERE ri.DeviceId=d.Id AND r.UserId=@viewerId AND r.Status IN(0,1,2) AND ri.ActualReturnDate IS NULL ORDER BY r.Id DESC) mine ";

    public DeviceDto? GetDevice(int id, int? viewerId = null) =>
        connection.QuerySingleOrDefault<DeviceDto>(Select + "WHERE d.Id=@id", new { id, viewerId });

    public PagedResult<DeviceDto> GetDevices(
        DeviceQueryParameters p,
        bool admin,
        int? excludedId = null,
        int? viewerId = null
    )
    {
        var where =
            " WHERE (@OnlyMine=0 OR EXISTS(SELECT 1 FROM RentalItems ri JOIN Rentals r ON r.Id=ri.RentalId WHERE ri.DeviceId=d.Id AND r.UserId=@viewerId AND r.Status IN(0,1,2) AND ri.ActualReturnDate IS NULL)) AND (@excludedId IS NULL OR d.Id<>@excludedId) AND ((@admin=1 AND @IncludeInactive=1) OR d.IsActive=1) AND (@CategoryId IS NULL OR d.CategoryId=@CategoryId) AND (@UnitId IS NULL OR d.UnitId=@UnitId) AND (@Status IS NULL OR d.Status=@Status) AND (@OnlyAvailable IS NULL OR @OnlyAvailable=0 OR d.Status=0) AND (@Keyword IS NULL OR d.Name LIKE @Keyword OR d.SerialNumber LIKE @Keyword)";
        var args = new
        {
            admin,
            viewerId,
            p.OnlyMine,
            p.IncludeInactive,
            excludedId,
            p.CategoryId,
            p.UnitId,
            p.Status,
            p.OnlyAvailable,
            Keyword = string.IsNullOrWhiteSpace(p.Keyword) ? null : "%" + p.Keyword.Trim() + "%",
            Skip = (Math.Max(1, p.PageIndex) - 1) * Math.Clamp(p.PageSize, 1, 100),
            Take = Math.Clamp(p.PageSize, 1, 100),
        };
        var order = p.SortBy switch
        {
            "price_asc" => "d.RentalPricePerDay",
            "price_desc" => "d.RentalPricePerDay DESC",
            "name" => "d.Name",
            _ => "d.CreatedAt DESC,d.Id DESC",
        };
        return new()
        {
            Items = connection
                .Query<DeviceDto>(
                    Select
                        + where
                        + " ORDER BY "
                        + order
                        + " OFFSET @Skip ROWS FETCH NEXT @Take ROWS ONLY",
                    args
                )
                .ToList(),
            TotalCount = connection.ExecuteScalar<int>(
                "SELECT COUNT(*) FROM Devices d" + where,
                args
            ),
            PageIndex = Math.Max(1, p.PageIndex),
            PageSize = args.Take,
        };
    }

    public int Add(CreateDeviceRequest obj) =>
        connection.QuerySingle<int>(
            "INSERT INTO Devices(SerialNumber,Name,CategoryId,UnitId,Status,RentalPricePerDay,ImageUrl,QrCode,Description,IsActive) OUTPUT INSERTED.Id VALUES(@SerialNumber,@Name,@CategoryId,@UnitId,@Status,@RentalPricePerDay,@ImageUrl,@QrCode,@Description,@IsActive)",
            obj
        );

    public int Edit(int id, UpdateDeviceRequest obj) =>
        connection.Execute(
            "UPDATE Devices SET SerialNumber=@SerialNumber,Name=@Name,CategoryId=@CategoryId,UnitId=@UnitId,Status=@Status,RentalPricePerDay=@RentalPricePerDay,ImageUrl=@ImageUrl,QrCode=@QrCode,Description=@Description,IsActive=@IsActive WHERE Id=@id",
            new
            {
                id,
                obj.SerialNumber,
                obj.Name,
                obj.CategoryId,
                obj.UnitId,
                obj.Status,
                obj.RentalPricePerDay,
                obj.ImageUrl,
                obj.QrCode,
                obj.Description,
                obj.IsActive,
            }
        );

    public int Delete(int id) =>
        connection.Execute(
            "DELETE FROM Devices WHERE Id=@id AND NOT EXISTS(SELECT 1 FROM RentalItems WHERE DeviceId=@id)",
            new { id }
        );

    public bool InRental(int id) =>
        connection.ExecuteScalar<int>(
            "SELECT COUNT(*) FROM RentalItems WHERE DeviceId=@id",
            new { id }
        ) > 0;

    public void SetImage(int id, string url) =>
        connection.Execute("UPDATE Devices SET ImageUrl=@url WHERE Id=@id", new { id, url });

    public DeviceDto? Lookup(string code, int? viewerId = null) =>
        connection.QuerySingleOrDefault<DeviceDto>(
            Select + "WHERE d.SerialNumber=@code OR d.QrCode=@code",
            new { code, viewerId }
        );

    public IEnumerable<object> History(int id, int? viewerId = null) =>
        connection.Query(
            "SELECT r.ContractCode contract_code,u.Name unit_name,r.PhoneNumber phone_number,r.StartDate start_date,r.ExpectedEndDate expected_end_date,COALESCE(ri.ActualReturnDate,r.ActualEndDate) actual_end_date,CASE WHEN ri.ActualReturnDate IS NOT NULL OR r.Status=3 THEN 'RETURNED' WHEN r.Status=4 THEN 'CANCELLED' WHEN r.Status=0 THEN 'PENDING' WHEN r.Status=1 THEN 'APPROVED' ELSE 'ACTIVE' END rental_status,ri.ConditionOnDelivery condition_on_delivery,ri.ConditionOnReturn condition_on_return FROM RentalItems ri JOIN Rentals r ON r.Id=ri.RentalId LEFT JOIN Units u ON u.Id=r.UnitId WHERE ri.DeviceId=@id AND (@viewerId IS NULL OR r.UserId=@viewerId) ORDER BY r.Id DESC",
            new { id, viewerId }
        );

    public bool HasActiveRental(int id) =>
        connection.ExecuteScalar<int>(
            "SELECT COUNT(*) FROM RentalItems ri JOIN Rentals r ON r.Id=ri.RentalId WHERE ri.DeviceId=@id AND ri.ActualReturnDate IS NULL AND r.Status IN(0,1,2)",
            new { id }
        ) > 0;

    public void UpdateStatus(int id, DeviceStatus status)
    {
        if (!Enum.IsDefined(status))
            throw new ArgumentException("Trạng thái thiết bị không hợp lệ.");
        if (connection.State != ConnectionState.Open)
            connection.Open();
        using var tx = connection.BeginTransaction(IsolationLevel.Serializable);
        // Khóa hợp đồng trước rồi mới khóa máy, giống thứ tự khi thu hồi cả hợp đồng.
        var rentalIds = connection
            .Query<int>(
                "SELECT r.Id FROM Rentals r WITH(UPDLOCK,HOLDLOCK) WHERE r.Status IN(0,1,2) AND EXISTS(SELECT 1 FROM RentalItems ri WHERE ri.RentalId=r.Id AND ri.DeviceId=@id AND ri.ActualReturnDate IS NULL) ORDER BY r.Id",
                new { id },
                tx
            )
            .ToList();
        var device = connection.QuerySingle<Device>(
            "SELECT * FROM Devices WITH(UPDLOCK,HOLDLOCK) WHERE Id=@id",
            new { id },
            tx
        );
        if (device.Status == status)
        {
            tx.Commit();
            return;
        }
        if (rentalIds.Count > 1)
            throw new ArgumentException(
                "Thiết bị đang có nhiều hợp đồng chưa kết thúc. Vui lòng kiểm tra hợp đồng."
            );
        if (rentalIds.Count == 1)
        {
            var rentalId = rentalIds[0];
            var rentalStatus = connection.QuerySingle<RentalStatus>(
                "SELECT Status FROM Rentals WHERE Id=@rentalId",
                new { rentalId },
                tx
            );
            if (rentalStatus != RentalStatus.Renting)
                throw new ArgumentException(
                    "Hợp đồng chưa bàn giao. Hãy bàn giao hoặc hủy hợp đồng trước khi thu hồi."
                );
            if (status == DeviceStatus.Rented)
                throw new ArgumentException("Máy đang thuộc hợp đồng thuê.");
            // Ghi nhận trả đúng máy đang chọn, không trả các máy khác trong hợp đồng.
            connection.Execute(
                "UPDATE RentalItems SET ActualReturnDate=SYSUTCDATETIME(),ConditionOnReturn=@condition WHERE RentalId=@rentalId AND DeviceId=@id AND ActualReturnDate IS NULL",
                new
                {
                    id,
                    rentalId,
                    condition = status == DeviceStatus.Available ? "Đã thu hồi về kho"
                    : status == DeviceStatus.Broken ? "Thu hồi và báo hỏng"
                    : "Thu hồi để bảo trì",
                },
                tx
            );
            connection.Execute(
                "UPDATE Rentals SET Status=3,ActualEndDate=SYSUTCDATETIME() WHERE Id=@rentalId AND NOT EXISTS(SELECT 1 FROM RentalItems WHERE RentalId=@rentalId AND ActualReturnDate IS NULL)",
                new { rentalId },
                tx
            );
        }
        connection.Execute(
            "UPDATE Devices SET Status=@status,UpdatedAt=SYSUTCDATETIME() WHERE Id=@id",
            new { id, status },
            tx
        );
        tx.Commit();
    }
}

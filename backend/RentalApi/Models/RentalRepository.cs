using System.Data;
using Dapper;
using RentalApi.DTOs;
using RentalApi.Entities;

namespace RentalApi.Models;

public class RentalRepository : BaseRepository
{
    public RentalRepository(IDbConnection connection)
        : base(connection) { }

    private const string Select =
        "SELECT r.*,u.FullName UserName,u.Email UserEmail,n.Name UnitName FROM Rentals r JOIN Users u ON u.Id=r.UserId LEFT JOIN Units n ON n.Id=r.UnitId ";

    public RentalDto? GetRental(int id)
    {
        var rental = connection.QuerySingleOrDefault<RentalDto>(
            Select + "WHERE r.Id=@id",
            new { id }
        );
        if (rental != null)
            rental.Items = connection
                .Query<RentalItemDto>(
                    "SELECT ri.*,d.Name DeviceName,d.SerialNumber DeviceSerialNumber,d.ImageUrl DeviceImageUrl,ri.DailyRate*ri.RentalDays Subtotal FROM RentalItems ri JOIN Devices d ON d.Id=ri.DeviceId WHERE RentalId=@id",
                    new { id }
                )
                .ToList();
        return rental;
    }

    public List<RentalDto> GetMine(int userId) =>
        connection
            .Query<int>(
                "SELECT Id FROM Rentals WHERE UserId=@userId ORDER BY Id DESC",
                new { userId }
            )
            .Select(id => GetRental(id)!)
            .ToList();

    public PagedResult<RentalDto> GetRentals(RentalQueryParameters p)
    {
        var where =
            " WHERE (@Status IS NULL OR r.Status=@Status) AND (@Keyword IS NULL OR r.ContractCode LIKE @Keyword OR u.FullName LIKE @Keyword) AND (@FromDate IS NULL OR r.CreatedAt>=@FromDate) AND (@ToDate IS NULL OR r.CreatedAt<DATEADD(day,1,CAST(@ToDate AS date)))";
        var args = new
        {
            p.Status,
            Keyword = string.IsNullOrWhiteSpace(p.Keyword) ? null : "%" + p.Keyword + "%",
            p.FromDate,
            p.ToDate,
            Skip = (Math.Max(1, p.PageIndex) - 1) * Math.Clamp(p.PageSize, 1, 100),
            Take = Math.Clamp(p.PageSize, 1, 100),
        };
        var ids = connection
            .Query<int>(
                "SELECT r.Id FROM Rentals r JOIN Users u ON u.Id=r.UserId"
                    + where
                    + " ORDER BY r.Id DESC OFFSET @Skip ROWS FETCH NEXT @Take ROWS ONLY",
                args
            )
            .ToList();
        return new()
        {
            Items = ids.Select(id => GetRental(id)!).ToList(),
            TotalCount = connection.ExecuteScalar<int>(
                "SELECT COUNT(*) FROM Rentals r JOIN Users u ON u.Id=r.UserId" + where,
                args
            ),
            PageIndex = Math.Max(1, p.PageIndex),
            PageSize = args.Take,
        };
    }

    public int Checkout(int userId, CreateRentalCheckoutRequest obj)
    {
        if (
            obj.ExpectedEndDate <= obj.StartDate
            || obj.Items.Count == 0
            || obj.Items.Select(i => i.DeviceId).Distinct().Count() != obj.Items.Count
        )
            throw new ArgumentException("Ngày thuê hoặc danh sách thiết bị không hợp lệ.");
        if (connection.State != ConnectionState.Open)
            connection.Open();
        using var tx = connection.BeginTransaction(IsolationLevel.Serializable);
        // Khóa thiết bị trong giao dịch để hai khách không thuê trùng cùng một máy.
        var devices = new List<Device>();
        foreach (var item in obj.Items.OrderBy(i => i.DeviceId))
        {
            var d = connection.QuerySingleOrDefault<Device>(
                "SELECT * FROM Devices WITH(UPDLOCK,HOLDLOCK) WHERE Id=@DeviceId",
                item,
                tx
            );
            if (d == null || !d.IsActive || d.Status != DeviceStatus.Available)
                throw new ArgumentException("Thiết bị không tồn tại hoặc không còn sẵn sàng.");
            devices.Add(d);
        }
        var total = obj.Items.Sum(i =>
            devices.First(d => d.Id == i.DeviceId).RentalPricePerDay * i.RentalDays
        );
        var id = connection.QuerySingle<int>(
            "INSERT INTO Rentals(ContractCode,UserId,UnitId,StartDate,ExpectedEndDate,TotalAmount,TotalDeposit,Status,ShippingAddress,PhoneNumber,Notes) OUTPUT INSERTED.Id VALUES(@code,@userId,@UnitId,@StartDate,@ExpectedEndDate,@total,@deposit,0,@ShippingAddress,@PhoneNumber,@Notes)",
            new
            {
                code = "HD-" + Guid.NewGuid().ToString("N")[..12].ToUpper(),
                userId,
                obj.UnitId,
                obj.StartDate,
                obj.ExpectedEndDate,
                total,
                deposit = total * 0.3m,
                obj.ShippingAddress,
                obj.PhoneNumber,
                obj.Notes,
            },
            tx
        );
        foreach (var item in obj.Items)
        {
            var rate = devices.First(d => d.Id == item.DeviceId).RentalPricePerDay;
            connection.Execute(
                "INSERT INTO RentalItems(RentalId,DeviceId,DailyRate,RentalDays) VALUES(@id,@DeviceId,@rate,@RentalDays); UPDATE Devices SET Status=1 WHERE Id=@DeviceId",
                new
                {
                    id,
                    item.DeviceId,
                    rate,
                    item.RentalDays,
                },
                tx
            );
        }
        tx.Commit();
        return id;
    }

    public void SetStatus(int id, UpdateRentalStatusRequest obj)
    {
        if (connection.State != ConnectionState.Open)
            connection.Open();
        using var tx = connection.BeginTransaction(IsolationLevel.Serializable);
        var old = connection.QuerySingle<RentalStatus>(
            "SELECT Status FROM Rentals WITH(UPDLOCK,HOLDLOCK) WHERE Id=@id",
            new { id },
            tx
        );
        if (old == obj.Status)
        {
            tx.Commit();
            return;
        }
        bool valid =
            old == RentalStatus.Pending
                && (obj.Status == RentalStatus.Approved || obj.Status == RentalStatus.Cancelled)
            || old == RentalStatus.Approved
                && (obj.Status == RentalStatus.Renting || obj.Status == RentalStatus.Cancelled)
            || old == RentalStatus.Renting && obj.Status == RentalStatus.Returned;
        if (!valid)
            throw new ArgumentException("Không thể chuyển trạng thái hợp đồng theo thứ tự này.");
        connection.Execute(
            "UPDATE Rentals SET Status=@Status,ActualEndDate=@ActualEndDate,Notes=COALESCE(@Notes,Notes) WHERE Id=@id",
            new
            {
                id,
                obj.Status,
                ActualEndDate = obj.Status == RentalStatus.Returned
                    ? obj.ActualEndDate ?? DateTime.UtcNow
                    : obj.ActualEndDate,
                obj.Notes,
            },
            tx
        );
        if (obj.Status == RentalStatus.Returned || obj.Status == RentalStatus.Cancelled)
            connection.Execute(
                "UPDATE Devices SET Status=0 WHERE Id IN(SELECT DeviceId FROM RentalItems WHERE RentalId=@id AND ActualReturnDate IS NULL)",
                new { id },
                tx
            );
        if (obj.Status == RentalStatus.Returned || obj.Status == RentalStatus.Cancelled)
            connection.Execute(
                "UPDATE RentalItems SET ActualReturnDate=SYSUTCDATETIME() WHERE RentalId=@id AND ActualReturnDate IS NULL",
                new { id },
                tx
            );
        tx.Commit();
    }

    public IEnumerable<object> GetLogs(int id) =>
        connection.Query(
            "SELECT Id id,LogType log_type,HandledBy handled_by,SignerName signer_name,SignatureData signature_data,Notes notes,CreatedAt created_at FROM HandoverLogs WHERE RentalId=@id ORDER BY Id",
            new { id }
        );

    public void AddLog(int id, HandoverRequest obj)
    {
        if (connection.State != ConnectionState.Open)
            connection.Open();
        using var tx = connection.BeginTransaction(IsolationLevel.Serializable);
        var old = connection.QuerySingle<RentalStatus>(
            "SELECT Status FROM Rentals WITH(UPDLOCK,HOLDLOCK) WHERE Id=@id",
            new { id },
            tx
        );
        if (
            obj.LogType == "DELIVERY" && old != RentalStatus.Approved
            || obj.LogType == "RETURN" && old != RentalStatus.Renting
        )
            throw new ArgumentException("Bàn giao cần đơn đã duyệt; thu hồi cần đơn đang thuê.");
        connection.Execute(
            "INSERT INTO HandoverLogs(RentalId,LogType,HandledBy,SignerName,SignatureData,Notes) VALUES(@id,@LogType,@HandledBy,@SignerName,@SignatureData,@Notes)",
            new
            {
                id,
                obj.LogType,
                obj.HandledBy,
                obj.SignerName,
                obj.SignatureData,
                obj.Notes,
            },
            tx
        );
        connection.Execute(
            "UPDATE Rentals SET Status=@status,ActualEndDate=@returned WHERE Id=@id",
            new
            {
                id,
                status = obj.LogType == "RETURN" ? 3 : 2,
                returned = obj.LogType == "RETURN" ? (DateTime?)DateTime.UtcNow : null,
            },
            tx
        );
        if (obj.LogType == "RETURN")
            connection.Execute(
                "UPDATE Devices SET Status=0 WHERE Id IN(SELECT DeviceId FROM RentalItems WHERE RentalId=@id AND ActualReturnDate IS NULL)",
                new { id },
                tx
            );
        if (obj.LogType == "RETURN")
            connection.Execute(
                "UPDATE RentalItems SET ActualReturnDate=SYSUTCDATETIME() WHERE RentalId=@id AND ActualReturnDate IS NULL",
                new { id },
                tx
            );
        tx.Commit();
    }
}

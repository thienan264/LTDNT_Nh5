namespace RentalApi.Entities;

public enum RentalStatus
{
    Pending = 0, // Chờ duyệt
    Approved = 1, // Đã duyệt, chờ bàn giao
    Renting = 2, // Đang thuê / đã bàn giao
    Returned = 3, // Đã trả thiết bị hoàn tất
    Cancelled = 4, // Đã hủy đơn
}

public class Rental
{
    public int Id { get; set; }
    public string ContractCode { get; set; } = string.Empty;

    public int UserId { get; set; }
    public User User { get; set; } = null!;

    public int? UnitId { get; set; }
    public Unit? Unit { get; set; }

    public DateTime StartDate { get; set; }
    public DateTime ExpectedEndDate { get; set; }
    public DateTime? ActualEndDate { get; set; }

    public decimal TotalAmount { get; set; }
    public decimal TotalDeposit { get; set; }
    public RentalStatus Status { get; set; } = RentalStatus.Pending;
    public string? ShippingAddress { get; set; }
    public string? PhoneNumber { get; set; }
    public string? Notes { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime? UpdatedAt { get; set; }

    public ICollection<RentalItem> RentalItems { get; set; } = new List<RentalItem>();
}

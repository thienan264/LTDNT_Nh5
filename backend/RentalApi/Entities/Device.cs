namespace RentalApi.Entities;

public enum DeviceStatus
{
    Available = 0, // Sẵn sàng cho thuê
    Rented = 1, // Đang cho thuê
    Maintenance = 2, // Đang bảo dưỡng / kiểm định
    Broken = 3, // Hư hỏng / ngừng sử dụng
}

public class Device
{
    public int Id { get; set; }
    public string SerialNumber { get; set; } = string.Empty;
    public string Name { get; set; } = string.Empty;

    public int CategoryId { get; set; }
    public Category Category { get; set; } = null!;

    public int? UnitId { get; set; }
    public Unit? Unit { get; set; }

    public DeviceStatus Status { get; set; } = DeviceStatus.Available;
    public decimal RentalPricePerDay { get; set; }
    public string? ImageUrl { get; set; }
    public string? QrCode { get; set; }
    public string? Description { get; set; }
    public bool IsActive { get; set; } = true;
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime? UpdatedAt { get; set; }

    public ICollection<RentalItem> RentalItems { get; set; } = new List<RentalItem>();
}

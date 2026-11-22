using System.ComponentModel.DataAnnotations;
using RentalApi.Entities;

namespace RentalApi.DTOs;

public class DeviceDto
{
    public bool IsRentedByMe { get; set; }
    public RentalStatus? MyRentalStatus { get; set; }
    public int Id { get; set; }
    public string SerialNumber { get; set; } = string.Empty;
    public string Name { get; set; } = string.Empty;
    public int CategoryId { get; set; }
    public string CategoryName { get; set; } = string.Empty;
    public int? UnitId { get; set; }
    public string? UnitName { get; set; }
    public DeviceStatus Status { get; set; }
    public string StatusText =>
        Status switch
        {
            DeviceStatus.Available => "Sẵn sàng cho thuê",
            DeviceStatus.Rented => "Đang cho thuê",
            DeviceStatus.Maintenance => "Bảo dưỡng / Kiểm định",
            DeviceStatus.Broken => "Hư hỏng / Tạm ngưng",
            _ => "Không xác định",
        };
    public decimal RentalPricePerDay { get; set; }
    public string? ImageUrl { get; set; }
    public string? QrCode { get; set; }
    public string? Description { get; set; }
    public bool IsActive { get; set; }
    public DateTime CreatedAt { get; set; }
}

public class CreateDeviceRequest
{
    [Required]
    [MaxLength(100)]
    public string SerialNumber { get; set; } = string.Empty;

    [Required]
    [MaxLength(255)]
    public string Name { get; set; } = string.Empty;

    [Required]
    public int CategoryId { get; set; }

    public int? UnitId { get; set; }

    [Required]
    [Range(0, 1000000000)]
    public decimal RentalPricePerDay { get; set; }

    public DeviceStatus Status { get; set; } = DeviceStatus.Available;
    public string? ImageUrl { get; set; }
    public string? QrCode { get; set; }
    public string? Description { get; set; }
    public bool IsActive { get; set; } = true;
}

public class UpdateDeviceRequest
{
    [Required]
    [MaxLength(100)]
    public string SerialNumber { get; set; } = string.Empty;

    [Required]
    [MaxLength(255)]
    public string Name { get; set; } = string.Empty;

    [Required]
    public int CategoryId { get; set; }

    public int? UnitId { get; set; }

    [Required]
    [Range(0, 1000000000)]
    public decimal RentalPricePerDay { get; set; }

    public DeviceStatus Status { get; set; }
    public string? ImageUrl { get; set; }
    public string? QrCode { get; set; }
    public string? Description { get; set; }
    public bool IsActive { get; set; }
}

public class DeviceQueryParameters
{
    public bool OnlyMine { get; set; }
    public bool IncludeInactive { get; set; }
    public string? Keyword { get; set; }
    public int? CategoryId { get; set; }
    public int? UnitId { get; set; }
    public DeviceStatus? Status { get; set; }
    public bool? OnlyAvailable { get; set; }
    public int PageIndex { get; set; } = 1;
    public int PageSize { get; set; } = 10;
    public string? SortBy { get; set; } // "newest", "price_asc", "price_desc", "name"
}

public class UpdateDeviceStatusRequest
{
    public DeviceStatus Status { get; set; }
}

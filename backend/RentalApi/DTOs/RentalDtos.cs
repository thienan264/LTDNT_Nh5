using System.ComponentModel.DataAnnotations;
using RentalApi.Entities;

namespace RentalApi.DTOs;

public class RentalItemDto
{
    public DateTime? ActualReturnDate { get; set; }
    public int Id { get; set; }
    public int DeviceId { get; set; }
    public string DeviceName { get; set; } = string.Empty;
    public string DeviceSerialNumber { get; set; } = string.Empty;
    public string? DeviceImageUrl { get; set; }
    public decimal DailyRate { get; set; }
    public int RentalDays { get; set; }
    public decimal Subtotal { get; set; }
    public string? ConditionOnDelivery { get; set; }
    public string? ConditionOnReturn { get; set; }
}

public class RentalDto
{
    public int Id { get; set; }
    public string ContractCode { get; set; } = string.Empty;
    public int UserId { get; set; }
    public string UserName { get; set; } = string.Empty;
    public string UserEmail { get; set; } = string.Empty;
    public int? UnitId { get; set; }
    public string? UnitName { get; set; }

    public DateTime StartDate { get; set; }
    public DateTime ExpectedEndDate { get; set; }
    public DateTime? ActualEndDate { get; set; }

    public decimal TotalAmount { get; set; }
    public decimal TotalDeposit { get; set; }
    public RentalStatus Status { get; set; }
    public string StatusText =>
        Status switch
        {
            RentalStatus.Pending => "Chờ duyệt hợp đồng",
            RentalStatus.Approved => "Đã duyệt, chờ giao thiết bị",
            RentalStatus.Renting => "Đang thuê thiết bị",
            RentalStatus.Returned => "Đã hoàn trả thiết bị",
            RentalStatus.Cancelled => "Đã hủy đơn thuê",
            _ => "Không xác định",
        };

    public string? ShippingAddress { get; set; }
    public string? PhoneNumber { get; set; }
    public string? Notes { get; set; }
    public DateTime CreatedAt { get; set; }

    public List<RentalItemDto> Items { get; set; } = new();
}

public class CheckoutItemRequest
{
    [Required]
    public int DeviceId { get; set; }

    [Required]
    [Range(1, 365)]
    public int RentalDays { get; set; } = 1;
}

public class CreateRentalCheckoutRequest
{
    public int? UnitId { get; set; }

    [Required]
    public DateTime StartDate { get; set; }

    [Required]
    public DateTime ExpectedEndDate { get; set; }

    [Required]
    [MaxLength(255)]
    public string ShippingAddress { get; set; } = string.Empty;

    [Required]
    [MaxLength(20)]
    public string PhoneNumber { get; set; } = string.Empty;

    public string? Notes { get; set; }

    [Required]
    [MinLength(1, ErrorMessage = "Giỏ thuê phải có ít nhất một thiết bị")]
    public List<CheckoutItemRequest> Items { get; set; } = new();
}

public class UpdateRentalStatusRequest
{
    [Required]
    public RentalStatus Status { get; set; }

    public DateTime? ActualEndDate { get; set; }
    public string? Notes { get; set; }
}

public class RentalQueryParameters
{
    public string? Keyword { get; set; }
    public RentalStatus? Status { get; set; }
    public DateTime? FromDate { get; set; }
    public DateTime? ToDate { get; set; }
    public int PageIndex { get; set; } = 1;
    public int PageSize { get; set; } = 10;
}

public class HandoverRequest
{
    [Required, RegularExpression("^(DELIVERY|RETURN)$")]
    public string LogType { get; set; } = "DELIVERY";

    [Required, MaxLength(150)]
    public string HandledBy { get; set; } = string.Empty;

    [Required, MaxLength(150)]
    public string SignerName { get; set; } = string.Empty;

    [Required]
    public string SignatureData { get; set; } = string.Empty;
    public string? Notes { get; set; }
}

using System.ComponentModel.DataAnnotations;

namespace RentalApi.DTOs;

public class UnitDto
{
    public int Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public string Address { get; set; } = string.Empty;
    public string? PhoneNumber { get; set; }
    public string? ContactPerson { get; set; }
    public string? Email { get; set; }
    public bool IsActive { get; set; }
    public int DeviceCount { get; set; }
    public DateTime CreatedAt { get; set; }
}

public class CreateUnitRequest
{
    [Required]
    [MaxLength(255)]
    public string Name { get; set; } = string.Empty;

    [Required]
    [MaxLength(500)]
    public string Address { get; set; } = string.Empty;

    public string? PhoneNumber { get; set; }
    public string? ContactPerson { get; set; }
    public string? Email { get; set; }
    public bool IsActive { get; set; } = true;
}

public class UpdateUnitRequest
{
    [Required]
    [MaxLength(255)]
    public string Name { get; set; } = string.Empty;

    [Required]
    [MaxLength(500)]
    public string Address { get; set; } = string.Empty;

    public string? PhoneNumber { get; set; }
    public string? ContactPerson { get; set; }
    public string? Email { get; set; }
    public bool IsActive { get; set; }
}

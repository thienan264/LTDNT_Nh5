using System.ComponentModel.DataAnnotations;

namespace RentalApi.DTOs;

public class CategoryDto
{
    public int Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public string? Description { get; set; }
    public string? ImageUrl { get; set; }
    public int DisplayOrder { get; set; }
    public bool IsActive { get; set; }
    public int DeviceCount { get; set; }
    public DateTime CreatedAt { get; set; }
}

public class CreateCategoryRequest
{
    [Required]
    [MaxLength(100)]
    public string Name { get; set; } = string.Empty;

    public string? Description { get; set; }
    public string? ImageUrl { get; set; }
    public int DisplayOrder { get; set; } = 0;
    public bool IsActive { get; set; } = true;
}

public class UpdateCategoryRequest
{
    [Required]
    [MaxLength(100)]
    public string Name { get; set; } = string.Empty;

    public string? Description { get; set; }
    public string? ImageUrl { get; set; }
    public int DisplayOrder { get; set; }
    public bool IsActive { get; set; }
}

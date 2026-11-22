using System.ComponentModel.DataAnnotations;

namespace RentalApi.DTOs;

public class UserManagementDto
{
    public int Id { get; set; }
    public string FullName { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public string? PhoneNumber { get; set; }
    public string? Address { get; set; }
    public string? AvatarUrl { get; set; }
    public bool IsActive { get; set; }
    public List<string> Roles { get; set; } = new();
    public int RentalCount { get; set; }
    public DateTime CreatedAt { get; set; }
}

public class UpdateUserRolesRequest
{
    [Required]
    public List<string> Roles { get; set; } = new();
}

public class UpdateUserStatusRequest
{
    [Required]
    public bool IsActive { get; set; }
}

public class UserQueryParameters
{
    public string? Keyword { get; set; }
    public string? Role { get; set; }
    public bool? IsActive { get; set; }
    public int PageIndex { get; set; } = 1;
    public int PageSize { get; set; } = 10;
}

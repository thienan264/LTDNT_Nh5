using Microsoft.AspNetCore.Http;

namespace RentalApi.DTOs;

public class PagedResult<T>
{
    public List<T> Items { get; set; } = new();
    public int TotalCount { get; set; }
    public int PageIndex { get; set; }
    public int PageSize { get; set; }
    public int TotalPages => (int)Math.Ceiling((double)TotalCount / PageSize);
    public bool HasPreviousPage => PageIndex > 1;
    public bool HasNextPage => PageIndex < TotalPages;
}

public class FileUploadDto
{
    public IFormFile File { get; set; } = null!;
}

public class MessageResponse
{
    public string Message { get; set; } = string.Empty;
}

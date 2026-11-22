using Microsoft.AspNetCore.Http;

namespace RentalApi.Services;

public interface IFileStorageService
{
    Task<string> SaveFileAsync(IFormFile file, string subFolder);
    bool DeleteFile(string? relativeUrl);
}

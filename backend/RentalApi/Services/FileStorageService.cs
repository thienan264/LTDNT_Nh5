using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Http;

namespace RentalApi.Services;

public class FileStorageService : IFileStorageService
{
    private readonly IWebHostEnvironment _env;

    public FileStorageService(IWebHostEnvironment env)
    {
        _env = env;
    }

    public async Task<string> SaveFileAsync(IFormFile file, string subFolder)
    {
        if (file == null || file.Length == 0)
        {
            throw new ArgumentException("Tệp tin rỗng hoặc không hợp lệ");
        }

        var webRoot = _env.WebRootPath;
        if (string.IsNullOrEmpty(webRoot))
        {
            webRoot = Path.Combine(_env.ContentRootPath, "wwwroot");
        }

        var targetDir = Path.Combine(webRoot, "uploads", subFolder);
        if (!Directory.Exists(targetDir))
        {
            Directory.CreateDirectory(targetDir);
        }

        var extension = Path.GetExtension(file.FileName).ToLowerInvariant();
        if (extension != ".jpg" && extension != ".jpeg" && extension != ".png")
            throw new ArgumentException("Chỉ nhận ảnh JPG, PNG.");
        if (file.Length > 5 * 1024 * 1024)
            throw new ArgumentException("Ảnh tối đa 5 MB.");
        var uniqueFileName = $"{Guid.NewGuid():N}{extension}";
        var filePath = Path.Combine(targetDir, uniqueFileName);

        using (var stream = new FileStream(filePath, FileMode.Create))
        {
            await file.CopyToAsync(stream);
        }

        // Return relative path: /uploads/{subFolder}/{uniqueFileName}
        return $"/uploads/{subFolder}/{uniqueFileName}";
    }

    public bool DeleteFile(string? relativeUrl)
    {
        if (string.IsNullOrWhiteSpace(relativeUrl))
        {
            return false;
        }

        try
        {
            var webRoot = _env.WebRootPath;
            if (string.IsNullOrEmpty(webRoot))
            {
                webRoot = Path.Combine(_env.ContentRootPath, "wwwroot");
            }

            if (!relativeUrl.StartsWith("/uploads/"))
                return false;
            var trimmed = relativeUrl.TrimStart('/');
            var fullPath = Path.GetFullPath(Path.Combine(webRoot, trimmed));
            var uploadsRoot =
                Path.GetFullPath(Path.Combine(webRoot, "uploads")) + Path.DirectorySeparatorChar;
            if (!fullPath.StartsWith(uploadsRoot, StringComparison.Ordinal))
                return false;

            if (File.Exists(fullPath))
            {
                File.Delete(fullPath);
                return true;
            }
        }
        catch
        {
            // Silently ignore file delete errors
        }

        return false;
    }
}

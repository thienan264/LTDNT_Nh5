using System.Data;
using Dapper;
using RentalApi.DTOs;
using RentalApi.Entities;

namespace RentalApi.Models;

public class CategoryRepository : BaseRepository
{
    public CategoryRepository(IDbConnection connection)
        : base(connection) { }

    public List<CategoryDto> GetCategories(bool includeInactive = false) =>
        connection
            .Query<CategoryDto>(
                "SELECT c.*, (SELECT COUNT(*) FROM Devices WHERE CategoryId=c.Id) DeviceCount FROM Categories c WHERE c.IsActive=1 OR @includeInactive=1 ORDER BY DisplayOrder,Id",
                new { includeInactive }
            )
            .ToList();

    public CategoryDto? GetCategory(int id)
    {
        string sql =
            "SELECT c.*, (SELECT COUNT(*) FROM Devices WHERE CategoryId=c.Id) DeviceCount FROM Categories c WHERE c.Id=@id";
        return connection.QuerySingleOrDefault<CategoryDto>(sql, new { id });
    }

    public int Add(CreateCategoryRequest obj) =>
        connection.QuerySingle<int>(
            "INSERT INTO Categories(Name,Description,ImageUrl,DisplayOrder,IsActive) OUTPUT INSERTED.Id VALUES(@Name,@Description,@ImageUrl,@DisplayOrder,@IsActive)",
            obj
        );

    public int Edit(int id, UpdateCategoryRequest obj) =>
        connection.Execute(
            "UPDATE Categories SET Name=@Name,Description=@Description,ImageUrl=@ImageUrl,DisplayOrder=@DisplayOrder,IsActive=@IsActive WHERE Id=@id",
            new
            {
                id,
                obj.Name,
                obj.Description,
                obj.ImageUrl,
                obj.DisplayOrder,
                obj.IsActive,
            }
        );

    public int Delete(int id) =>
        connection.Execute(
            "DELETE FROM Categories WHERE Id=@id AND NOT EXISTS(SELECT 1 FROM Devices WHERE CategoryId=@id)",
            new { id }
        );

    public void SetImage(int id, string url) =>
        connection.Execute("UPDATE Categories SET ImageUrl=@url WHERE Id=@id", new { id, url });
}

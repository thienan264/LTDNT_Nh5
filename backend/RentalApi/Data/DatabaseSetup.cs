using Dapper;
using Microsoft.Data.SqlClient;

namespace RentalApi.Data;

public static class DatabaseSetup
{
    public static void Initialize(IConfiguration configuration, string root)
    {
        var cs = configuration.GetConnectionString("DefaultConnection")!;
        var settings = new SqlConnectionStringBuilder(cs);
        var database = settings.InitialCatalog;
        if (database != "EquipmentRentalDb")
            throw new InvalidOperationException(
                "Script khởi tạo chỉ dùng database EquipmentRentalDb."
            );
        settings.InitialCatalog = "master";
        using (var master = new SqlConnection(settings.ConnectionString))
            master.Execute(
                "IF DB_ID('EquipmentRentalDb') IS NULL CREATE DATABASE EquipmentRentalDb"
            );
        using var connection = new SqlConnection(cs);
        connection.Execute(File.ReadAllText(Path.Combine(root, "Data", "schema.sql")));
        connection.Execute(File.ReadAllText(Path.Combine(root, "Data", "demo_data.sql")));
        foreach (
            var account in new[]
            {
                new
                {
                    Email = "admin@rental.com",
                    Password = "Admin@123",
                    Name = "Quản trị viên",
                    Role = "Admin",
                },
                new
                {
                    Email = "member@rental.com",
                    Password = "Member@123",
                    Name = "Thành viên",
                    Role = "Member",
                },
            }
        )
        {
            if (
                connection.ExecuteScalar<int>(
                    "SELECT COUNT(*) FROM Users WHERE Email=@Email",
                    account
                ) > 0
            )
                continue;
            var id = connection.QuerySingle<int>(
                "INSERT INTO Users(FullName,Email,PasswordHash,PhoneNumber) OUTPUT INSERTED.Id VALUES(@Name,@Email,@hash,'0901234567')",
                new
                {
                    account.Name,
                    account.Email,
                    hash = BCrypt.Net.BCrypt.HashPassword(account.Password),
                }
            );
            connection.Execute(
                "INSERT INTO UserRoles(UserId,RoleId) SELECT @id,Id FROM Roles WHERE Name=@Role",
                new { id, account.Role }
            );
        }
    }
}

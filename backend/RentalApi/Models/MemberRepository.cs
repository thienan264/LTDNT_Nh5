using System.Data;
using Dapper;
using RentalApi.DTOs;
using RentalApi.Entities;

namespace RentalApi.Models;

public class MemberRepository : BaseRepository
{
    public MemberRepository(IDbConnection connection)
        : base(connection) { }

    public User? GetByEmail(string email) =>
        connection.QuerySingleOrDefault<User>(
            "SELECT * FROM Users WHERE Email=@email",
            new { email = email.Trim().ToLower() }
        );

    public User? GetMember(int id) =>
        connection.QuerySingleOrDefault<User>("SELECT * FROM Users WHERE Id=@id", new { id });

    public List<string> GetRoles(int id) =>
        connection
            .Query<string>(
                "SELECT r.Name FROM Roles r JOIN UserRoles ur ON ur.RoleId=r.Id WHERE ur.UserId=@id",
                new { id }
            )
            .ToList();

    public UserProfileDto Profile(int id)
    {
        var u = GetMember(id) ?? throw new ArgumentException("Không tìm thấy tài khoản.");
        return new()
        {
            Id = u.Id,
            FullName = u.FullName,
            Email = u.Email,
            PhoneNumber = u.PhoneNumber,
            Address = u.Address,
            AvatarUrl = u.AvatarUrl,
            IsActive = u.IsActive,
            CreatedAt = u.CreatedAt,
            Roles = GetRoles(id),
        };
    }

    public int Add(RegisterRequest obj)
    {
        if (connection.State != ConnectionState.Open)
            connection.Open();
        using var tx = connection.BeginTransaction();
        var id = connection.QuerySingle<int>(
            "INSERT INTO Users(FullName,Email,PasswordHash,PhoneNumber,Address) OUTPUT INSERTED.Id VALUES(@FullName,@Email,@PasswordHash,@PhoneNumber,@Address)",
            new
            {
                obj.FullName,
                Email = obj.Email.Trim().ToLower(),
                PasswordHash = BCrypt.Net.BCrypt.HashPassword(obj.Password),
                obj.PhoneNumber,
                obj.Address,
            },
            tx
        );
        connection.Execute(
            "INSERT INTO UserRoles(UserId,RoleId) SELECT @id,Id FROM Roles WHERE Name='Member'",
            new { id },
            tx
        );
        tx.Commit();
        return id;
    }

    public void ChangePassword(int id, string password) =>
        connection.Execute(
            "UPDATE Users SET PasswordHash=@hash WHERE Id=@id",
            new { id, hash = BCrypt.Net.BCrypt.HashPassword(password) }
        );

    public PagedResult<UserManagementDto> GetMembers(UserQueryParameters p)
    {
        var users = connection
            .Query<UserManagementDto>(
                "SELECT u.*,(SELECT COUNT(*) FROM Rentals WHERE UserId=u.Id) RentalCount FROM Users u ORDER BY Id"
            )
            .ToList();
        foreach (var u in users)
            u.Roles = GetRoles(u.Id);
        users = users
            .Where(u =>
                (
                    string.IsNullOrWhiteSpace(p.Keyword)
                    || u.FullName.Contains(p.Keyword, StringComparison.OrdinalIgnoreCase)
                    || u.Email.Contains(p.Keyword, StringComparison.OrdinalIgnoreCase)
                )
                && (!p.IsActive.HasValue || u.IsActive == p.IsActive)
                && (
                    string.IsNullOrWhiteSpace(p.Role)
                    || u.Roles.Contains(p.Role, StringComparer.OrdinalIgnoreCase)
                )
            )
            .ToList();
        var size = Math.Clamp(p.PageSize, 1, 100);
        return new()
        {
            Items = users.Skip((Math.Max(1, p.PageIndex) - 1) * size).Take(size).ToList(),
            TotalCount = users.Count,
            PageIndex = Math.Max(1, p.PageIndex),
            PageSize = size,
        };
    }

    public void SetRoles(int id, List<string> roles)
    {
        if (roles.Count == 0 || roles.Any(r => r != "Admin" && r != "Member"))
            throw new ArgumentException("Role chỉ được là Admin hoặc Member.");
        if (connection.State != ConnectionState.Open)
            connection.Open();
        using var tx = connection.BeginTransaction();
        connection.Execute("DELETE FROM UserRoles WHERE UserId=@id", new { id }, tx);
        foreach (var role in roles.Distinct())
            connection.Execute(
                "INSERT INTO UserRoles(UserId,RoleId) SELECT @id,Id FROM Roles WHERE Name=@role",
                new { id, role },
                tx
            );
        tx.Commit();
    }

    public void SetStatus(int id, bool active) =>
        connection.Execute("UPDATE Users SET IsActive=@active WHERE Id=@id", new { id, active });
}

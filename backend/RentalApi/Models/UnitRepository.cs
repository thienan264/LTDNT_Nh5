using System.Data;
using Dapper;
using RentalApi.DTOs;
using RentalApi.Entities;

namespace RentalApi.Models;

public class UnitRepository : BaseRepository
{
    public UnitRepository(IDbConnection connection)
        : base(connection) { }

    public List<UnitDto> GetUnits() =>
        connection
            .Query<UnitDto>(
                "SELECT u.*,(SELECT COUNT(*) FROM Devices WHERE UnitId=u.Id) DeviceCount FROM Units u ORDER BY Id"
            )
            .ToList();

    public UnitDto? GetUnit(int id) => GetUnits().Find(u => u.Id == id);

    public int Add(CreateUnitRequest obj) =>
        connection.QuerySingle<int>(
            "INSERT INTO Units(Name,Address,PhoneNumber,ContactPerson,Email,IsActive) OUTPUT INSERTED.Id VALUES(@Name,@Address,@PhoneNumber,@ContactPerson,@Email,@IsActive)",
            obj
        );

    public int Edit(int id, UpdateUnitRequest obj) =>
        connection.Execute(
            "UPDATE Units SET Name=@Name,Address=@Address,PhoneNumber=@PhoneNumber,ContactPerson=@ContactPerson,Email=@Email,IsActive=@IsActive WHERE Id=@id",
            new
            {
                id,
                obj.Name,
                obj.Address,
                obj.PhoneNumber,
                obj.ContactPerson,
                obj.Email,
                obj.IsActive,
            }
        );

    public int Delete(int id) =>
        connection.Execute(
            "DELETE FROM Units WHERE Id=@id AND NOT EXISTS(SELECT 1 FROM Devices WHERE UnitId=@id) AND NOT EXISTS(SELECT 1 FROM Rentals WHERE UnitId=@id)",
            new { id }
        );
}

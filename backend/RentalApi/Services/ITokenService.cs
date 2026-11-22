using RentalApi.Entities;

namespace RentalApi.Services;

public interface ITokenService
{
    string GenerateToken(User user, IEnumerable<string> roles);
}

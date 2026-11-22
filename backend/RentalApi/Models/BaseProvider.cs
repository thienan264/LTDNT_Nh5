using System.Data;
using Microsoft.Data.SqlClient;

namespace RentalApi.Models;

public abstract class BaseProvider : IDisposable
{
    private IDbConnection? connection;
    private readonly IConfiguration configuration;

    protected BaseProvider(IConfiguration configuration)
    {
        this.configuration = configuration;
    }

    protected IDbConnection Connection =>
        connection ??= new SqlConnection(configuration.GetConnectionString("DefaultConnection"));

    public void Dispose()
    {
        connection?.Dispose();
    }
}

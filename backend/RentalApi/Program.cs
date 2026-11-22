using System.Text;
using System.Text.Json.Serialization;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.Data.SqlClient;
using Microsoft.IdentityModel.Tokens;
using RentalApi.Data;
using RentalApi.Models;
using RentalApi.Services;

Directory.CreateDirectory(Path.Combine(Directory.GetCurrentDirectory(), "wwwroot", "uploads"));
var builder = WebApplication.CreateBuilder(args);
builder.Services.AddScoped<SiteProvider>();
builder.Services.AddScoped<ITokenService, TokenService>();
builder.Services.AddScoped<IFileStorageService, FileStorageService>();
builder
    .Services.AddControllers()
    .AddJsonOptions(p => p.JsonSerializerOptions.Converters.Add(new JsonStringEnumConverter()));
builder.Services.AddCors();
builder
    .Services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddJwtBearer(p =>
    {
        p.TokenValidationParameters = new TokenValidationParameters
        {
            ValidateIssuerSigningKey = true,
            ValidateIssuer = true,
            ValidateAudience = true,
            ValidateLifetime = true,
            ValidIssuer = builder.Configuration["Jwt:Issuer"],
            ValidAudience = builder.Configuration["Jwt:Audience"],
            IssuerSigningKey = new SymmetricSecurityKey(
                Encoding.UTF8.GetBytes(builder.Configuration["Jwt:Key"]!)
            ),
            ClockSkew = TimeSpan.Zero,
        };
    });
builder.Services.AddAuthorization();

// Dùng script SQL thay vì EF Migration, giống bài mẫu của thầy.
DatabaseSetup.Initialize(builder.Configuration, builder.Environment.ContentRootPath);
var app = builder.Build();
app.Use(
    async (context, next) =>
    {
        try
        {
            await next();
        }
        catch (ArgumentException ex)
        {
            context.Response.StatusCode = 400;
            await context.Response.WriteAsJsonAsync(new { message = ex.Message });
        }
        catch (SqlException ex) when (ex.Number is 2601 or 2627 or 547)
        {
            context.Response.StatusCode = 400;
            await context.Response.WriteAsJsonAsync(
                new
                {
                    message = "Dữ liệu trùng hoặc đang được tham chiếu. Kiểm tra danh mục, serial, đơn vị.",
                }
            );
        }
    }
);
Directory.CreateDirectory(Path.Combine(app.Environment.ContentRootPath, "wwwroot", "uploads"));
app.UseStaticFiles();
app.UseCors(p => p.AllowAnyOrigin().AllowAnyHeader().AllowAnyMethod());
app.UseAuthentication();
app.UseAuthorization();
app.MapControllers();
app.MapGet(
    "/",
    () =>
        new
        {
            application = "Equipment Rental",
            framework = ".NET 10",
            database = "SQL Server",
            dataAccess = "Dapper",
        }
);
app.Run();

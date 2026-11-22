using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using RentalApi.DTOs;
using RentalApi.Entities;
using RentalApi.Services;

namespace RentalApi.Controllers;

[ApiController, Route("api/auth")]
public class AuthController : BaseController
{
    private readonly ITokenService tokens;

    public AuthController(ITokenService tokens)
    {
        this.tokens = tokens;
    }

    private AuthResponse Result(int id)
    {
        var user = Provider.Member.GetMember(id)!;
        return new()
        {
            Token = tokens.GenerateToken(user, Provider.Member.GetRoles(id)),
            ExpiresAt = DateTime.UtcNow.AddHours(24),
            User = Provider.Member.Profile(id),
        };
    }

    [HttpPost("register")]
    public IActionResult Register(RegisterRequest obj)
    {
        if (Provider.Member.GetByEmail(obj.Email) != null)
            return BadRequest(new { message = "Email đã được đăng ký." });
        return Ok(Result(Provider.Member.Add(obj)));
    }

    [HttpPost("login")]
    public IActionResult Login(LoginRequest obj)
    {
        var user = Provider.Member.GetByEmail(obj.Email);
        if (user == null || !BCrypt.Net.BCrypt.Verify(obj.Password, user.PasswordHash))
            return Unauthorized(new { message = "Email hoặc mật khẩu không chính xác." });
        if (!user.IsActive)
            return StatusCode(403, new { message = "Tài khoản đã bị khóa." });
        return Ok(Result(user.Id));
    }

    [Authorize, HttpGet("profile")]
    public IActionResult Profile() => Ok(Provider.Member.Profile(CurrentUserId));

    [Authorize, HttpPost("change-password")]
    public IActionResult ChangePassword(ChangePasswordRequest obj)
    {
        var user = Provider.Member.GetMember(CurrentUserId);
        if (user == null || !BCrypt.Net.BCrypt.Verify(obj.CurrentPassword, user.PasswordHash))
            return BadRequest(new { message = "Mật khẩu hiện tại không đúng." });
        Provider.Member.ChangePassword(CurrentUserId, obj.NewPassword);
        return Ok(new { message = "Đổi mật khẩu thành công." });
    }
}

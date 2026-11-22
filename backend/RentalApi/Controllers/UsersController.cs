using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using RentalApi.DTOs;
using RentalApi.Entities;
using RentalApi.Services;

namespace RentalApi.Controllers;

[ApiController, Route("api/users"), Authorize(Roles = "Admin")]
public class UsersController : BaseController
{
    [HttpGet]
    public IActionResult GetAll([FromQuery] UserQueryParameters p) =>
        Ok(Provider.Member.GetMembers(p));

    [HttpGet("roles")]
    public IActionResult Roles() => Ok(new[] { "Admin", "Member" });

    [HttpPut("{id}/roles")]
    public IActionResult SetRoles(int id, UpdateUserRolesRequest obj)
    {
        if (Provider.Member.GetMember(id) == null)
            return NotFound();
        if (id == CurrentUserId && !obj.Roles.Contains("Admin"))
            return BadRequest(new { message = "Không thể tự gỡ quyền Admin." });
        Provider.Member.SetRoles(id, obj.Roles);
        return Ok(Provider.Member.Profile(id));
    }

    [HttpPut("{id}/status")]
    public IActionResult SetStatus(int id, UpdateUserStatusRequest obj)
    {
        if (Provider.Member.GetMember(id) == null)
            return NotFound();
        if (id == CurrentUserId && !obj.IsActive)
            return BadRequest(new { message = "Không thể tự khóa tài khoản." });
        Provider.Member.SetStatus(id, obj.IsActive);
        return Ok(new { message = "Đã cập nhật trạng thái." });
    }
}

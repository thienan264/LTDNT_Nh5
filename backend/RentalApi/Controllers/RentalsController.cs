using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using RentalApi.DTOs;
using RentalApi.Entities;
using RentalApi.Services;

namespace RentalApi.Controllers;

[ApiController, Route("api/rentals"), Authorize]
public class RentalsController : BaseController
{
    [HttpPost("checkout")]
    public IActionResult Checkout(CreateRentalCheckoutRequest obj)
    {
        if (Provider.Member.GetMember(CurrentUserId)?.IsActive != true)
            return Unauthorized();
        var id = Provider.Rental.Checkout(CurrentUserId, obj);
        return CreatedAtAction(nameof(Get), new { id }, Provider.Rental.GetRental(id));
    }

    [HttpGet("my")]
    public IActionResult Mine() => Ok(Provider.Rental.GetMine(CurrentUserId));

    [HttpGet("{id}")]
    public IActionResult Get(int id)
    {
        var r = Provider.Rental.GetRental(id);
        if (r == null)
            return NotFound();
        if (r.UserId != CurrentUserId && !User.IsInRole("Admin"))
            return Forbid();
        return Ok(r);
    }

    [HttpGet, Authorize(Roles = "Admin")]
    public IActionResult GetAll([FromQuery] RentalQueryParameters p) =>
        Ok(Provider.Rental.GetRentals(p));

    [HttpPut("{id}/status"), Authorize(Roles = "Admin")]
    public IActionResult Status(int id, UpdateRentalStatusRequest obj)
    {
        if (Provider.Rental.GetRental(id) == null)
            return NotFound();
        Provider.Rental.SetStatus(id, obj);
        return Ok(Provider.Rental.GetRental(id));
    }

    [HttpGet("{id}/handover")]
    public IActionResult Logs(int id)
    {
        var r = Provider.Rental.GetRental(id);
        if (r == null)
            return NotFound();
        if (r.UserId != CurrentUserId && !User.IsInRole("Admin"))
            return Forbid();
        return Ok(Provider.Rental.GetLogs(id));
    }

    [HttpPost("{id}/handover"), Authorize(Roles = "Admin")]
    public IActionResult AddLog(int id, HandoverRequest obj)
    {
        if (Provider.Rental.GetRental(id) == null)
            return NotFound();
        Provider.Rental.AddLog(id, obj);
        return Ok(new { message = "Đã lưu biên bản và cập nhật trạng thái." });
    }
}

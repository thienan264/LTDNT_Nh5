using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using RentalApi.DTOs;
using RentalApi.Entities;
using RentalApi.Services;

namespace RentalApi.Controllers;

[ApiController, Route("api/units")]
public class UnitsController : BaseController
{
    [HttpGet]
    public IActionResult GetAll() => Ok(Provider.Unit.GetUnits());

    [HttpPost, Authorize(Roles = "Admin")]
    public IActionResult Add(CreateUnitRequest obj)
    {
        var id = Provider.Unit.Add(obj);
        return Ok(Provider.Unit.GetUnit(id));
    }

    [HttpPut("{id}"), Authorize(Roles = "Admin")]
    public IActionResult Edit(int id, UpdateUnitRequest obj)
    {
        if (Provider.Unit.Edit(id, obj) == 0)
            return NotFound();
        return Ok(Provider.Unit.GetUnit(id));
    }

    [HttpDelete("{id}"), Authorize(Roles = "Admin")]
    public IActionResult Delete(int id) =>
        Provider.Unit.Delete(id) > 0
            ? Ok(new { message = "Đã xóa đơn vị." })
            : BadRequest(new { message = "Đơn vị không tồn tại hoặc đang có thiết bị/hợp đồng." });
}

using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using RentalApi.DTOs;
using RentalApi.Entities;
using RentalApi.Services;

namespace RentalApi.Controllers;

[ApiController, Route("api/devices")]
public class DevicesController : BaseController
{
    private readonly IFileStorageService files;

    public DevicesController(IFileStorageService files)
    {
        this.files = files;
    }

    private int? ViewerId => User.Identity?.IsAuthenticated == true ? CurrentUserId : null;

    [HttpGet]
    public IActionResult GetAll([FromQuery] DeviceQueryParameters p) =>
        Ok(Provider.Device.GetDevices(p, User.IsInRole("Admin"), viewerId: ViewerId));

    [HttpGet("lookup")]
    public IActionResult Lookup([FromQuery] string code)
    {
        var d = Provider.Device.Lookup(code, ViewerId);
        return d == null || !d.IsActive && !User.IsInRole("Admin") ? NotFound() : Ok(d);
    }

    [HttpGet("{id}/history"), Authorize]
    public IActionResult History(int id) => Ok(Provider.Device.History(id, User.IsInRole("Admin") ? null : CurrentUserId));

    [HttpGet("{id:int}")]
    public IActionResult Get(int id)
    {
        var d = Provider.Device.GetDevice(id, ViewerId);
        return d == null || !d.IsActive && !User.IsInRole("Admin") ? NotFound() : Ok(d);
    }

    [HttpGet("{id}/related")]
    public IActionResult Related(
        int id,
        [FromQuery] int pageIndex = 1,
        [FromQuery] int pageSize = 5
    )
    {
        var d = Provider.Device.GetDevice(id, ViewerId);
        if (d == null)
            return NotFound();
        return Ok(
            Provider.Device.GetDevices(
                new DeviceQueryParameters
                {
                    CategoryId = d.CategoryId,
                    PageIndex = pageIndex,
                    PageSize = pageSize,
                },
                User.IsInRole("Admin"),
                id,
                ViewerId
            )
        );
    }

    [HttpPost, Authorize(Roles = "Admin")]
    public IActionResult Add(CreateDeviceRequest obj)
    {
        var id = Provider.Device.Add(obj);
        return CreatedAtAction(nameof(Get), new { id }, Provider.Device.GetDevice(id, ViewerId));
    }

    [HttpPut("{id}"), Authorize(Roles = "Admin")]
    public IActionResult Edit(int id, UpdateDeviceRequest obj)
    {
        var old = Provider.Device.GetDevice(id, ViewerId);
        if (old == null)
            return NotFound();
        if (old.Status != obj.Status && Provider.Device.HasActiveRental(id))
            return BadRequest(
                new { message = "Thiết bị đang thuộc hợp đồng; hãy cập nhật qua hợp đồng." }
            );
        Provider.Device.Edit(id, obj);
        if (old.ImageUrl != obj.ImageUrl)
            files.DeleteFile(old.ImageUrl);
        return Ok(Provider.Device.GetDevice(id, ViewerId));
    }

    [HttpPut("{id}/status"), Authorize(Roles = "Admin")]
    public IActionResult UpdateStatus(int id, UpdateDeviceStatusRequest obj)
    {
        if (Provider.Device.GetDevice(id, ViewerId) == null)
            return NotFound();
        Provider.Device.UpdateStatus(id, obj.Status);
        return Ok(Provider.Device.GetDevice(id, ViewerId));
    }

    [HttpDelete("{id}"), Authorize(Roles = "Admin")]
    public IActionResult Delete(int id)
    {
        var old = Provider.Device.GetDevice(id, ViewerId);
        if (old == null)
            return NotFound();
        if (Provider.Device.Delete(id) == 0)
            return BadRequest(new { message = "Thiết bị đã có trong hợp đồng, không thể xóa." });
        files.DeleteFile(old.ImageUrl);
        return Ok(new { message = "Đã xóa thiết bị." });
    }

    [HttpPost("{id}/upload-image"), Authorize(Roles = "Admin")]
    public async Task<IActionResult> Upload(int id, [FromForm] FileUploadDto obj)
    {
        var old = Provider.Device.GetDevice(id, ViewerId);
        if (old == null)
            return NotFound();
        var url = await files.SaveFileAsync(obj.File, "devices");
        Provider.Device.SetImage(id, url);
        files.DeleteFile(old.ImageUrl);
        return Ok(new { imageUrl = url });
    }
}

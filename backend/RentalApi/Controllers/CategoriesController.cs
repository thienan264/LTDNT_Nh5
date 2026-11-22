using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using RentalApi.DTOs;
using RentalApi.Entities;
using RentalApi.Services;

namespace RentalApi.Controllers;

[ApiController, Route("api/categories")]
public class CategoriesController : BaseController
{
    private readonly IFileStorageService files;

    public CategoriesController(IFileStorageService files)
    {
        this.files = files;
    }

    [HttpGet]
    public IActionResult GetAll([FromQuery] bool includeInactive = false) =>
        Ok(Provider.Category.GetCategories(includeInactive && User.IsInRole("Admin")));

    [HttpGet("{id}")]
    public IActionResult Get(int id)
    {
        var category = Provider.Category.GetCategory(id);
        if (category == null)
            return NotFound();
        return Ok(category);
    }

    [HttpPost, Authorize(Roles = "Admin")]
    public IActionResult Add(CreateCategoryRequest obj)
    {
        var id = Provider.Category.Add(obj);
        return CreatedAtAction(nameof(Get), new { id }, Provider.Category.GetCategory(id));
    }

    [HttpPut("{id}"), Authorize(Roles = "Admin")]
    public IActionResult Edit(int id, UpdateCategoryRequest obj)
    {
        var old = Provider.Category.GetCategory(id);
        if (old == null)
            return NotFound();
        Provider.Category.Edit(id, obj);
        if (old.ImageUrl != obj.ImageUrl)
            files.DeleteFile(old.ImageUrl);
        return Ok(Provider.Category.GetCategory(id));
    }

    [HttpDelete("{id}"), Authorize(Roles = "Admin")]
    public IActionResult Delete(int id)
    {
        var old = Provider.Category.GetCategory(id);
        if (old == null)
            return NotFound();
        if (Provider.Category.Delete(id) == 0)
            return BadRequest(new { message = "Danh mục đang có thiết bị, không thể xóa." });
        files.DeleteFile(old.ImageUrl);
        return Ok(new { message = "Đã xóa danh mục." });
    }

    [HttpPost("{id}/upload-image"), Authorize(Roles = "Admin")]
    public async Task<IActionResult> Upload(int id, [FromForm] FileUploadDto obj)
    {
        var old = Provider.Category.GetCategory(id);
        if (old == null)
            return NotFound();
        var url = await files.SaveFileAsync(obj.File, "categories");
        Provider.Category.SetImage(id, url);
        files.DeleteFile(old.ImageUrl);
        return Ok(new { imageUrl = url });
    }
}

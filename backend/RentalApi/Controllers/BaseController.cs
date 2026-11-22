using System.Security.Claims;
using Microsoft.AspNetCore.Mvc;
using RentalApi.Models;

namespace RentalApi.Controllers;

public abstract class BaseController : ControllerBase
{
    protected SiteProvider Provider =>
        HttpContext.RequestServices.GetRequiredService<SiteProvider>();
    protected int CurrentUserId => int.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
}

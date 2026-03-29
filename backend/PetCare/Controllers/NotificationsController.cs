using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using PetCare.DTOs;
using PetCare.Entities;
using PetCare.Repositories;

namespace PetCare.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize]
public class NotificationsController : ControllerBase
{
    private readonly IUnitOfWork _unitOfWork;

    public NotificationsController(IUnitOfWork unitOfWork)
    {
        _unitOfWork = unitOfWork;
    }

    [HttpGet]
    public async Task<ActionResult<ApiResponse<IEnumerable<Notification>>>> GetMyNotifications()
    {
        var userIdClaim = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value;
        if (!int.TryParse(userIdClaim, out var currentUserId))
        {
            return Unauthorized(ApiResponse<IEnumerable<Notification>>.ErrorResponse("Unauthorized"));
        }
        var list = await _unitOfWork.Notifications.FindAsync(n => n.UserId == currentUserId);
        return Ok(ApiResponse<IEnumerable<Notification>>.SuccessResponse(list.OrderByDescending(n => n.CreatedAt)));
    }

    [HttpPut("{id:int}/read")]
    public async Task<ActionResult<ApiResponse<object>>> MarkRead(int id)
    {
        var userIdClaim = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value;
        if (!int.TryParse(userIdClaim, out var currentUserId))
        {
            return Unauthorized(ApiResponse<object>.ErrorResponse("Unauthorized"));
        }
        var n = await _unitOfWork.Notifications.GetByIdAsync(id);
        if (n == null || n.UserId != currentUserId)
        {
            return NotFound(ApiResponse<object>.ErrorResponse("Not found"));
        }
        n.IsRead = true;
        await _unitOfWork.Notifications.UpdateAsync(n);
        return Ok(ApiResponse<object>.SuccessResponse(null, "Marked read"));
    }
}



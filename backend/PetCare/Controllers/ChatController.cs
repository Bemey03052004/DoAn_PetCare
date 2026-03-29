using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using PetCare.DTOs;
using PetCare.Entities;
using PetCare.Repositories;

namespace PetCare.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize]
public class ChatController : ControllerBase
{
    private readonly IUnitOfWork _unitOfWork;

    public ChatController(IUnitOfWork unitOfWork)
    {
        _unitOfWork = unitOfWork;
    }

    [HttpGet("rooms")]
    public async Task<ActionResult<ApiResponse<IEnumerable<ChatRoom>>>> GetMyRooms()
    {
        var userIdClaim = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value;
        if (!int.TryParse(userIdClaim, out var currentUserId))
        {
            return Unauthorized(ApiResponse<IEnumerable<ChatRoom>>.ErrorResponse("Unauthorized"));
        }
        var rooms = await _unitOfWork.ChatRooms.FindAsync(c => c.User1Id == currentUserId || c.User2Id == currentUserId);
        return Ok(ApiResponse<IEnumerable<ChatRoom>>.SuccessResponse(rooms));
    }

    [HttpGet("rooms/{roomId:int}/messages")]
    public async Task<ActionResult<ApiResponse<IEnumerable<Message>>>> GetMessages(int roomId, [FromQuery] int? take = 50, [FromQuery] int? beforeId = null)
    {
        var userIdClaim = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value;
        if (!int.TryParse(userIdClaim, out var currentUserId))
        {
            return Unauthorized(ApiResponse<IEnumerable<Message>>.ErrorResponse("Unauthorized"));
        }
        var room = await _unitOfWork.ChatRooms.GetByIdAsync(roomId);
        if (room == null || (room.User1Id != currentUserId && room.User2Id != currentUserId))
        {
            return Forbid();
        }
        var query = (await _unitOfWork.Messages.FindAsync(m => m.ChatRoomId == roomId)).AsQueryable();
        if (beforeId.HasValue)
        {
            query = query.Where(m => m.Id < beforeId.Value);
        }
        var messages = query
            .OrderByDescending(m => m.Id)
            .Take(take ?? 50)
            .OrderBy(m => m.Id)
            .ToList();
        return Ok(ApiResponse<IEnumerable<Message>>.SuccessResponse(messages));
    }
}



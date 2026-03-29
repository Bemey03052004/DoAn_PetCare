using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using PetCare.DTOs;
using PetCare.Repositories;
using System.Security.Claims;

namespace PetCare.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize]
public class LoginSessionController : ControllerBase
{
    private readonly IUnitOfWork _unitOfWork;

    public LoginSessionController(IUnitOfWork unitOfWork)
    {
        _unitOfWork = unitOfWork;
    }

    [HttpGet("my-sessions")]
    public async Task<ActionResult<ApiResponse<List<LoginSessionDto>>>> GetMySessions()
    {
        try
        {
            var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier);
            if (userIdClaim == null || !int.TryParse(userIdClaim.Value, out int userId))
            {
                return Unauthorized(ApiResponse<List<LoginSessionDto>>.ErrorResponse("Invalid user"));
            }

            var sessions = await _unitOfWork.LoginSessions.GetActiveSessionsByUserIdAsync(userId);
            var currentRefreshToken = GetCurrentRefreshToken();

            var sessionDtos = sessions.Select(s => new LoginSessionDto
            {
                Id = s.Id,
                DeviceName = s.DeviceName,
                DeviceType = s.DeviceType,
                Location = s.Location,
                IpAddress = s.IpAddress,
                CreatedAt = s.CreatedAt,
                ExpiresAt = s.ExpiresAt,
                LastUsedAt = s.LastUsedAt,
                IsActive = s.IsActive,
                IsCurrent = s.RefreshToken == currentRefreshToken
            }).ToList();

            return Ok(ApiResponse<List<LoginSessionDto>>.SuccessResponse(sessionDtos, "Sessions retrieved successfully"));
        }
        catch (Exception ex)
        {
            return StatusCode(500, ApiResponse<List<LoginSessionDto>>.ErrorResponse("An error occurred while retrieving sessions", new List<string> { ex.Message }));
        }
    }

    [HttpDelete("revoke/{sessionId}")]
    public async Task<ActionResult<ApiResponse<object>>> RevokeSession(int sessionId)
    {
        try
        {
            var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier);
            if (userIdClaim == null || !int.TryParse(userIdClaim.Value, out int userId))
            {
                return Unauthorized(ApiResponse<object>.ErrorResponse("Invalid user"));
            }

            // Check if the session belongs to the current user
            var session = await _unitOfWork.LoginSessions.GetByIdAsync(sessionId);
            if (session == null || session.UserId != userId)
            {
                return NotFound(ApiResponse<object>.ErrorResponse("Session not found"));
            }

            await _unitOfWork.LoginSessions.RevokeSessionAsync(sessionId);
            await _unitOfWork.SaveAsync();

            return Ok(ApiResponse<object>.SuccessResponse(null, "Session revoked successfully"));
        }
        catch (Exception ex)
        {
            return StatusCode(500, ApiResponse<object>.ErrorResponse("An error occurred while revoking session", new List<string> { ex.Message }));
        }
    }

    [HttpDelete("revoke-all")]
    public async Task<ActionResult<ApiResponse<object>>> RevokeAllSessions()
    {
        try
        {
            var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier);
            if (userIdClaim == null || !int.TryParse(userIdClaim.Value, out int userId))
            {
                return Unauthorized(ApiResponse<object>.ErrorResponse("Invalid user"));
            }

            await _unitOfWork.LoginSessions.RevokeAllUserSessionsAsync(userId);
            await _unitOfWork.SaveAsync();

            return Ok(ApiResponse<object>.SuccessResponse(null, "All sessions revoked successfully"));
        }
        catch (Exception ex)
        {
            return StatusCode(500, ApiResponse<object>.ErrorResponse("An error occurred while revoking sessions", new List<string> { ex.Message }));
        }
    }

    private string? GetCurrentRefreshToken()
    {
        // In a real implementation, you might get this from the request header or context
        // For now, we'll return null and rely on other methods to identify current session
        return Request.Headers["X-Refresh-Token"].FirstOrDefault();
    }
}

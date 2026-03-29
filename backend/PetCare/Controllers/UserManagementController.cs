using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using PetCare.DTOs;
using PetCare.Services;
using FluentValidation;

namespace PetCare.Controllers;

[ApiController]
[Route("api/users")] // User management for regular users
public class UserManagementController : ControllerBase
{
    private readonly IUserService _userService;
    private readonly IValidator<UserUpdateDto> _updateValidator;

    public UserManagementController(IUserService userService, IValidator<UserUpdateDto> updateValidator)
    {
        _userService = userService;
        _updateValidator = updateValidator;
    }

    [HttpGet]
    [Authorize(Roles = "Admin")]
    public async Task<ActionResult<ApiResponse<IEnumerable<UserResponseDto>>>> GetAllUsers()
    {
        try
        {
            var users = await _userService.GetAllUsersAsync();
            return Ok(ApiResponse<IEnumerable<UserResponseDto>>.SuccessResponse(users, "Users retrieved successfully"));
        }
        catch (Exception ex)
        {
            return StatusCode(500, ApiResponse<IEnumerable<UserResponseDto>>.ErrorResponse($"Error retrieving users: {ex.Message}"));
        }
    }

    [HttpGet("{id:int}")]
    [Authorize]
    public async Task<ActionResult<ApiResponse<UserResponseDto>>> GetUserById(int id)
    {
        try
        {
            // Check if the authenticated user is requesting their own data or is an admin
            var userId = int.Parse(User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value ?? "0");
            var isAdmin = User.IsInRole("Admin");

            if (userId != id && !isAdmin)
            {
                return Forbid();
            }

            var user = await _userService.GetUserByIdAsync(id);
            return Ok(ApiResponse<UserResponseDto>.SuccessResponse(user, "User retrieved successfully"));
        }
        catch (KeyNotFoundException ex)
        {
            return NotFound(ApiResponse<UserResponseDto>.ErrorResponse(ex.Message));
        }
        catch (Exception ex)
        {
            return StatusCode(500, ApiResponse<UserResponseDto>.ErrorResponse($"Error retrieving user: {ex.Message}"));
        }
    }

    [HttpGet("profile")]
    [Authorize]
    public async Task<ActionResult<ApiResponse<UserResponseDto>>> GetProfile()
    {
        try
        {
            // Get the authenticated user's ID
            var userId = int.Parse(User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value ?? "0");
            if (userId == 0)
            {
                return Unauthorized(ApiResponse<UserResponseDto>.ErrorResponse("User not authenticated"));
            }

            var user = await _userService.GetUserByIdAsync(userId);
            return Ok(ApiResponse<UserResponseDto>.SuccessResponse(user, "Profile retrieved successfully"));
        }
        catch (KeyNotFoundException ex)
        {
            return NotFound(ApiResponse<UserResponseDto>.ErrorResponse(ex.Message));
        }
        catch (Exception ex)
        {
            return StatusCode(500, ApiResponse<UserResponseDto>.ErrorResponse($"Error retrieving profile: {ex.Message}"));
        }
    }

    [HttpGet("{id:int}/basic")]
    [Authorize]
    public async Task<ActionResult<ApiResponse<object>>> GetUserBasicInfo(int id)
    {
        try
        {
            var user = await _userService.GetUserByIdAsync(id);
            var basicInfo = new
            {
                Id = user.Id,
                FullName = user.FullName,
                Email = user.Email
            };
            return Ok(ApiResponse<object>.SuccessResponse(basicInfo, "User basic info retrieved successfully"));
        }
        catch (KeyNotFoundException ex)
        {
            return NotFound(ApiResponse<object>.ErrorResponse(ex.Message));
        }
        catch (Exception ex)
        {
            return StatusCode(500, ApiResponse<object>.ErrorResponse($"Error retrieving user basic info: {ex.Message}"));
        }
    }

    [HttpGet("test")]
    [Authorize]
    public async Task<ActionResult<ApiResponse<object>>> TestUsers()
    {
        try
        {
            var users = await _userService.GetAllUsersAsync();
            var userCount = users.Count();
            var firstUser = users.FirstOrDefault();
            
            var testInfo = new
            {
                TotalUsers = userCount,
                FirstUser = firstUser != null ? new
                {
                    Id = firstUser.Id,
                    FullName = firstUser.FullName,
                    Email = firstUser.Email
                } : null
            };
            
            return Ok(ApiResponse<object>.SuccessResponse(testInfo, "Test users info retrieved successfully"));
        }
        catch (Exception ex)
        {
            return StatusCode(500, ApiResponse<object>.ErrorResponse($"Error testing users: {ex.Message}"));
        }
    }

    [HttpPut("profile")]
    [Authorize]
    public async Task<ActionResult<ApiResponse<UserResponseDto>>> UpdateProfile([FromBody] UserUpdateDto updateDto)
    {
        try
        {
            // Get the authenticated user's ID
            var userId = int.Parse(User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value ?? "0");
            if (userId == 0)
            {
                return Unauthorized(ApiResponse<UserResponseDto>.ErrorResponse("User not authenticated"));
            }

            // Validate the update request
            var validationResult = await _updateValidator.ValidateAsync(updateDto);
            if (!validationResult.IsValid)
            {
                var errors = validationResult.Errors.Select(e => $"{e.PropertyName}: {e.ErrorMessage}").ToList();
                return BadRequest(ApiResponse<UserResponseDto>.ErrorResponse("Validation failed", errors));
            }

            var updatedUser = await _userService.UpdateUserAsync(userId, updateDto);
            return Ok(ApiResponse<UserResponseDto>.SuccessResponse(updatedUser, "Profile updated successfully"));
        }
        catch (KeyNotFoundException ex)
        {
            return NotFound(ApiResponse<UserResponseDto>.ErrorResponse(ex.Message));
        }
        catch (InvalidOperationException ex)
        {
            return Conflict(ApiResponse<UserResponseDto>.ErrorResponse(ex.Message));
        }
        catch (Exception ex)
        {
            return StatusCode(500, ApiResponse<UserResponseDto>.ErrorResponse($"Error updating profile: {ex.Message}"));
        }
    }

    [HttpPut("{id:int}")]
    [Authorize]
    public async Task<ActionResult<ApiResponse<UserResponseDto>>> UpdateUser(int id, [FromBody] UserUpdateDto updateDto)
    {
        try
        {
            // Check if the authenticated user is updating their own data or is an admin
            var userId = int.Parse(User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value ?? "0");
            var isAdmin = User.IsInRole("Admin");

            if (userId != id && !isAdmin)
            {
                return Forbid();
            }

            // Validate the update request
            var validationResult = await _updateValidator.ValidateAsync(updateDto);
            if (!validationResult.IsValid)
            {
                var errors = validationResult.Errors.Select(e => $"{e.PropertyName}: {e.ErrorMessage}").ToList();
                return BadRequest(ApiResponse<UserResponseDto>.ErrorResponse("Validation failed", errors));
            }

            var updatedUser = await _userService.UpdateUserAsync(id, updateDto);
            return Ok(ApiResponse<UserResponseDto>.SuccessResponse(updatedUser, "User updated successfully"));
        }
        catch (KeyNotFoundException ex)
        {
            return NotFound(ApiResponse<UserResponseDto>.ErrorResponse(ex.Message));
        }
        catch (InvalidOperationException ex)
        {
            return Conflict(ApiResponse<UserResponseDto>.ErrorResponse(ex.Message));
        }
        catch (Exception ex)
        {
            return StatusCode(500, ApiResponse<UserResponseDto>.ErrorResponse($"Error updating user: {ex.Message}"));
        }
    }

    [HttpDelete("{id:int}")]
    [Authorize(Roles = "Admin")]
    public async Task<ActionResult<ApiResponse<object>>> DeleteUser(int id)
    {
        try
        {
            var result = await _userService.DeleteUserAsync(id);
            return result
                ? Ok(ApiResponse<object>.SuccessResponse(null, "User deleted successfully"))
                : NotFound(ApiResponse<object>.ErrorResponse($"User with ID {id} not found"));
        }
        catch (Exception ex)
        {
            return StatusCode(500, ApiResponse<object>.ErrorResponse($"Error deleting user: {ex.Message}"));
        }
    }

    [HttpGet("{id:int}/roles")]
    [Authorize]
    public async Task<ActionResult<ApiResponse<IEnumerable<string>>>> GetUserRoles(int id)
    {
        try
        {
            // Check if the authenticated user is requesting their own data or is an admin
            var userId = int.Parse(User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value ?? "0");
            var isAdmin = User.IsInRole("Admin");

            if (userId != id && !isAdmin)
            {
                return Forbid();
            }

            var roles = await _userService.GetUserRolesAsync(id);
            return Ok(ApiResponse<IEnumerable<string>>.SuccessResponse(roles, "User roles retrieved successfully"));
        }
        catch (Exception ex)
        {
            return StatusCode(500, ApiResponse<IEnumerable<string>>.ErrorResponse($"Error retrieving user roles: {ex.Message}"));
        }
    }

    [HttpPost("{id:int}/roles")]
    [Authorize(Roles = "Admin")]
    public async Task<ActionResult<ApiResponse<object>>> AddRoleToUser(int id, [FromBody] UserRoleDto roleDto)
    {
        try
        {
            var result = await _userService.AddRoleToUserAsync(id, roleDto.RoleName);
            return result
                ? Ok(ApiResponse<object>.SuccessResponse(null, $"Role '{roleDto.RoleName}' added to user successfully"))
                : NotFound(ApiResponse<object>.ErrorResponse($"User with ID {id} or role '{roleDto.RoleName}' not found"));
        }
        catch (Exception ex)
        {
            return StatusCode(500, ApiResponse<object>.ErrorResponse($"Error adding role to user: {ex.Message}"));
        }
    }

    [HttpDelete("{id:int}/roles/{roleName}")]
    [Authorize(Roles = "Admin")]
    public async Task<ActionResult<ApiResponse<object>>> RemoveRoleFromUser(int id, string roleName)
    {
        try
        {
            var result = await _userService.RemoveRoleFromUserAsync(id, roleName);
            return result
                ? Ok(ApiResponse<object>.SuccessResponse(null, $"Role '{roleName}' removed from user successfully"))
                : NotFound(ApiResponse<object>.ErrorResponse($"User with ID {id} or role '{roleName}' not found"));
        }
        catch (Exception ex)
        {
            return StatusCode(500, ApiResponse<object>.ErrorResponse($"Error removing role from user: {ex.Message}"));
        }
    }
}
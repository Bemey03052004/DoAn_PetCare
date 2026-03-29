using Microsoft.AspNetCore.Mvc;
using PetCare.DTOs;
using PetCare.Entities;
using PetCare.Repositories;
using Microsoft.AspNetCore.Authorization;

namespace PetCare.Controllers;

[ApiController]
[Route("api/admin/users")]
[Authorize(Roles = "Admin")]
public class UsersController : ControllerBase
{
    private readonly IUnitOfWork _unitOfWork;

    public UsersController(IUnitOfWork unitOfWork)
    {
        _unitOfWork = unitOfWork;
    }

    [HttpGet]
    public async Task<ActionResult<ApiResponse<IEnumerable<UserResponseDto>>>> GetAll()
    {
        var users = await _unitOfWork.Users.GetAllWithPetsAsync();
        var result = new List<UserResponseDto>();
        foreach (var u in users)
        {
            var roles = await _unitOfWork.Users.GetUserRolesAsync(u.Id);
            result.Add(new UserResponseDto
            {
                Id = u.Id,
                FullName = u.FullName,
                Email = u.Email,
                Phone = u.Phone,
                Address = u.Address,
                Latitude = u.Latitude,
                Longitude = u.Longitude,
                Roles = roles.ToList(),
                CreatedAt = u.CreatedAt
            });
        }
        return Ok(ApiResponse<IEnumerable<UserResponseDto>>.SuccessResponse(result));
    }

    [HttpGet("{id:int}")]
    public async Task<ActionResult<ApiResponse<UserResponseDto>>> GetById(int id)
    {
        var user = await _unitOfWork.Users.GetByIdWithPetsAsync(id);
        if (user is null)
        {
            return NotFound(ApiResponse<UserResponseDto>.ErrorResponse("User not found"));
        }
        var roles = await _unitOfWork.Users.GetUserRolesAsync(user.Id);
        var dto = new UserResponseDto
        {
            Id = user.Id,
            FullName = user.FullName,
            Email = user.Email,
            Phone = user.Phone,
            Address = user.Address,
            Latitude = user.Latitude,
            Longitude = user.Longitude,
            Roles = roles.ToList(),
            CreatedAt = user.CreatedAt
        };
        return Ok(ApiResponse<UserResponseDto>.SuccessResponse(dto));
    }

    [HttpPost]
    public async Task<ActionResult<ApiResponse<User>>> Create([FromBody] User user)
    {
        // Check if email is already in use
        if (!await _unitOfWork.Users.IsEmailUniqueAsync(user.Email))
        {
            return Conflict(ApiResponse<User>.ErrorResponse("Email already in use"));
        }

        var createdUser = await _unitOfWork.Users.AddAsync(user);
        return CreatedAtAction(nameof(GetById), new { id = createdUser.Id }, 
            ApiResponse<User>.SuccessResponse(createdUser));
    }

    [HttpPut("{id:int}")]
    public async Task<ActionResult<ApiResponse<User>>> Update(int id, [FromBody] User user)
    {
        var existing = await _unitOfWork.Users.GetByIdAsync(id);
        if (existing is null) 
        {
            return NotFound(ApiResponse<User>.ErrorResponse("User not found"));
        }

        // Check if email is unique if it's changed
        if (existing.Email != user.Email && !await _unitOfWork.Users.IsEmailUniqueAsync(user.Email))
        {
            return Conflict(ApiResponse<User>.ErrorResponse("Email already in use"));
        }

        existing.FullName = user.FullName;
        existing.Email = user.Email;
        existing.Phone = user.Phone;
        existing.Address = user.Address;
        existing.Latitude = user.Latitude;
        existing.Longitude = user.Longitude;
        
        // Don't overwrite password hash unless it's provided
        if (!string.IsNullOrEmpty(user.PasswordHash))
        {
            existing.PasswordHash = user.PasswordHash;
        }

        await _unitOfWork.Users.UpdateAsync(existing);
        return Ok(ApiResponse<User>.SuccessResponse(existing));
    }

    [HttpDelete("{id:int}")]
    public async Task<IActionResult> Delete(int id)
    {
        var existing = await _unitOfWork.Users.GetByIdAsync(id);
        if (existing is null) 
        {
            return NotFound(ApiResponse<User>.ErrorResponse("User not found"));
        }

        await _unitOfWork.Users.DeleteAsync(existing);
        return NoContent();
    }

    // ===== Roles management =====
    [Authorize(Roles = "Admin")]
    [HttpGet("{id:int}/roles")]
    public async Task<ActionResult<ApiResponse<IEnumerable<string>>>> GetUserRoles(int id)
    {
        var user = await _unitOfWork.Users.GetByIdAsync(id);
        if (user is null) return NotFound(ApiResponse<IEnumerable<string>>.ErrorResponse("User not found"));
        var roles = await _unitOfWork.Users.GetUserRolesAsync(id);
        return Ok(ApiResponse<IEnumerable<string>>.SuccessResponse(roles));
    }

    public class AddRoleRequest { public string RoleName { get; set; } = string.Empty; }

    [Authorize(Roles = "Admin")]
    [HttpPost("{id:int}/roles")]
    public async Task<ActionResult<ApiResponse<object>>> AddRole(int id, [FromBody] AddRoleRequest body)
    {
        var user = await _unitOfWork.Users.GetByIdAsync(id);
        if (user is null) return NotFound(ApiResponse<object>.ErrorResponse("User not found"));
        var role = (await _unitOfWork.Roles.FindAsync(r => r.Name == body.RoleName)).FirstOrDefault();
        if (role == null) return NotFound(ApiResponse<object>.ErrorResponse("Role not found"));
        var exists = (await _unitOfWork.UserRoles.FindAsync(ur => ur.UserId == id && ur.RoleId == role.Id)).Any();
        if (exists) return Conflict(ApiResponse<object>.ErrorResponse("Role already assigned"));
        await _unitOfWork.UserRoles.AddAsync(new UserRole { UserId = id, RoleId = role.Id, AssignedAt = DateTime.UtcNow });
        return Ok(ApiResponse<object>.SuccessResponse(null, "Role added"));
    }

    [Authorize(Roles = "Admin")]
    [HttpDelete("{id:int}/roles/{roleName}")]
    public async Task<ActionResult<ApiResponse<object>>> RemoveRole(int id, string roleName)
    {
        var user = await _unitOfWork.Users.GetByIdAsync(id);
        if (user is null) return NotFound(ApiResponse<object>.ErrorResponse("User not found"));
        var role = (await _unitOfWork.Roles.FindAsync(r => r.Name == roleName)).FirstOrDefault();
        if (role == null) return NotFound(ApiResponse<object>.ErrorResponse("Role not found"));
        var link = (await _unitOfWork.UserRoles.FindAsync(ur => ur.UserId == id && ur.RoleId == role.Id)).FirstOrDefault();
        if (link == null) return NotFound(ApiResponse<object>.ErrorResponse("User doesn't have this role"));
        await _unitOfWork.UserRoles.DeleteAsync(link);
        return Ok(ApiResponse<object>.SuccessResponse(null, "Role removed"));
    }
}
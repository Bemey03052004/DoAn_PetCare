using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using PetCare.DTOs;
using PetCare.Entities;
using PetCare.Repositories;

namespace PetCare.Controllers;

[ApiController]
[Route("api/admin/roles")] // Changed from "api/roles" to "api/admin/roles" for consistency
[Authorize(Roles = "Admin")]
public class RoleController : ControllerBase
{
    private readonly IUnitOfWork _unitOfWork;

    public RoleController(IUnitOfWork unitOfWork)
    {
        _unitOfWork = unitOfWork;
    }

    [HttpGet]
    public async Task<ActionResult<ApiResponse<IEnumerable<Role>>>> GetAllRoles()
    {
        try
        {
            var roles = await _unitOfWork.Roles.GetAllAsync();
            return Ok(ApiResponse<IEnumerable<Role>>.SuccessResponse(roles, "Roles retrieved successfully"));
        }
        catch (Exception ex)
        {
            return StatusCode(500, ApiResponse<IEnumerable<Role>>.ErrorResponse($"Error retrieving roles: {ex.Message}"));
        }
    }

    [HttpGet("{id:int}")]
    public async Task<ActionResult<ApiResponse<Role>>> GetRoleById(int id)
    {
        try
        {
            var role = await _unitOfWork.Roles.GetByIdAsync(id);
            
            if (role == null)
            {
                return NotFound(ApiResponse<Role>.ErrorResponse($"Role with ID {id} not found"));
            }
            
            return Ok(ApiResponse<Role>.SuccessResponse(role, "Role retrieved successfully"));
        }
        catch (Exception ex)
        {
            return StatusCode(500, ApiResponse<Role>.ErrorResponse($"Error retrieving role: {ex.Message}"));
        }
    }

    [HttpPost]
    public async Task<ActionResult<ApiResponse<Role>>> CreateRole([FromBody] RoleDto roleDto)
    {
        try
        {
            // Check if role with the same name already exists
            var existingRole = await _unitOfWork.Roles.FindAsync(r => r.Name == roleDto.Name);
            if (existingRole.Any())
            {
                return Conflict(ApiResponse<Role>.ErrorResponse($"Role with name '{roleDto.Name}' already exists"));
            }

            var role = new Role
            {
                Name = roleDto.Name,
                Description = roleDto.Description
            };

            var createdRole = await _unitOfWork.Roles.AddAsync(role);
            return CreatedAtAction(nameof(GetRoleById), new { id = createdRole.Id }, 
                ApiResponse<Role>.SuccessResponse(createdRole, "Role created successfully"));
        }
        catch (Exception ex)
        {
            return StatusCode(500, ApiResponse<Role>.ErrorResponse($"Error creating role: {ex.Message}"));
        }
    }

    [HttpPut("{id:int}")]
    public async Task<ActionResult<ApiResponse<Role>>> UpdateRole(int id, [FromBody] RoleDto roleDto)
    {
        try
        {
            var role = await _unitOfWork.Roles.GetByIdAsync(id);
            if (role == null)
            {
                return NotFound(ApiResponse<Role>.ErrorResponse($"Role with ID {id} not found"));
            }

            // Check if role name is changing and if it's already in use
            if (role.Name != roleDto.Name)
            {
                var existingRole = await _unitOfWork.Roles.FindAsync(r => r.Name == roleDto.Name);
                if (existingRole.Any())
                {
                    return Conflict(ApiResponse<Role>.ErrorResponse($"Role with name '{roleDto.Name}' already exists"));
                }
            }

            role.Name = roleDto.Name;
            role.Description = roleDto.Description;

            await _unitOfWork.Roles.UpdateAsync(role);
            return Ok(ApiResponse<Role>.SuccessResponse(role, "Role updated successfully"));
        }
        catch (Exception ex)
        {
            return StatusCode(500, ApiResponse<Role>.ErrorResponse($"Error updating role: {ex.Message}"));
        }
    }

    [HttpDelete("{id:int}")]
    public async Task<ActionResult<ApiResponse<object>>> DeleteRole(int id)
    {
        try
        {
            var role = await _unitOfWork.Roles.GetByIdAsync(id);
            if (role == null)
            {
                return NotFound(ApiResponse<object>.ErrorResponse($"Role with ID {id} not found"));
            }

            // Don't allow deletion of built-in roles
            if (role.Name == "User" || role.Name == "Admin")
            {
                return BadRequest(ApiResponse<object>.ErrorResponse("Cannot delete built-in roles"));
            }

            await _unitOfWork.BeginTransactionAsync();
            
            try
            {
                // Delete all user-role associations for this role
                var userRoles = await _unitOfWork.UserRoles.FindAsync(ur => ur.RoleId == id);
                foreach (var userRole in userRoles)
                {
                    await _unitOfWork.UserRoles.DeleteAsync(userRole);
                }
                
                // Delete the role
                await _unitOfWork.Roles.DeleteAsync(role);
                
                await _unitOfWork.CommitAsync();
                return Ok(ApiResponse<object>.SuccessResponse(null, "Role deleted successfully"));
            }
            catch
            {
                await _unitOfWork.RollbackAsync();
                throw;
            }
        }
        catch (Exception ex)
        {
            return StatusCode(500, ApiResponse<object>.ErrorResponse($"Error deleting role: {ex.Message}"));
        }
    }

    [HttpGet("{id:int}/users")]
    public async Task<ActionResult<ApiResponse<IEnumerable<UserResponseDto>>>> GetUsersInRole(int id)
    {
        try
        {
            var role = await _unitOfWork.Roles.GetByIdAsync(id);
            if (role == null)
            {
                return NotFound(ApiResponse<IEnumerable<UserResponseDto>>.ErrorResponse($"Role with ID {id} not found"));
            }

            // Get all user-role associations for this role
            var userRoles = await _unitOfWork.UserRoles.FindAsync(ur => ur.RoleId == id);
            var userIds = userRoles.Select(ur => ur.UserId).ToList();
            
            var users = new List<UserResponseDto>();
            
            // Get user details for each user ID
            foreach (var userId in userIds)
            {
                var user = await _unitOfWork.Users.GetByIdAsync(userId);
                if (user != null)
                {
                    var roles = await _unitOfWork.Users.GetUserRolesAsync(userId);
                    users.Add(new UserResponseDto
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
                    });
                }
            }
            
            return Ok(ApiResponse<IEnumerable<UserResponseDto>>.SuccessResponse(users, $"Users with role '{role.Name}' retrieved successfully"));
        }
        catch (Exception ex)
        {
            return StatusCode(500, ApiResponse<IEnumerable<UserResponseDto>>.ErrorResponse($"Error retrieving users for role: {ex.Message}"));
        }
    }
}
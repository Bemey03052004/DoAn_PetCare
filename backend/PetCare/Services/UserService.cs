using PetCare.DTOs;
using PetCare.Entities;
using PetCare.Repositories;

namespace PetCare.Services;

public interface IUserService
{
    Task<UserResponseDto> GetUserByIdAsync(int id);
    Task<IEnumerable<UserResponseDto>> GetAllUsersAsync();
    Task<UserResponseDto> UpdateUserAsync(int id, UserUpdateDto updateDto);
    Task<bool> DeleteUserAsync(int id);
    Task<bool> AddRoleToUserAsync(int userId, string roleName);
    Task<bool> RemoveRoleFromUserAsync(int userId, string roleName);
    Task<IEnumerable<string>> GetUserRolesAsync(int userId);
}

public class UserService : IUserService
{
    private readonly IUnitOfWork _unitOfWork;

    public UserService(IUnitOfWork unitOfWork)
    {
        _unitOfWork = unitOfWork;
    }

    public async Task<UserResponseDto> GetUserByIdAsync(int id)
    {
        var user = await _unitOfWork.Users.GetByIdWithRolesAsync(id);
        if (user == null)
        {
            throw new KeyNotFoundException($"User with ID {id} not found");
        }

        // Get user roles
        var roles = await _unitOfWork.Users.GetUserRolesAsync(id);

        return MapUserToDto(user, roles);
    }

    public async Task<IEnumerable<UserResponseDto>> GetAllUsersAsync()
    {
        var users = await _unitOfWork.Users.GetAllWithRolesAsync();
        var userDtos = new List<UserResponseDto>();

        foreach (var user in users)
        {
            var roles = await _unitOfWork.Users.GetUserRolesAsync(user.Id);
            userDtos.Add(MapUserToDto(user, roles));
        }

        return userDtos;
    }

    public async Task<UserResponseDto> UpdateUserAsync(int id, UserUpdateDto updateDto)
    {
        var user = await _unitOfWork.Users.GetByIdAsync(id);
        if (user == null)
        {
            throw new KeyNotFoundException($"User with ID {id} not found");
        }

        // Check if email is changing and if it's already in use
        if (updateDto.Email != null && user.Email != updateDto.Email)
        {
            if (!await _unitOfWork.Users.IsEmailUniqueAsync(updateDto.Email))
            {
                throw new InvalidOperationException("Email is already in use");
            }
            user.Email = updateDto.Email;
        }

        // Update user properties if provided
        if (updateDto.FullName != null) user.FullName = updateDto.FullName;
        if (updateDto.Phone != null) user.Phone = updateDto.Phone;
        if (updateDto.Address != null) user.Address = updateDto.Address;
        if (updateDto.Latitude.HasValue) user.Latitude = updateDto.Latitude;
        if (updateDto.Longitude.HasValue) user.Longitude = updateDto.Longitude;

        // Update password if provided
        if (!string.IsNullOrEmpty(updateDto.Password))
        {
            user.PasswordHash = BCrypt.Net.BCrypt.HashPassword(updateDto.Password);
        }

        await _unitOfWork.Users.UpdateAsync(user);
        var roles = await _unitOfWork.Users.GetUserRolesAsync(id);

        return MapUserToDto(user, roles);
    }

    public async Task<bool> DeleteUserAsync(int id)
    {
        var user = await _unitOfWork.Users.GetByIdAsync(id);
        if (user == null)
        {
            return false;
        }

        await _unitOfWork.BeginTransactionAsync();
        
        try
        {
            // Delete all user roles
            var userRoles = await _unitOfWork.UserRoles.FindAsync(ur => ur.UserId == id);
            foreach (var userRole in userRoles)
            {
                await _unitOfWork.UserRoles.DeleteAsync(userRole);
            }
            
            // Delete the user
            await _unitOfWork.Users.DeleteAsync(user);
            
            await _unitOfWork.CommitAsync();
            return true;
        }
        catch
        {
            await _unitOfWork.RollbackAsync();
            throw;
        }
    }

    public async Task<bool> AddRoleToUserAsync(int userId, string roleName)
    {
        var user = await _unitOfWork.Users.GetByIdAsync(userId);
        if (user == null)
        {
            return false;
        }

        try
        {
            await _unitOfWork.Users.AddUserToRoleAsync(userId, roleName);
            return true;
        }
        catch
        {
            return false;
        }
    }

    public async Task<bool> RemoveRoleFromUserAsync(int userId, string roleName)
    {
        var user = await _unitOfWork.Users.GetByIdAsync(userId);
        if (user == null)
        {
            return false;
        }

        try
        {
            await _unitOfWork.Users.RemoveUserFromRoleAsync(userId, roleName);
            return true;
        }
        catch
        {
            return false;
        }
    }

    public async Task<IEnumerable<string>> GetUserRolesAsync(int userId)
    {
        var user = await _unitOfWork.Users.GetByIdAsync(userId);
        if (user == null)
        {
            return Enumerable.Empty<string>();
        }

        return await _unitOfWork.Users.GetUserRolesAsync(userId);
    }

    private static UserResponseDto MapUserToDto(User user, IEnumerable<string> roles)
    {
        return new UserResponseDto
        {
            Id = user.Id,
            FullName = user.FullName,
            Email = user.Email,
            Phone = user.Phone,
            Address = user.Address,
            Latitude = user.Latitude,
            Longitude = user.Longitude,
            IsEmailVerified = user.IsEmailVerified,
            Roles = roles.ToList(),
            CreatedAt = user.CreatedAt
        };
    }
}
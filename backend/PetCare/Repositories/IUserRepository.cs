using PetCare.Entities;

namespace PetCare.Repositories;

public interface IUserRepository : IRepository<User>
{
    Task<User?> GetByEmailAsync(string email);
    Task<User?> GetByIdWithPetsAsync(int id);
    Task<User?> GetByIdWithRolesAsync(int id);
    Task<User?> GetByIdWithFullDetailsAsync(int id);
    Task<IEnumerable<User>> GetAllWithPetsAsync();
    Task<IEnumerable<User>> GetAllWithRolesAsync();
    Task<bool> IsEmailUniqueAsync(string email);
    Task<IEnumerable<string>> GetUserRolesAsync(int userId);
    Task AddUserToRoleAsync(int userId, string roleName);
    Task RemoveUserFromRoleAsync(int userId, string roleName);
    Task<bool> IsUserInRoleAsync(int userId, string roleName);
}
using System.Linq.Expressions;

namespace PetCare.Repositories;

/// <summary>
/// Generic repository interface for basic CRUD operations
/// </summary>
/// <typeparam name="T">Entity type</typeparam>
public interface IRepository<T> where T : class
{
    // Get operations
    Task<T?> GetByIdAsync(int id);
    Task<IEnumerable<T>> GetAllAsync();
    Task<IEnumerable<T>> FindAsync(Expression<Func<T, bool>> predicate);
    
    // Add operations
    Task<T> AddAsync(T entity);
    Task AddRangeAsync(IEnumerable<T> entities);
    
    // Update operations
    Task<T> UpdateAsync(T entity);
    
    // Delete operations
    Task DeleteAsync(T entity);
    Task DeleteRangeAsync(IEnumerable<T> entities);
    
    // Count operations
    Task<int> CountAsync();
    Task<int> CountAsync(Expression<Func<T, bool>> predicate);
    
    // Exists operation
    Task<bool> ExistsAsync(Expression<Func<T, bool>> predicate);
    
    // Admin operations
    Task<IEnumerable<T>> GetRecentAsync(int count);
}
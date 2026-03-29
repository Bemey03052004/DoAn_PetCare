using Microsoft.EntityFrameworkCore;
using PetCare.Data;
using PetCare.Entities;

namespace PetCare.Repositories;

public interface ILoginSessionRepository : IRepository<LoginSession>
{
    Task<LoginSession?> GetByRefreshTokenAsync(string refreshToken);
    Task<List<LoginSession>> GetActiveSessionsByUserIdAsync(int userId);
    Task RevokeSessionAsync(int sessionId);
    Task RevokeAllUserSessionsAsync(int userId);
    Task CleanupExpiredSessionsAsync();
}

public class LoginSessionRepository : Repository<LoginSession>, ILoginSessionRepository
{
    public LoginSessionRepository(AppDbContext context) : base(context)
    {
    }

    public async Task<LoginSession?> GetByRefreshTokenAsync(string refreshToken)
    {
        return await _context.LoginSessions
            .Include(ls => ls.User)
            .FirstOrDefaultAsync(ls => ls.RefreshToken == refreshToken && ls.IsActive && !ls.IsRevoked);
    }

    public async Task<List<LoginSession>> GetActiveSessionsByUserIdAsync(int userId)
    {
        return await _context.LoginSessions
            .Where(ls => ls.UserId == userId && ls.IsActive && !ls.IsRevoked && ls.ExpiresAt > DateTime.UtcNow)
            .OrderByDescending(ls => ls.LastUsedAt ?? ls.CreatedAt)
            .ToListAsync();
    }

    public async Task RevokeSessionAsync(int sessionId)
    {
        var session = await GetByIdAsync(sessionId);
        if (session != null)
        {
            session.IsRevoked = true;
            session.IsActive = false;
            session.RevokedAt = DateTime.UtcNow;
            await UpdateAsync(session);
        }
    }

    public async Task RevokeAllUserSessionsAsync(int userId)
    {
        var sessions = await _context.LoginSessions
            .Where(ls => ls.UserId == userId && ls.IsActive && !ls.IsRevoked)
            .ToListAsync();

        foreach (var session in sessions)
        {
            session.IsRevoked = true;
            session.IsActive = false;
            session.RevokedAt = DateTime.UtcNow;
        }

        await _context.SaveChangesAsync();
    }

    public async Task CleanupExpiredSessionsAsync()
    {
        var expiredSessions = await _context.LoginSessions
            .Where(ls => ls.ExpiresAt < DateTime.UtcNow || ls.IsRevoked)
            .ToListAsync();

        _context.LoginSessions.RemoveRange(expiredSessions);
        await _context.SaveChangesAsync();
    }
}

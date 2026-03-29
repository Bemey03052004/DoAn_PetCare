using Microsoft.EntityFrameworkCore;
using PetCare.Data;
using PetCare.Entities;

namespace PetCare.Repositories;

public class BoardingRequestRepository : Repository<BoardingRequest>, IBoardingRequestRepository
{
    public BoardingRequestRepository(AppDbContext context) : base(context)
    {
    }

    public async Task<IEnumerable<BoardingRequest>> GetByCustomerIdAsync(int customerId)
    {
        return await _context.BoardingRequests
            .Include(br => br.Pet)
            .Include(br => br.Owner)
            .Include(br => br.Customer)
            .Where(br => br.CustomerId == customerId)
            .OrderByDescending(br => br.CreatedAt)
            .ToListAsync();
    }

    public async Task<IEnumerable<BoardingRequest>> GetByOwnerIdAsync(int ownerId)
    {
        return await _context.BoardingRequests
            .Include(br => br.Pet)
            .Include(br => br.Owner)
            .Include(br => br.Customer)
            .Where(br => br.OwnerId == ownerId)
            .OrderByDescending(br => br.CreatedAt)
            .ToListAsync();
    }

    public async Task<IEnumerable<BoardingRequest>> GetByPetIdAsync(int petId)
    {
        return await _context.BoardingRequests
            .Include(br => br.Pet)
            .Include(br => br.Owner)
            .Include(br => br.Customer)
            .Where(br => br.PetId == petId)
            .OrderByDescending(br => br.CreatedAt)
            .ToListAsync();
    }

    public async Task<BoardingRequest?> GetWithDetailsAsync(int id)
    {
        return await _context.BoardingRequests
            .Include(br => br.Pet)
            .Include(br => br.Owner)
            .Include(br => br.Customer)
            .Include(br => br.Payments)
            .FirstOrDefaultAsync(br => br.Id == id);
    }

    public async Task<IEnumerable<BoardingRequest>> GetOverlappingRequestsAsync(int petId, DateTime startDate, DateTime endDate)
    {
        return await _context.BoardingRequests
            .Where(br => br.PetId == petId && br.Status == "Confirmed" &&
                       ((startDate >= br.StartDate && startDate < br.EndDate) ||
                        (endDate > br.StartDate && endDate <= br.EndDate) ||
                        (startDate <= br.StartDate && endDate >= br.EndDate)))
            .ToListAsync();
    }

    public async Task<IEnumerable<BoardingRequest>> GetRecentAsync(int count)
    {
        return await _context.BoardingRequests
            .OrderByDescending(br => br.CreatedAt)
            .Take(count)
            .ToListAsync();
    }
}

using Microsoft.EntityFrameworkCore;
using PetCare.Data;
using PetCare.Entities;

namespace PetCare.Repositories;

public class SaleRequestRepository : Repository<SaleRequest>, ISaleRequestRepository
{
    public SaleRequestRepository(AppDbContext context) : base(context)
    {
    }

    public async Task<IEnumerable<SaleRequest>> GetByBuyerIdAsync(int buyerId)
    {
        return await _context.SaleRequests
            .Include(sr => sr.Pet)
            .Include(sr => sr.Seller)
            .Include(sr => sr.Buyer)
            .Where(sr => sr.BuyerId == buyerId)
            .OrderByDescending(sr => sr.CreatedAt)
            .ToListAsync();
    }

    public async Task<IEnumerable<SaleRequest>> GetBySellerIdAsync(int sellerId)
    {
        return await _context.SaleRequests
            .Include(sr => sr.Pet)
            .Include(sr => sr.Seller)
            .Include(sr => sr.Buyer)
            .Where(sr => sr.SellerId == sellerId)
            .OrderByDescending(sr => sr.CreatedAt)
            .ToListAsync();
    }

    public async Task<IEnumerable<SaleRequest>> GetByPetIdAsync(int petId)
    {
        return await _context.SaleRequests
            .Include(sr => sr.Pet)
            .Include(sr => sr.Seller)
            .Include(sr => sr.Buyer)
            .Where(sr => sr.PetId == petId)
            .OrderByDescending(sr => sr.CreatedAt)
            .ToListAsync();
    }

    public async Task<SaleRequest?> GetWithDetailsAsync(int id)
    {
        return await _context.SaleRequests
            .Include(sr => sr.Pet)
            .Include(sr => sr.Seller)
            .Include(sr => sr.Buyer)
            .Include(sr => sr.Payments)
            .FirstOrDefaultAsync(sr => sr.Id == id);
    }
}

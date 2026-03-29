using Microsoft.EntityFrameworkCore;
using PetCare.Data;
using PetCare.Entities;

namespace PetCare.Repositories;

public interface IPriceOfferRepository : IRepository<PriceOffer>
{
    Task<IEnumerable<PriceOffer>> GetByPetIdAsync(int petId);
    Task<IEnumerable<PriceOffer>> GetByOffererIdAsync(int offererId);
    Task<IEnumerable<PriceOffer>> GetByReceiverIdAsync(int receiverId);
    Task<PriceOffer?> GetWithDetailsAsync(int id);
    Task<IEnumerable<PriceOffer>> GetActiveOffersForPetAsync(int petId);
    Task<bool> HasActiveOfferAsync(int petId, int offererId);
}

public class PriceOfferRepository : Repository<PriceOffer>, IPriceOfferRepository
{
    public PriceOfferRepository(AppDbContext context) : base(context)
    {
    }

    public async Task<IEnumerable<PriceOffer>> GetByPetIdAsync(int petId)
    {
        return await _context.PriceOffers
            .Include(po => po.Pet)
            .Include(po => po.Offerer)
            .Include(po => po.Receiver)
            .Include(po => po.History)
                .ThenInclude(h => h.User)
            .Where(po => po.PetId == petId)
            .OrderByDescending(po => po.CreatedAt)
            .ToListAsync();
    }

    public async Task<IEnumerable<PriceOffer>> GetByOffererIdAsync(int offererId)
    {
        return await _context.PriceOffers
            .Include(po => po.Pet)
            .Include(po => po.Offerer)
            .Include(po => po.Receiver)
            .Include(po => po.History)
                .ThenInclude(h => h.User)
            .Where(po => po.OffererId == offererId)
            .OrderByDescending(po => po.CreatedAt)
            .ToListAsync();
    }

    public async Task<IEnumerable<PriceOffer>> GetByReceiverIdAsync(int receiverId)
    {
        return await _context.PriceOffers
            .Include(po => po.Pet)
            .Include(po => po.Offerer)
            .Include(po => po.Receiver)
            .Include(po => po.History)
                .ThenInclude(h => h.User)
            .Where(po => po.ReceiverId == receiverId)
            .OrderByDescending(po => po.CreatedAt)
            .ToListAsync();
    }

    public async Task<PriceOffer?> GetWithDetailsAsync(int id)
    {
        return await _context.PriceOffers
            .Include(po => po.Pet)
            .Include(po => po.Offerer)
            .Include(po => po.Receiver)
            .Include(po => po.History)
                .ThenInclude(h => h.User)
            .FirstOrDefaultAsync(po => po.Id == id);
    }

    public async Task<IEnumerable<PriceOffer>> GetActiveOffersForPetAsync(int petId)
    {
        return await _context.PriceOffers
            .Include(po => po.Pet)
            .Include(po => po.Offerer)
            .Include(po => po.Receiver)
            .Include(po => po.History)
                .ThenInclude(h => h.User)
            .Where(po => po.PetId == petId && 
                        (po.Status == "Pending" || po.Status == "CounterOffered"))
            .OrderByDescending(po => po.CreatedAt)
            .ToListAsync();
    }

    public async Task<bool> HasActiveOfferAsync(int petId, int offererId)
    {
        return await _context.PriceOffers
            .AnyAsync(po => po.PetId == petId && 
                           po.OffererId == offererId && 
                           (po.Status == "Pending" || po.Status == "CounterOffered"));
    }
}

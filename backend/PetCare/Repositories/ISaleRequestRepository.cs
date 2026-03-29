using PetCare.Entities;

namespace PetCare.Repositories;

public interface ISaleRequestRepository : IRepository<SaleRequest>
{
    Task<IEnumerable<SaleRequest>> GetByBuyerIdAsync(int buyerId);
    Task<IEnumerable<SaleRequest>> GetBySellerIdAsync(int sellerId);
    Task<IEnumerable<SaleRequest>> GetByPetIdAsync(int petId);
    Task<SaleRequest?> GetWithDetailsAsync(int id);
}

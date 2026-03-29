using PetCare.Entities;

namespace PetCare.Repositories;

public interface IBoardingRequestRepository : IRepository<BoardingRequest>
{
    Task<IEnumerable<BoardingRequest>> GetByCustomerIdAsync(int customerId);
    Task<IEnumerable<BoardingRequest>> GetByOwnerIdAsync(int ownerId);
    Task<IEnumerable<BoardingRequest>> GetByPetIdAsync(int petId);
    Task<BoardingRequest?> GetWithDetailsAsync(int id);
    Task<IEnumerable<BoardingRequest>> GetOverlappingRequestsAsync(int petId, DateTime startDate, DateTime endDate);
    Task<IEnumerable<BoardingRequest>> GetRecentAsync(int count);
}

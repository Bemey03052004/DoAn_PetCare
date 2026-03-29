using PetCare.Entities;

namespace PetCare.Repositories;

public interface IPetRepository : IRepository<Pet>
{
    Task<Pet?> GetByIdWithProfileAsync(int id);
    Task<Pet?> GetByIdWithOwnerAsync(int id);
    Task<Pet?> GetByIdWithFullDetailsAsync(int id);
    Task<IEnumerable<Pet>> GetByOwnerIdAsync(int ownerId);
    Task<IEnumerable<Pet>> GetAvailableForAdoptionAsync();
    Task<IEnumerable<Pet>> GetPetsByPreferenceAsync(Preference preference, double? maxDistance = null);
    Task<IEnumerable<Pet>> GetPublicPetsAsync(string? species = null, int? minAgeMonths = null, int? maxAgeMonths = null, string? keyword = null, double? lat = null, double? lng = null, double? maxDistanceKm = null);
}
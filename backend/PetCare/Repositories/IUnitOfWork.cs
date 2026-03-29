using PetCare.Entities;

namespace PetCare.Repositories;

/// <summary>
/// Interface for the Unit of Work pattern to coordinate multiple repository operations within a single transaction
/// </summary>
public interface IUnitOfWork : IDisposable
{
    // Individual repositories
    IUserRepository Users { get; }
    IRepository<Role> Roles { get; }
    IRepository<UserRole> UserRoles { get; }
    IPetRepository Pets { get; }
    IRepository<PetProfile> PetProfiles { get; }
    IRepository<VaccinationSchedule> VaccinationSchedules { get; }
    IRepository<AdoptionRequest> AdoptionRequests { get; }
    ISaleRequestRepository SaleRequests { get; }
    IBoardingRequestRepository BoardingRequests { get; }
    IRepository<PetBoardingRequest> PetBoardingRequests { get; }
    IRepository<PaymentTransaction> PaymentTransactions { get; }
    IRepository<ContentModeration> ContentModerations { get; }
    IRepository<ContentReport> ContentReports { get; }
    IRepository<SystemConfiguration> SystemConfigurations { get; }
    IRepository<ServiceFee> ServiceFees { get; }
    IRepository<UserComplaint> UserComplaints { get; }
    IRepository<ChatRoom> ChatRooms { get; }
    IRepository<Message> Messages { get; }
    IRepository<Notification> Notifications { get; }
    IRepository<Preference> Preferences { get; }
    IRepository<PasswordResetToken> PasswordResetTokens { get; }
    IRepository<EmailVerificationCode> EmailVerificationCodes { get; }
    IRepository<Transaction> Transactions { get; }
    IPriceOfferRepository PriceOffers { get; }
    ILoginSessionRepository LoginSessions { get; }
    IRepository<Species> Species { get; }
    
    // Transaction management
    Task BeginTransactionAsync();
    Task CommitAsync();
    Task RollbackAsync();
    
    // Save changes
    Task<int> SaveChangesAsync();
    Task SaveAsync();
}
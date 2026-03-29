using Microsoft.EntityFrameworkCore.Storage;
using PetCare.Data;
using PetCare.Entities;

namespace PetCare.Repositories;

public class UnitOfWork : IUnitOfWork
{
    private readonly AppDbContext _context;
    private IDbContextTransaction? _transaction;
    
    private IUserRepository? _userRepository;
    private IRepository<Role>? _roleRepository;
    private IRepository<UserRole>? _userRoleRepository;
    private IPetRepository? _petRepository;
    private IRepository<PetProfile>? _petProfileRepository;
    private IRepository<VaccinationSchedule>? _vaccinationScheduleRepository;
    private IRepository<AdoptionRequest>? _adoptionRequestRepository;
    private ISaleRequestRepository? _saleRequestRepository;
    private IBoardingRequestRepository? _boardingRequestRepository;
    private IRepository<PetBoardingRequest>? _petBoardingRequestRepository;
    private IRepository<PaymentTransaction>? _paymentTransactionRepository;
    private IRepository<ContentModeration>? _contentModerationRepository;
    private IRepository<ContentReport>? _contentReportRepository;
    private IRepository<SystemConfiguration>? _systemConfigurationRepository;
    private IRepository<ServiceFee>? _serviceFeeRepository;
    private IRepository<UserComplaint>? _userComplaintRepository;
    private IRepository<ChatRoom>? _chatRoomRepository;
    private IRepository<Message>? _messageRepository;
    private IRepository<Notification>? _notificationRepository;
    private IRepository<Preference>? _preferenceRepository;
    private IRepository<PasswordResetToken>? _passwordResetTokenRepository;
    private IRepository<EmailVerificationCode>? _emailVerificationCodeRepository;
    private IRepository<Transaction>? _transactionRepository;
    private IPriceOfferRepository? _priceOfferRepository;
    private ILoginSessionRepository? _loginSessionRepository;
    private IRepository<Species>? _speciesRepository;

    public UnitOfWork(AppDbContext context)
    {
        _context = context;
    }

    public IUserRepository Users => _userRepository ??= new UserRepository(_context);

    public IRepository<Role> Roles => _roleRepository ??= new Repository<Role>(_context);

    public IRepository<UserRole> UserRoles => _userRoleRepository ??= new Repository<UserRole>(_context);

    public IPetRepository Pets => _petRepository ??= new PetRepository(_context);

    public IRepository<PetProfile> PetProfiles => 
        _petProfileRepository ??= new Repository<PetProfile>(_context);

    public IRepository<VaccinationSchedule> VaccinationSchedules => 
        _vaccinationScheduleRepository ??= new Repository<VaccinationSchedule>(_context);

    public IRepository<AdoptionRequest> AdoptionRequests => 
        _adoptionRequestRepository ??= new Repository<AdoptionRequest>(_context);

    public ISaleRequestRepository SaleRequests => 
        _saleRequestRepository ??= new SaleRequestRepository(_context);

    public IBoardingRequestRepository BoardingRequests => 
        _boardingRequestRepository ??= new BoardingRequestRepository(_context);

    public IRepository<PetBoardingRequest> PetBoardingRequests => 
        _petBoardingRequestRepository ??= new Repository<PetBoardingRequest>(_context);

    public IRepository<PaymentTransaction> PaymentTransactions => 
        _paymentTransactionRepository ??= new Repository<PaymentTransaction>(_context);

    public IRepository<ContentModeration> ContentModerations => 
        _contentModerationRepository ??= new Repository<ContentModeration>(_context);

    public IRepository<ContentReport> ContentReports => 
        _contentReportRepository ??= new Repository<ContentReport>(_context);

    public IRepository<SystemConfiguration> SystemConfigurations => 
        _systemConfigurationRepository ??= new Repository<SystemConfiguration>(_context);

    public IRepository<ServiceFee> ServiceFees => 
        _serviceFeeRepository ??= new Repository<ServiceFee>(_context);

    public IRepository<UserComplaint> UserComplaints => 
        _userComplaintRepository ??= new Repository<UserComplaint>(_context);

    public IRepository<ChatRoom> ChatRooms => 
        _chatRoomRepository ??= new Repository<ChatRoom>(_context);

    public IRepository<Message> Messages => 
        _messageRepository ??= new Repository<Message>(_context);

    public IRepository<Notification> Notifications => 
        _notificationRepository ??= new Repository<Notification>(_context);

    public IRepository<Preference> Preferences => 
        _preferenceRepository ??= new Repository<Preference>(_context);

    public IRepository<PasswordResetToken> PasswordResetTokens => 
        _passwordResetTokenRepository ??= new Repository<PasswordResetToken>(_context);

    public IRepository<EmailVerificationCode> EmailVerificationCodes => 
        _emailVerificationCodeRepository ??= new Repository<EmailVerificationCode>(_context);

    public IRepository<Transaction> Transactions => 
        _transactionRepository ??= new Repository<Transaction>(_context);

    public IPriceOfferRepository PriceOffers => 
        _priceOfferRepository ??= new PriceOfferRepository(_context);

    public ILoginSessionRepository LoginSessions => 
        _loginSessionRepository ??= new LoginSessionRepository(_context);

    public IRepository<Species> Species =>
        _speciesRepository ??= new Repository<Species>(_context);

    public async Task BeginTransactionAsync()
    {
        _transaction = await _context.Database.BeginTransactionAsync();
    }

    public async Task CommitAsync()
    {
        try
        {
            await _context.SaveChangesAsync();
            if (_transaction != null)
            {
                await _transaction.CommitAsync();
            }
        }
        finally
        {
            if (_transaction != null)
            {
                await _transaction.DisposeAsync();
                _transaction = null;
            }
        }
    }

    public async Task RollbackAsync()
    {
        try
        {
            if (_transaction != null)
            {
                await _transaction.RollbackAsync();
            }
        }
        finally
        {
            if (_transaction != null)
            {
                await _transaction.DisposeAsync();
                _transaction = null;
            }
        }
    }

    public async Task<int> SaveChangesAsync()
    {
        return await _context.SaveChangesAsync();
    }

    public async Task SaveAsync()
    {
        await _context.SaveChangesAsync();
    }

    public void Dispose()
    {
        _transaction?.Dispose();
        _context.Dispose();
        GC.SuppressFinalize(this);
    }
}
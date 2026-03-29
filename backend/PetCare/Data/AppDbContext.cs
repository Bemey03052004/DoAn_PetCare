using Microsoft.EntityFrameworkCore;

using PetCare.Entities;

namespace PetCare.Data;

public class AppDbContext(DbContextOptions<AppDbContext> options) : DbContext(options)
{
    // ===== DbSet cho toàn bộ Entity =====
    public DbSet<User> Users => Set<User>();
    public DbSet<Role> Roles => Set<Role>();
    public DbSet<UserRole> UserRoles => Set<UserRole>();
    public DbSet<Pet> Pets => Set<Pet>();
    public DbSet<PetProfile> PetProfiles => Set<PetProfile>();
    public DbSet<VaccinationSchedule> VaccinationSchedules => Set<VaccinationSchedule>();
    public DbSet<AdoptionRequest> AdoptionRequests => Set<AdoptionRequest>();
    public DbSet<SaleRequest> SaleRequests => Set<SaleRequest>();
    public DbSet<BoardingRequest> BoardingRequests => Set<BoardingRequest>();
    public DbSet<PetBoardingRequest> PetBoardingRequests => Set<PetBoardingRequest>();
    public DbSet<PaymentTransaction> PaymentTransactions => Set<PaymentTransaction>();
    public DbSet<ContentModeration> ContentModerations => Set<ContentModeration>();
    public DbSet<ContentReport> ContentReports => Set<ContentReport>();
    public DbSet<SystemConfiguration> SystemConfigurations => Set<SystemConfiguration>();
    public DbSet<ServiceFee> ServiceFees => Set<ServiceFee>();
    public DbSet<UserComplaint> UserComplaints => Set<UserComplaint>();
    public DbSet<ChatRoom> ChatRooms => Set<ChatRoom>();
    public DbSet<Message> Messages => Set<Message>();
    public DbSet<Notification> Notifications => Set<Notification>();
    public DbSet<Preference> Preferences => Set<Preference>();
    public DbSet<PasswordResetToken> PasswordResetTokens => Set<PasswordResetToken>();
    public DbSet<EmailVerificationCode> EmailVerificationCodes => Set<EmailVerificationCode>();
    public DbSet<Transaction> Transactions => Set<Transaction>();
    public DbSet<PriceOffer> PriceOffers => Set<PriceOffer>();
    public DbSet<PriceOfferHistory> PriceOfferHistories => Set<PriceOfferHistory>();
    public DbSet<LoginSession> LoginSessions => Set<LoginSession>();
    public DbSet<Species> Species => Set<Species>();

    // ⚙️ Cấu hình Fluent API
    protected override void OnModelCreating(ModelBuilder b)
    {
        base.OnModelCreating(b);

        // ----- User -----
        b.Entity<User>()
            .HasIndex(u => u.Email)
            .IsUnique();

        b.Entity<User>()
            .HasMany(u => u.Pets)
            .WithOne(p => p.Owner)
            .HasForeignKey(p => p.OwnerId)
            .OnDelete(DeleteBehavior.Cascade);

        // ----- User-Role Many-to-Many Relationship -----
        b.Entity<UserRole>()
            .HasKey(ur => ur.Id);

        b.Entity<UserRole>()
            .HasOne(ur => ur.User)
            .WithMany(u => u.UserRoles)
            .HasForeignKey(ur => ur.UserId)
            .OnDelete(DeleteBehavior.Cascade);

        b.Entity<UserRole>()
            .HasOne(ur => ur.Role)
            .WithMany(r => r.UserRoles)
            .HasForeignKey(ur => ur.RoleId)
            .OnDelete(DeleteBehavior.Cascade);

        // Create a unique constraint on UserId and RoleId to prevent duplicate assignments
        b.Entity<UserRole>()
            .HasIndex(ur => new { ur.UserId, ur.RoleId })
            .IsUnique();

        // ----- Pet -----
        b.Entity<Pet>()
            .HasOne(p => p.Profile)
            .WithOne(pp => pp.Pet)
            .HasForeignKey<PetProfile>(pp => pp.PetId)
            .OnDelete(DeleteBehavior.Cascade);

        b.Entity<Pet>()
            .HasMany(p => p.VaccinationSchedules)
            .WithOne(v => v.Pet)
            .HasForeignKey(v => v.PetId)
            .OnDelete(DeleteBehavior.Cascade);

        b.Entity<Pet>()
            .HasMany(p => p.AdoptionRequests)
            .WithOne(a => a.Pet)
            .HasForeignKey(a => a.PetId)
            .OnDelete(DeleteBehavior.Cascade);

        // ----- SaleRequest -----
        b.Entity<SaleRequest>()
            .HasOne(sr => sr.Pet)
            .WithMany()
            .HasForeignKey(sr => sr.PetId)
            .OnDelete(DeleteBehavior.Cascade);

        b.Entity<SaleRequest>()
            .HasOne(sr => sr.Seller)
            .WithMany()
            .HasForeignKey(sr => sr.SellerId)
            .OnDelete(DeleteBehavior.Restrict);

        b.Entity<SaleRequest>()
            .HasOne(sr => sr.Buyer)
            .WithMany()
            .HasForeignKey(sr => sr.BuyerId)
            .OnDelete(DeleteBehavior.Restrict);

        // ----- BoardingRequest -----
        b.Entity<BoardingRequest>()
            .HasOne(br => br.Pet)
            .WithMany()
            .HasForeignKey(br => br.PetId)
            .OnDelete(DeleteBehavior.Cascade);

        b.Entity<BoardingRequest>()
            .HasOne(br => br.Owner)
            .WithMany()
            .HasForeignKey(br => br.OwnerId)
            .OnDelete(DeleteBehavior.Restrict);

        b.Entity<BoardingRequest>()
            .HasOne(br => br.Customer)
            .WithMany()
            .HasForeignKey(br => br.CustomerId)
            .OnDelete(DeleteBehavior.Restrict);

        // ----- PetProfile -----
        b.Entity<PetProfile>()
            .HasIndex(pp => pp.PetId)
            .IsUnique();

        // ----- VaccinationSchedule -----
        b.Entity<VaccinationSchedule>()
            .HasIndex(v => v.ScheduledDate);

        // ----- AdoptionRequest -----
        b.Entity<AdoptionRequest>()
            .HasOne(a => a.User)
            .WithMany(u => u.AdoptionRequests)
            .HasForeignKey(a => a.UserId)
            .OnDelete(DeleteBehavior.Cascade);

        // ----- ChatRoom -----
        b.Entity<ChatRoom>()
            .HasOne(c => c.User1)
            .WithMany()
            .HasForeignKey(c => c.User1Id)
            .OnDelete(DeleteBehavior.Restrict);

        b.Entity<ChatRoom>()
            .HasOne(c => c.User2)
            .WithMany()
            .HasForeignKey(c => c.User2Id)
            .OnDelete(DeleteBehavior.Restrict);

        // ----- Message -----
        b.Entity<Message>()
            .HasOne(m => m.ChatRoom)
            .WithMany(c => c.Messages)
            .HasForeignKey(m => m.ChatRoomId)
            .OnDelete(DeleteBehavior.Cascade);

        b.Entity<Message>()
            .HasOne(m => m.Sender)
            .WithMany(u => u.Messages)
            .HasForeignKey(m => m.SenderId)
            .OnDelete(DeleteBehavior.Restrict);

        // ----- Notification -----
        b.Entity<Notification>()
            .HasOne(n => n.User)
            .WithMany(u => u.Notifications)
            .HasForeignKey(n => n.UserId)
            .OnDelete(DeleteBehavior.Cascade);

        // ----- Preference -----
        b.Entity<Preference>()
            .HasOne(p => p.User)
            .WithMany()
            .HasForeignKey(p => p.UserId)
            .OnDelete(DeleteBehavior.Cascade);

        // ----- PetBoardingRequest -----
        b.Entity<PetBoardingRequest>()
            .HasOne(br => br.Pet)
            .WithMany()
            .HasForeignKey(br => br.PetId)
            .OnDelete(DeleteBehavior.Cascade);

        b.Entity<PetBoardingRequest>()
            .HasOne(br => br.Requester)
            .WithMany()
            .HasForeignKey(br => br.RequesterId)
            .OnDelete(DeleteBehavior.Restrict);

        b.Entity<PetBoardingRequest>()
            .HasOne(br => br.PetOwner)
            .WithMany()
            .HasForeignKey(br => br.PetOwnerId)
            .OnDelete(DeleteBehavior.Restrict);

        // ----- PaymentTransaction -----
        b.Entity<PaymentTransaction>()
            .HasOne(pt => pt.User)
            .WithMany()
            .HasForeignKey(pt => pt.UserId)
            .OnDelete(DeleteBehavior.Restrict);

        // ----- ContentModeration -----
        b.Entity<ContentModeration>()
            .HasOne(cm => cm.Moderator)
            .WithMany()
            .HasForeignKey(cm => cm.ModeratorId)
            .OnDelete(DeleteBehavior.Restrict);

        // ----- ContentReport -----
        b.Entity<ContentReport>()
            .HasOne(cr => cr.Reporter)
            .WithMany()
            .HasForeignKey(cr => cr.ReporterId)
            .OnDelete(DeleteBehavior.Restrict);

        b.Entity<ContentReport>()
            .HasOne(cr => cr.AssignedModerator)
            .WithMany()
            .HasForeignKey(cr => cr.AssignedModeratorId)
            .OnDelete(DeleteBehavior.Restrict);

        // ----- SystemConfiguration -----
        b.Entity<SystemConfiguration>()
            .HasOne(sc => sc.CreatedBy)
            .WithMany()
            .HasForeignKey(sc => sc.CreatedById)
            .OnDelete(DeleteBehavior.Restrict);

        b.Entity<SystemConfiguration>()
            .HasOne(sc => sc.UpdatedBy)
            .WithMany()
            .HasForeignKey(sc => sc.UpdatedById)
            .OnDelete(DeleteBehavior.Restrict);

        // ----- UserComplaint -----
        b.Entity<UserComplaint>()
            .HasOne(uc => uc.Complainant)
            .WithMany()
            .HasForeignKey(uc => uc.ComplainantId)
            .OnDelete(DeleteBehavior.Restrict);

        b.Entity<UserComplaint>()
            .HasOne(uc => uc.Respondent)
            .WithMany()
            .HasForeignKey(uc => uc.RespondentId)
            .OnDelete(DeleteBehavior.Restrict);

        b.Entity<UserComplaint>()
            .HasOne(uc => uc.AssignedAdmin)
            .WithMany()
            .HasForeignKey(uc => uc.AssignedAdminId)
            .OnDelete(DeleteBehavior.Restrict);

        // ----- PriceOffer -----
        b.Entity<PriceOffer>()
            .HasOne(po => po.Pet)
            .WithMany()
            .HasForeignKey(po => po.PetId)
            .OnDelete(DeleteBehavior.Cascade);

        b.Entity<PriceOffer>()
            .HasOne(po => po.Offerer)
            .WithMany()
            .HasForeignKey(po => po.OffererId)
            .OnDelete(DeleteBehavior.Restrict);

        b.Entity<PriceOffer>()
            .HasOne(po => po.Receiver)
            .WithMany()
            .HasForeignKey(po => po.ReceiverId)
            .OnDelete(DeleteBehavior.Restrict);

        b.Entity<PriceOffer>()
            .HasMany(po => po.History)
            .WithOne(poh => poh.PriceOffer)
            .HasForeignKey(poh => poh.PriceOfferId)
            .OnDelete(DeleteBehavior.Cascade);

        // ----- PriceOfferHistory -----
        b.Entity<PriceOfferHistory>()
            .HasOne(poh => poh.User)
            .WithMany()
            .HasForeignKey(poh => poh.UserId)
            .OnDelete(DeleteBehavior.Restrict);

        // ----- LoginSession Configuration -----
        b.Entity<LoginSession>()
            .HasOne(ls => ls.User)
            .WithMany()
            .HasForeignKey(ls => ls.UserId)
            .OnDelete(DeleteBehavior.Cascade);

        b.Entity<LoginSession>()
            .HasIndex(ls => ls.RefreshToken)
            .IsUnique();

        b.Entity<LoginSession>()
            .HasIndex(ls => new { ls.UserId, ls.IsActive });

        // ----- Default Roles -----
        b.Entity<Role>().HasData(
            new Role { Id = 1, Name = "User", Description = "Standard user with basic access" },
            new Role { Id = 2, Name = "Staff", Description = "Staff member with content moderation access" },
            new Role { Id = 3, Name = "Admin", Description = "Administrator with full access" }
        );
    }
}

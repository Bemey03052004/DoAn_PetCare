namespace PetCare.DTOs;

public class UpdatePetDto
{
    public string? Name { get; set; }
    public string? Species { get; set; }
    public string? Breed { get; set; }
    public int? AgeMonths { get; set; }
    public string? Gender { get; set; }
    public string? Description { get; set; }
    public string? ImageUrl { get; set; }
    public decimal? Price { get; set; }
    public bool? IsPublic { get; set; }
    public bool? IsAdopted { get; set; }
    public bool? IsHidden { get; set; }
}

public class TransactionDto
{
    public int Id { get; set; }
    public int UserId { get; set; }
    public string UserName { get; set; } = "";
    public decimal Amount { get; set; }
    public string Type { get; set; } = "";
    public string Status { get; set; } = "";
    public string Description { get; set; } = "";
    public DateTime CreatedAt { get; set; }
    public DateTime? UpdatedAt { get; set; }
}

public class UpdateTransactionStatusDto
{
    public string Status { get; set; } = "";
}

public class DashboardDto
{
    public int TotalPets { get; set; }
    public int TotalUsers { get; set; }
    public int TotalTransactions { get; set; }
    public int TotalBoardingRequests { get; set; }
    public int TotalAdoptionRequests { get; set; }
    public decimal TotalRevenue { get; set; }
    public double SuccessRate { get; set; }
    public List<PetDto> RecentPets { get; set; } = new();
    public List<TransactionDto> RecentTransactions { get; set; } = new();
}

public class UserDto
{
    public int Id { get; set; }
    public string FullName { get; set; } = "";
    public string Email { get; set; } = "";
    public string PhoneNumber { get; set; } = "";
    public bool IsActive { get; set; }
    public bool IsEmailVerified { get; set; }
    public DateTime CreatedAt { get; set; }
    public DateTime? UpdatedAt { get; set; }
    public List<string> Roles { get; set; } = new();
}

public class UpdateUserStatusDto
{
    public bool IsActive { get; set; }
}

public class AssignRoleDto
{
    public string RoleName { get; set; } = "";
}

public class UpdateBoardingRequestStatusDto
{
    public string Status { get; set; } = "";
}

public class AdoptionRequestDto
{
    public int Id { get; set; }
    public int PetId { get; set; }
    public string PetName { get; set; } = "";
    public string PetImageUrl { get; set; } = "";
    public int UserId { get; set; }
    public string UserName { get; set; } = "";
    public string Message { get; set; } = "";
    public string Status { get; set; } = "";
    public DateTime CreatedAt { get; set; }
    public DateTime? UpdatedAt { get; set; }
}

public class UpdateAdoptionRequestStatusDto
{
    public string Status { get; set; } = "";
}

public class SystemStatsDto
{
    public int TotalUsers { get; set; }
    public int ActiveUsers { get; set; }
    public int TotalPets { get; set; }
    public int PublicPets { get; set; }
    public int AdoptedPets { get; set; }
    public int TotalTransactions { get; set; }
    public int CompletedTransactions { get; set; }
    public decimal TotalRevenue { get; set; }
    public double SuccessRate { get; set; }
}

public class RecentActivitiesDto
{
    public List<PetDto> RecentPets { get; set; } = new();
    public List<TransactionDto> RecentTransactions { get; set; } = new();
    public List<BoardingRequestDto> RecentBoardingRequests { get; set; } = new();
    public List<AdoptionRequestDto> RecentAdoptionRequests { get; set; } = new();
}

public class CreateSampleTransactionDto
{
    public int UserId { get; set; }
    public decimal Amount { get; set; }
    public string Type { get; set; } = "";
    public string Status { get; set; } = "";
    public string Description { get; set; } = "";
}
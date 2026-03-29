using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using System.Text.Json.Serialization;

namespace PetCare.Entities;

public class SystemConfiguration
{
    [Key]
    public int Id { get; set; }

    [Required, MaxLength(100)]
    public string Key { get; set; } = "";

    [MaxLength(1000)]
    public string? Value { get; set; }

    [MaxLength(500)]
    public string? Description { get; set; }

    [MaxLength(50)]
    public string Category { get; set; } = "General"; // General, Pricing, Policy, Feature

    public bool IsActive { get; set; } = true;

    [ForeignKey(nameof(CreatedBy))]
    public int CreatedById { get; set; }

    [JsonIgnore]
    public User CreatedBy { get; set; } = null!;

    [ForeignKey(nameof(UpdatedBy))]
    public int? UpdatedById { get; set; }

    [JsonIgnore]
    public User? UpdatedBy { get; set; }

    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime? UpdatedAt { get; set; }
}

public class ServiceFee
{
    [Key]
    public int Id { get; set; }

    [Required, MaxLength(100)]
    public string ServiceType { get; set; } = ""; // "PetListing", "BoardingService", "AdoptionFee", "TransactionFee"

    [Required]
    public decimal FeeAmount { get; set; }

    [MaxLength(10)]
    public string FeeType { get; set; } = "Fixed"; // Fixed, Percentage

    [MaxLength(500)]
    public string? Description { get; set; }

    public bool IsActive { get; set; } = true;

    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime? UpdatedAt { get; set; }
}

public class UserComplaint
{
    [Key]
    public int Id { get; set; }

    [ForeignKey(nameof(Complainant))]
    public int ComplainantId { get; set; }

    [JsonIgnore]
    public User Complainant { get; set; } = null!;

    [ForeignKey(nameof(Respondent))]
    public int RespondentId { get; set; }

    [JsonIgnore]
    public User Respondent { get; set; } = null!;

    [MaxLength(50)]
    public string ComplaintType { get; set; } = ""; // "Scam", "Inappropriate", "Service", "Payment", "Other"

    [Required, MaxLength(1000)]
    public string Description { get; set; } = "";

    [MaxLength(50)]
    public string Status { get; set; } = "Pending"; // Pending, UnderReview, Resolved, Dismissed

    [ForeignKey(nameof(AssignedAdmin))]
    public int? AssignedAdminId { get; set; }

    [JsonIgnore]
    public User? AssignedAdmin { get; set; }

    [MaxLength(1000)]
    public string? AdminResponse { get; set; }

    [MaxLength(1000)]
    public string? Resolution { get; set; }

    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime? ResolvedAt { get; set; }
}

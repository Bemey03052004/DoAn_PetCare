using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using System.Text.Json.Serialization;

namespace PetCare.Entities;

public class ContentModeration
{
    [Key]
    public int Id { get; set; }

    [MaxLength(50)]
    public string ContentType { get; set; } = ""; // "Pet", "PetBoardingRequest", "AdoptionRequest"

    public int ContentId { get; set; }

    [ForeignKey(nameof(Moderator))]
    public int ModeratorId { get; set; }

    [JsonIgnore]
    public User Moderator { get; set; } = null!;

    [MaxLength(50)]
    public string Status { get; set; } = "Pending"; // Pending, Approved, Rejected, NeedsReview

    [MaxLength(1000)]
    public string? RejectionReason { get; set; }

    [MaxLength(1000)]
    public string? ModeratorNotes { get; set; }

    [MaxLength(1000)]
    public string? InternalNotes { get; set; }

    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime? ReviewedAt { get; set; }
    public DateTime? ExpiresAt { get; set; }

    // Flags for different types of violations
    public bool IsInappropriateContent { get; set; } = false;
    public bool IsSpam { get; set; } = false;
    public bool IsFakeListing { get; set; } = false;
    public bool IsPriceManipulation { get; set; } = false;
    public bool IsIncompleteInformation { get; set; } = false;
    public bool IsViolationOfTerms { get; set; } = false;
}

public class ContentReport
{
    [Key]
    public int Id { get; set; }

    [MaxLength(50)]
    public string ContentType { get; set; } = ""; // "Pet", "PetBoardingRequest", "AdoptionRequest"

    public int ContentId { get; set; }

    [ForeignKey(nameof(Reporter))]
    public int ReporterId { get; set; }

    [JsonIgnore]
    public User Reporter { get; set; } = null!;

    [MaxLength(50)]
    public string ReportType { get; set; } = ""; // "Inappropriate", "Spam", "Fake", "PriceManipulation", "Other"

    [MaxLength(1000)]
    public string Description { get; set; } = "";

    [MaxLength(50)]
    public string Status { get; set; } = "Pending"; // Pending, UnderReview, Resolved, Dismissed

    [ForeignKey(nameof(AssignedModerator))]
    public int? AssignedModeratorId { get; set; }

    [JsonIgnore]
    public User? AssignedModerator { get; set; }

    [MaxLength(1000)]
    public string? ModeratorResponse { get; set; }

    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime? ResolvedAt { get; set; }
}

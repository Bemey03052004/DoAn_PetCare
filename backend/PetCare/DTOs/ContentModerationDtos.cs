using System.ComponentModel.DataAnnotations;

namespace PetCare.DTOs;

public class CreateContentModerationDto
{
    [Required(ErrorMessage = "Content type is required")]
    [MaxLength(50, ErrorMessage = "Content type cannot exceed 50 characters")]
    public string ContentType { get; set; } = "";

    [Required(ErrorMessage = "Content ID is required")]
    public int ContentId { get; set; }

    [MaxLength(50, ErrorMessage = "Status cannot exceed 50 characters")]
    public string Status { get; set; } = "Pending";

    [MaxLength(1000, ErrorMessage = "Rejection reason cannot exceed 1000 characters")]
    public string? RejectionReason { get; set; }

    [MaxLength(1000, ErrorMessage = "Moderator notes cannot exceed 1000 characters")]
    public string? ModeratorNotes { get; set; }

    [MaxLength(1000, ErrorMessage = "Internal notes cannot exceed 1000 characters")]
    public string? InternalNotes { get; set; }

    public bool IsInappropriateContent { get; set; } = false;
    public bool IsSpam { get; set; } = false;
    public bool IsFakeListing { get; set; } = false;
    public bool IsPriceManipulation { get; set; } = false;
    public bool IsIncompleteInformation { get; set; } = false;
    public bool IsViolationOfTerms { get; set; } = false;
}

public class ContentModerationResponseDto
{
    public int Id { get; set; }
    public string ContentType { get; set; } = "";
    public int ContentId { get; set; }
    public int ModeratorId { get; set; }
    public string ModeratorName { get; set; } = "";
    public string Status { get; set; } = "";
    public string? RejectionReason { get; set; }
    public string? ModeratorNotes { get; set; }
    public string? InternalNotes { get; set; }
    public DateTime CreatedAt { get; set; }
    public DateTime? ReviewedAt { get; set; }
    public DateTime? ExpiresAt { get; set; }
    public bool IsInappropriateContent { get; set; }
    public bool IsSpam { get; set; }
    public bool IsFakeListing { get; set; }
    public bool IsPriceManipulation { get; set; }
    public bool IsIncompleteInformation { get; set; }
    public bool IsViolationOfTerms { get; set; }
}

public class CreateContentReportDto
{
    [Required(ErrorMessage = "Content type is required")]
    [MaxLength(50, ErrorMessage = "Content type cannot exceed 50 characters")]
    public string ContentType { get; set; } = "";

    [Required(ErrorMessage = "Content ID is required")]
    public int ContentId { get; set; }

    [Required(ErrorMessage = "Report type is required")]
    [MaxLength(50, ErrorMessage = "Report type cannot exceed 50 characters")]
    public string ReportType { get; set; } = "";

    [Required(ErrorMessage = "Description is required")]
    [MaxLength(1000, ErrorMessage = "Description cannot exceed 1000 characters")]
    public string Description { get; set; } = "";
}

public class ContentReportResponseDto
{
    public int Id { get; set; }
    public string ContentType { get; set; } = "";
    public int ContentId { get; set; }
    public int ReporterId { get; set; }
    public string ReporterName { get; set; } = "";
    public string ReportType { get; set; } = "";
    public string Description { get; set; } = "";
    public string Status { get; set; } = "";
    public int? AssignedModeratorId { get; set; }
    public string? AssignedModeratorName { get; set; }
    public string? ModeratorResponse { get; set; }
    public DateTime CreatedAt { get; set; }
    public DateTime? ResolvedAt { get; set; }
}

public class UpdateContentModerationDto
{
    [MaxLength(50, ErrorMessage = "Status cannot exceed 50 characters")]
    public string? Status { get; set; }

    [MaxLength(1000, ErrorMessage = "Rejection reason cannot exceed 1000 characters")]
    public string? RejectionReason { get; set; }

    [MaxLength(1000, ErrorMessage = "Moderator notes cannot exceed 1000 characters")]
    public string? ModeratorNotes { get; set; }

    [MaxLength(1000, ErrorMessage = "Internal notes cannot exceed 1000 characters")]
    public string? InternalNotes { get; set; }

    public bool? IsInappropriateContent { get; set; }
    public bool? IsSpam { get; set; }
    public bool? IsFakeListing { get; set; }
    public bool? IsPriceManipulation { get; set; }
    public bool? IsIncompleteInformation { get; set; }
    public bool? IsViolationOfTerms { get; set; }
}

public class UpdateContentReportDto
{
    [MaxLength(50, ErrorMessage = "Status cannot exceed 50 characters")]
    public string? Status { get; set; }

    public int? AssignedModeratorId { get; set; }

    [MaxLength(1000, ErrorMessage = "Moderator response cannot exceed 1000 characters")]
    public string? ModeratorResponse { get; set; }
}

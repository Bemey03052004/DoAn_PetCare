using System.ComponentModel.DataAnnotations;

namespace PetCare.DTOs;

public class CreateBoardingRequestDto
{
    [Required]
    public int PetId { get; set; }

    [Required]
    public int CustomerId { get; set; }

    [Required]
    public DateTime StartDate { get; set; }

    [Required]
    public DateTime EndDate { get; set; }

    [Range(0.01, double.MaxValue, ErrorMessage = "Giá phải lớn hơn 0")]
    public decimal? CustomPricePerDay { get; set; }

    public string? SpecialInstructions { get; set; }
    public string? ContactPhone { get; set; }
    public string? ContactAddress { get; set; }
}

public class UpdateBoardingStatusDto
{
    [Required]
    public string Status { get; set; } = "Pending"; // Pending, Confirmed, InProgress, Completed, Cancelled
}

// Used by PetBoardingController for updating status/notes
public class UpdateBoardingRequestDto
{
    // Optional fields; controller checks and applies selectively
    [MaxLength(50)]
    public string? Status { get; set; }

    [MaxLength(500)]
    public string? OwnerNotes { get; set; }

    [MaxLength(500)]
    public string? RequesterNotes { get; set; }
}

public class BoardingRequestDto
{
    public int Id { get; set; }
    public int PetId { get; set; }
    public string PetName { get; set; } = "";
    public string PetImageUrl { get; set; } = "";
    public int OwnerId { get; set; }
    public string OwnerName { get; set; } = "";
    public int CustomerId { get; set; }
    public string CustomerName { get; set; } = "";
    public DateTime StartDate { get; set; }
    public DateTime EndDate { get; set; }
    public decimal PricePerDay { get; set; }
    public decimal TotalAmount { get; set; }
    public string? SpecialInstructions { get; set; }
    public string? ContactPhone { get; set; }
    public string? ContactAddress { get; set; }
    public string Status { get; set; } = "";
    public DateTime CreatedAt { get; set; }
    public DateTime? UpdatedAt { get; set; }
    public int? ChatRoomId { get; set; }
}

public class BoardingPaymentRequestDto
{
    [Required]
    public int BoardingRequestId { get; set; }

    [Required]
    public string PaymentMethod { get; set; } = "Cash";

    public string? TransactionId { get; set; }
    public string? Notes { get; set; }
}

public class BoardingRequestResponseDto
{
    public int Id { get; set; }
    public int PetId { get; set; }
    public string PetName { get; set; } = "";
    public string PetImageUrl { get; set; } = "";
    // Người gửi yêu cầu giữ dùm
    public int RequesterId { get; set; }
    public string RequesterName { get; set; } = "";
    // Chủ sở hữu thú cưng
    public int PetOwnerId { get; set; }
    public string PetOwnerName { get; set; } = "";
    public DateTime StartDate { get; set; }
    public DateTime EndDate { get; set; }
    public decimal TotalPrice { get; set; }
    public string? SpecialInstructions { get; set; }
    public string? ContactPhone { get; set; }
    public string? ContactAddress { get; set; }
    public string Status { get; set; } = "";
    public DateTime CreatedAt { get; set; }
    public DateTime? UpdatedAt { get; set; }
    public string? OwnerNotes { get; set; }
    public string? RequesterNotes { get; set; }
}

public class BoardingPaymentSuccessDto
{
    [Required]
    public int BoardingRequestId { get; set; }
    
    public string? PaymentReference { get; set; }
}

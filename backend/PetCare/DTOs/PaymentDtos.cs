using System.ComponentModel.DataAnnotations;

namespace PetCare.DTOs;

public class CreatePaymentRequestDto
{
    [Required(ErrorMessage = "Transaction type is required")]
    [MaxLength(50, ErrorMessage = "Transaction type cannot exceed 50 characters")]
    public string TransactionType { get; set; } = "";

    [Required(ErrorMessage = "Payment method is required")]
    [MaxLength(50, ErrorMessage = "Payment method cannot exceed 50 characters")]
    public string PaymentMethod { get; set; } = "";

    [Required(ErrorMessage = "Amount is required")]
    [Range(0.01, double.MaxValue, ErrorMessage = "Amount must be greater than 0")]
    public decimal Amount { get; set; }

    [Range(0, double.MaxValue, ErrorMessage = "Deposit amount must be 0 or greater")]
    public decimal? DepositAmount { get; set; }

    [MaxLength(500, ErrorMessage = "Description cannot exceed 500 characters")]
    public string? Description { get; set; }

    public int? PetId { get; set; }
    public int? BoardingRequestId { get; set; }
    public int? AdoptionRequestId { get; set; }

    [MaxLength(500, ErrorMessage = "Notes cannot exceed 500 characters")]
    public string? Notes { get; set; }
}

public class PaymentResponseDto
{
    public int Id { get; set; }
    public int UserId { get; set; }
    public string UserName { get; set; } = "";
    public string TransactionType { get; set; } = "";
    public string PaymentMethod { get; set; } = "";
    public decimal Amount { get; set; }
    public decimal? DepositAmount { get; set; }
    public string Status { get; set; } = "";
    public string? Description { get; set; }
    public string? ReferenceId { get; set; }
    public int? PetId { get; set; }
    public string? PetName { get; set; }
    public int? BoardingRequestId { get; set; }
    public int? AdoptionRequestId { get; set; }
    public string? Notes { get; set; }
    public DateTime CreatedAt { get; set; }
    public DateTime? CompletedAt { get; set; }
    public DateTime? ExpiresAt { get; set; }
}

public class UpdatePaymentStatusDto
{
    [Required(ErrorMessage = "Status is required")]
    [MaxLength(50, ErrorMessage = "Status cannot exceed 50 characters")]
    public string Status { get; set; } = "";

    [MaxLength(100, ErrorMessage = "Reference ID cannot exceed 100 characters")]
    public string? ReferenceId { get; set; }

    [MaxLength(500, ErrorMessage = "Notes cannot exceed 500 characters")]
    public string? Notes { get; set; }
}

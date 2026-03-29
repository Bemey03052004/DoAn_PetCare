using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using System.Text.Json.Serialization;

namespace PetCare.Entities;

public class PaymentTransaction
{
    [Key]
    public int Id { get; set; }

    [ForeignKey(nameof(User))]
    public int UserId { get; set; }

    [JsonIgnore]
    public User User { get; set; } = null!;

    [MaxLength(50)]
    public string TransactionType { get; set; } = ""; // "PetSale", "BoardingDeposit", "BoardingPayment", "Refund"

    [MaxLength(50)]
    public string PaymentMethod { get; set; } = ""; // "Cash", "BankTransfer", "Momo", "ZaloPay", "VNPay"

    public decimal Amount { get; set; }
    public decimal? DepositAmount { get; set; } // For boarding services

    [MaxLength(50)]
    public string Status { get; set; } = "Pending"; // Pending, Completed, Failed, Cancelled, Refunded

    [MaxLength(500)]
    public string? Description { get; set; }

    [MaxLength(100)]
    public string? ReferenceId { get; set; } // External payment reference

    // Related entities
    public int? PetId { get; set; }
    public int? SaleRequestId { get; set; }
    public int? BoardingRequestId { get; set; }
    public int? AdoptionRequestId { get; set; }

    [MaxLength(500)]
    public string? Notes { get; set; }

    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime? CompletedAt { get; set; }
    public DateTime? ExpiresAt { get; set; }
}

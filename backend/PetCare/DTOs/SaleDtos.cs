using System.ComponentModel.DataAnnotations;

namespace PetCare.DTOs;

public class CreateSaleRequestDto
{
    [Required]
    public int PetId { get; set; }
    
    [Required]
    public int BuyerId { get; set; }
    
    [Required]
    [Range(0.01, double.MaxValue, ErrorMessage = "Giá phải lớn hơn 0")]
    public decimal Amount { get; set; }
    
    public string? Message { get; set; }
    
    [Required]
    public string PaymentMethod { get; set; } = "Cash"; // Cash, BankTransfer, EWallet
}

public class UpdateSaleStatusDto
{
    [Required]
    public string Status { get; set; } = "Pending"; // Pending, Confirmed, Completed, Cancelled
}

public class SaleRequestDto
{
    public int Id { get; set; }
    public int PetId { get; set; }
    public string PetName { get; set; } = "";
    public string PetImageUrl { get; set; } = "";
    public int SellerId { get; set; }
    public string SellerName { get; set; } = "";
    public int BuyerId { get; set; }
    public string BuyerName { get; set; } = "";
    public decimal Amount { get; set; }
    public string? Message { get; set; }
    public string PaymentMethod { get; set; } = "";
    public string Status { get; set; } = "";
    public DateTime CreatedAt { get; set; }
    public DateTime? UpdatedAt { get; set; }
}

public class PaymentRequestDto
{
    [Required]
    public int SaleRequestId { get; set; }
    
    [Required]
    public string PaymentMethod { get; set; } = "Cash";
    
    public string? TransactionId { get; set; }
    public string? Notes { get; set; }
}

public class PaymentDto
{
    public int Id { get; set; }
    public int SaleRequestId { get; set; }
    public string PaymentMethod { get; set; } = "";
    public string? TransactionId { get; set; }
    public string Status { get; set; } = "";
    public string? Notes { get; set; }
    public DateTime CreatedAt { get; set; }
    public DateTime? UpdatedAt { get; set; }
}

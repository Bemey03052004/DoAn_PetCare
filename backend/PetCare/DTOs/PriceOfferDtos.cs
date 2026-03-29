using System.ComponentModel.DataAnnotations;

namespace PetCare.DTOs;

public class CreatePriceOfferDto
{
    [Required]
    public int PetId { get; set; }

    [Required]
    [Range(0.01, double.MaxValue, ErrorMessage = "Amount must be greater than 0")]
    public decimal OfferedAmount { get; set; }

    [MaxLength(500)]
    public string? Message { get; set; }
}

public class CounterOfferDto
{
    [Required]
    [Range(0.01, double.MaxValue, ErrorMessage = "Amount must be greater than 0")]
    public decimal CounterOfferAmount { get; set; }

    [MaxLength(500)]
    public string? CounterOfferMessage { get; set; }
}

public class UpdatePriceOfferStatusDto
{
    [Required]
    public string Status { get; set; } = ""; // Accepted, Rejected
}

public class PriceOfferDto
{
    public int Id { get; set; }
    public int PetId { get; set; }
    public string PetName { get; set; } = "";
    public string PetImageUrl { get; set; } = "";
    public int OffererId { get; set; }
    public string OffererName { get; set; } = "";
    public int ReceiverId { get; set; }
    public string ReceiverName { get; set; } = "";
    public decimal OfferedAmount { get; set; }
    public string? Message { get; set; }
    public string Status { get; set; } = "";
    public decimal? CounterOfferAmount { get; set; }
    public string? CounterOfferMessage { get; set; }
    public string? CounterOfferStatus { get; set; }
    public DateTime CreatedAt { get; set; }
    public DateTime? UpdatedAt { get; set; }
    public DateTime? CounterOfferAt { get; set; }
    public List<PriceOfferHistoryDto> History { get; set; } = new();
}

public class PriceOfferHistoryDto
{
    public int Id { get; set; }
    public int UserId { get; set; }
    public string UserName { get; set; } = "";
    public string Action { get; set; } = "";
    public decimal? Amount { get; set; }
    public string? Message { get; set; }
    public DateTime CreatedAt { get; set; }
}

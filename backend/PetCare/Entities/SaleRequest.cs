using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using System.Text.Json.Serialization;

namespace PetCare.Entities;

public class SaleRequest
{
    [Key]
    public int Id { get; set; }

    [ForeignKey(nameof(Pet))]
    public int PetId { get; set; }
    public Pet? Pet { get; set; }

    [ForeignKey(nameof(Seller))]
    public int SellerId { get; set; }
    public User? Seller { get; set; }

    [ForeignKey(nameof(Buyer))]
    public int BuyerId { get; set; }
    public User? Buyer { get; set; }

    [Column(TypeName = "decimal(18,2)")]
    public decimal Amount { get; set; }

    [MaxLength(500)]
    public string? Message { get; set; }

    [MaxLength(50)]
    public string PaymentMethod { get; set; } = "Cash";

    [MaxLength(20)]
    public string Status { get; set; } = "Pending"; // Pending, Confirmed, Completed, Cancelled

    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime? UpdatedAt { get; set; }

    [JsonIgnore]
    public ICollection<PaymentTransaction> Payments { get; set; } = new List<PaymentTransaction>();
}

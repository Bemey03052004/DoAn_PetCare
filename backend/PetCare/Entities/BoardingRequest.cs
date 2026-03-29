using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using System.Text.Json.Serialization;

namespace PetCare.Entities;

public class BoardingRequest
{
    [Key]
    public int Id { get; set; }

    [ForeignKey(nameof(Pet))]
    public int PetId { get; set; }
    public Pet? Pet { get; set; }

    [ForeignKey(nameof(Owner))]
    public int OwnerId { get; set; }
    public User? Owner { get; set; }

    [ForeignKey(nameof(Customer))]
    public int CustomerId { get; set; }
    public User? Customer { get; set; }

    public DateTime StartDate { get; set; }
    public DateTime EndDate { get; set; }

    [Column(TypeName = "decimal(18,2)")]
    public decimal PricePerDay { get; set; }

    [Column(TypeName = "decimal(18,2)")]
    public decimal TotalAmount { get; set; }

    [MaxLength(1000)]
    public string? SpecialInstructions { get; set; }

    [MaxLength(20)]
    public string? ContactPhone { get; set; }

    [MaxLength(255)]
    public string? ContactAddress { get; set; }

    [MaxLength(20)]
    public string Status { get; set; } = "Pending"; // Pending, Confirmed, InProgress, Completed, Cancelled

    public int? ChatRoomId { get; set; }

    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime? UpdatedAt { get; set; }

    [JsonIgnore]
    public ICollection<PaymentTransaction> Payments { get; set; } = new List<PaymentTransaction>();
}

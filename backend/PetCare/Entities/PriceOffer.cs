using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using System.Text.Json.Serialization;

namespace PetCare.Entities;

public class PriceOffer
{
    [Key]
    public int Id { get; set; }

    [ForeignKey(nameof(Pet))]
    public int PetId { get; set; }
    public Pet? Pet { get; set; }

    [ForeignKey(nameof(Offerer))]
    public int OffererId { get; set; }
    public User? Offerer { get; set; }

    [ForeignKey(nameof(Receiver))]
    public int ReceiverId { get; set; }
    public User? Receiver { get; set; }

    [Column(TypeName = "decimal(18,2)")]
    public decimal OfferedAmount { get; set; }

    [MaxLength(500)]
    public string? Message { get; set; }

    [MaxLength(20)]
    public string Status { get; set; } = "Pending"; // Pending, Accepted, Rejected, CounterOffered

    [Column(TypeName = "decimal(18,2)")]
    public decimal? CounterOfferAmount { get; set; }

    [MaxLength(500)]
    public string? CounterOfferMessage { get; set; }

    [MaxLength(20)]
    public string? CounterOfferStatus { get; set; } // Pending, Accepted, Rejected

    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime? UpdatedAt { get; set; }
    public DateTime? CounterOfferAt { get; set; }

    [JsonIgnore]
    public ICollection<PriceOfferHistory> History { get; set; } = new List<PriceOfferHistory>();
}

public class PriceOfferHistory
{
    [Key]
    public int Id { get; set; }

    [ForeignKey(nameof(PriceOffer))]
    public int PriceOfferId { get; set; }
    public PriceOffer? PriceOffer { get; set; }

    [ForeignKey(nameof(User))]
    public int UserId { get; set; }
    public User? User { get; set; }

    [MaxLength(50)]
    public string Action { get; set; } = ""; // Created, CounterOffered, Accepted, Rejected

    [Column(TypeName = "decimal(18,2)")]
    public decimal? Amount { get; set; }

    [MaxLength(500)]
    public string? Message { get; set; }

    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
}

using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using System.Text.Json.Serialization;

namespace PetCare.Entities;

public class PetBoardingRequest
{
    [Key]
    public int Id { get; set; }

    [ForeignKey(nameof(Pet))]
    public int PetId { get; set; }

    [JsonIgnore]
    public Pet Pet { get; set; } = null!;

    [ForeignKey(nameof(Requester))]
    public int RequesterId { get; set; }

    [JsonIgnore]
    public User Requester { get; set; } = null!;

    [ForeignKey(nameof(PetOwner))]
    public int PetOwnerId { get; set; }

    [JsonIgnore]
    public User PetOwner { get; set; } = null!;

    public DateTime StartDate { get; set; }
    public DateTime EndDate { get; set; }
    public decimal TotalPrice { get; set; }
    public string? SpecialInstructions { get; set; }
    public string? ContactPhone { get; set; }
    public string? ContactAddress { get; set; }

    [MaxLength(50)]
    public string Status { get; set; } = "Pending"; // Pending, Accepted, Declined, Completed, Cancelled

    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime? UpdatedAt { get; set; }

    [MaxLength(500)]
    public string? OwnerNotes { get; set; }

    [MaxLength(500)]
    public string? RequesterNotes { get; set; }
}

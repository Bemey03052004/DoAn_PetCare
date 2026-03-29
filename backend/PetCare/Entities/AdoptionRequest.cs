using PetCare.Entities;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using System.Text.Json.Serialization;

namespace PetCare.Entities;

public class AdoptionRequest
{
    [Key]
    public int Id { get; set; }

    [ForeignKey(nameof(Pet))]
    public int PetId { get; set; }

    [JsonIgnore]
    public Pet Pet { get; set; } = null!;

    [ForeignKey(nameof(User))]
    public int UserId { get; set; }

    [JsonIgnore]
    public User User { get; set; } = null!;

    [MaxLength(50)]
    public string Status { get; set; } = "Pending";

    [MaxLength(255)]
    public string? Message { get; set; }

    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime? UpdatedAt { get; set; }
}

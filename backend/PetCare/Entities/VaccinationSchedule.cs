using PetCare.Entities;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using System.Text.Json.Serialization;

namespace PetCare.Entities;

public class VaccinationSchedule
{
    [Key]
    public int Id { get; set; }

    [ForeignKey(nameof(Pet))]
    public int PetId { get; set; }

    [JsonIgnore]
    public Pet Pet { get; set; } = null!;

    [MaxLength(100)]
    public string VaccineName { get; set; } = "";

    public DateTime ScheduledDate { get; set; }
    public bool IsCompleted { get; set; } = false;

    public DateTime? CompletedAt { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
}

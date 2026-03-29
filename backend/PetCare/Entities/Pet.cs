using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using System.Text.Json.Serialization;

namespace PetCare.Entities;

public class Pet
{
    [Key]
    public int Id { get; set; }

    [Required, MaxLength(100)]
    public string Name { get; set; } = "";

    [MaxLength(50)]
    public string Species { get; set; } = "Dog";

    [MaxLength(50)]
    public string? Breed { get; set; }

    [MaxLength(10)]
    public string? Gender { get; set; }

    public int AgeMonths { get; set; }
    
    // Age in years for display
    public int Age => AgeMonths / 12;

    [MaxLength(255)]
    public string? ImageUrl { get; set; }

    [MaxLength(255)]
    public string? Description { get; set; }

    public bool IsAdopted { get; set; } = false;

    // Public listing flag: when true and not adopted, pet appears in public discovery
    public bool IsPublic { get; set; } = false;

    // Pet is temporarily hidden when boarding request is pending
    public bool IsHidden { get; set; } = false;

    // Pet selling fields
    public bool IsForSale { get; set; } = false;
    public decimal? Price { get; set; }
    public string? SaleDescription { get; set; }

    // Pet boarding fields
    public bool IsForBoarding { get; set; } = false;
    public decimal? BoardingPricePerDay { get; set; }
    public DateTime? BoardingStartDate { get; set; }
    public DateTime? BoardingEndDate { get; set; }
    public string? BoardingDescription { get; set; }

    [ForeignKey(nameof(Owner))]
    public int OwnerId { get; set; }

    public User? Owner { get; set; }

    // 🔥 Chặn vòng lặp (Pet → Owner → Pets → Pet …)
    [JsonIgnore]
    public PetProfile? Profile { get; set; }

    [JsonIgnore]
    public ICollection<VaccinationSchedule> VaccinationSchedules { get; set; } = new List<VaccinationSchedule>();

    [JsonIgnore]
    public ICollection<AdoptionRequest> AdoptionRequests { get; set; } = new List<AdoptionRequest>();

    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime? UpdatedAt { get; set; }
}

using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using System.Text.Json.Serialization;

namespace PetCare.Entities
{
    public class Preference
    {
        [Key]
        public int Id { get; set; }

        [ForeignKey(nameof(User))]
        public int UserId { get; set; }

        [JsonIgnore]
        public User User { get; set; } = null!;

        [MaxLength(50)]
        public string PreferredSpecies { get; set; } = "Dog";

        [MaxLength(50)]
        public string? PreferredGender { get; set; }

        public int? MinAgeMonths { get; set; }
        public int? MaxAgeMonths { get; set; }

        public double? MaxDistanceKm { get; set; }

        public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;
    }
}

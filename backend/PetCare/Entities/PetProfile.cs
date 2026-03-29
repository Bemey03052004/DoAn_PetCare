using PetCare.Entities;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using System.Text.Json.Serialization;

namespace PetCare.Entities;

public class PetProfile
{
    [Key]
    public int Id { get; set; }

    [ForeignKey(nameof(Pet))]
    public int PetId { get; set; }

    [JsonIgnore] // 🔥 để tránh vòng lặp ngược lại
    public Pet Pet { get; set; } = null!;

    [MaxLength(255)]
    public string? Personality { get; set; }

    [MaxLength(255)]
    public string? FavoriteFood { get; set; }

    [MaxLength(255)]
    public string? Hobbies { get; set; }

    [MaxLength(255)]
    public string? Story { get; set; }

    [MaxLength(255)]
    public string? SocialImage { get; set; }
}

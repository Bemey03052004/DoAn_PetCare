using System.ComponentModel.DataAnnotations;
using System.Text.Json.Serialization;

namespace PetCare.Entities;

public class Role
{
    [Key]
    public int Id { get; set; }

    [Required, MaxLength(50)]
    public string Name { get; set; } = "";

    [MaxLength(255)]
    public string? Description { get; set; }

    // Many-to-many relationship with users
    [JsonIgnore]
    public ICollection<UserRole> UserRoles { get; set; } = new List<UserRole>();
}
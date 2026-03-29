using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace PetCare.Entities;

public class UserRole
{
    [Key]
    public int Id { get; set; }

    // User foreign key
    [ForeignKey(nameof(User))]
    public int UserId { get; set; }
    public User User { get; set; } = null!;

    // Role foreign key
    [ForeignKey(nameof(Role))]
    public int RoleId { get; set; }
    public Role Role { get; set; } = null!;

    // Additional properties, if needed
    public DateTime AssignedAt { get; set; } = DateTime.UtcNow;
}
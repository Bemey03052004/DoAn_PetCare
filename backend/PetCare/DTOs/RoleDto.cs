using System.ComponentModel.DataAnnotations;

namespace PetCare.DTOs;

public class RoleDto
{
    [Required]
    [StringLength(50)]
    public string Name { get; set; } = "";
    
    [StringLength(255)]
    public string? Description { get; set; }
}
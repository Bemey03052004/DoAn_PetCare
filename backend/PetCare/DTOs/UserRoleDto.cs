using System.ComponentModel.DataAnnotations;

namespace PetCare.DTOs;

public class UserRoleDto
{
    [Required]
    public string RoleName { get; set; } = "";
}
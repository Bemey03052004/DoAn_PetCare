using System.ComponentModel.DataAnnotations;

namespace PetCare.DTOs;

public class UserRegistrationDto
{
    [Required]
    [StringLength(100)]
    public string FullName { get; set; } = "";

    [Required]
    [EmailAddress]
    [StringLength(100)]
    public string Email { get; set; } = "";

    [Required]
    [StringLength(100, MinimumLength = 6)]
    public string Password { get; set; } = "";

    [Required]
    [Compare("Password")]
    public string ConfirmPassword { get; set; } = "";

    [StringLength(20)]
    public string? Phone { get; set; }

    [StringLength(255)]
    public string? Address { get; set; }

    // Optional geolocation data
    public double? Latitude { get; set; }
    public double? Longitude { get; set; }
}
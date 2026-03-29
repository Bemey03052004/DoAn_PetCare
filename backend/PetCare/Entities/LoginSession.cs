using System.ComponentModel.DataAnnotations;

namespace PetCare.Entities;

public class LoginSession
{
    [Key]
    public int Id { get; set; }
    
    public int UserId { get; set; }
    public User User { get; set; } = null!;
    
    [Required]
    [MaxLength(512)]
    public string RefreshToken { get; set; } = string.Empty;
    
    [MaxLength(100)]
    public string DeviceName { get; set; } = string.Empty;
    
    [MaxLength(50)]
    public string DeviceType { get; set; } = string.Empty; // Mobile, Web, Desktop
    
    [MaxLength(200)]
    public string UserAgent { get; set; } = string.Empty;
    
    [MaxLength(45)]
    public string IpAddress { get; set; } = string.Empty;
    
    [MaxLength(100)]
    public string Location { get; set; } = string.Empty; // City, Country based on IP
    
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime ExpiresAt { get; set; }
    public DateTime? LastUsedAt { get; set; }
    
    public bool IsActive { get; set; } = true;
    public bool IsRevoked { get; set; } = false;
    public DateTime? RevokedAt { get; set; }
}

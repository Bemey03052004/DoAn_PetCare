namespace PetCare.DTOs;

public class LoginRequestDto
{
    public string Email { get; set; } = string.Empty;
    public string Password { get; set; } = string.Empty;
    
    // Device information
    public string DeviceName { get; set; } = string.Empty;
    public string DeviceType { get; set; } = string.Empty; // Mobile, Web, Desktop
    public string UserAgent { get; set; } = string.Empty;
}

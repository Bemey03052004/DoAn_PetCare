namespace PetCare.DTOs;

public class AuthResponseDto
{
    public UserResponseDto User { get; set; } = null!;
    public string Token { get; set; } = "";
    public string RefreshToken { get; set; } = "";
    public DateTime Expiration { get; set; }
}
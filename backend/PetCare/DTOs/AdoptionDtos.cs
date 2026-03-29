namespace PetCare.DTOs;

public class CreateAdoptionRequestDto
{
    public string? Message { get; set; }
}

public class AdoptionRequestWithTagDto
{
    public int Id { get; set; }
    public int PetId { get; set; }
    public string PetName { get; set; } = string.Empty;
    public string? PetImageUrl { get; set; }
    public int UserId { get; set; }
    public string UserName { get; set; } = string.Empty;
    public int PetOwnerId { get; set; }
    public string PetOwnerName { get; set; } = string.Empty;
    public string? Message { get; set; }
    public string Status { get; set; } = string.Empty;
    public DateTime CreatedAt { get; set; }
    public DateTime UpdatedAt { get; set; }
    
    // Tag information
    public string PetTag { get; set; } = string.Empty; // "Cho", "Giữ dùm", "Bán"
    public bool IsForSale { get; set; }
    public bool IsForBoarding { get; set; }
    public decimal? SalePrice { get; set; }
    public decimal? BoardingPricePerDay { get; set; }
}



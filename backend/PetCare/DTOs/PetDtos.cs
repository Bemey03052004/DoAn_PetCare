namespace PetCare.DTOs;

public class CreatePetRequestDto
{
    public string Name { get; set; } = "";
    public string Species { get; set; } = "Dog";
    public string? Breed { get; set; }
    public string? Gender { get; set; }
    public int AgeMonths { get; set; }
    public string? ImageUrl { get; set; }
    public string? Description { get; set; }
    public int OwnerId { get; set; }
    public bool IsPublic { get; set; } = false;

    // Pet selling fields
    public bool IsForSale { get; set; } = false;
    public decimal? Price { get; set; }
    public string? SaleDescription { get; set; }

    // Pet boarding fields
    public bool IsForBoarding { get; set; } = false;
    public decimal? BoardingPricePerDay { get; set; }
    public DateTime? BoardingStartDate { get; set; }
    public DateTime? BoardingEndDate { get; set; }
    public string? BoardingDescription { get; set; }

    // Optional social profile
    public string? Personality { get; set; }
    public string? FavoriteFood { get; set; }
    public string? Hobbies { get; set; }
    public string? Story { get; set; }
    public string? SocialImage { get; set; }

    // Optional vaccination schedule dates
    public List<DateTime>? VaccinationDates { get; set; }
}

public class PublishPetRequestDto
{
    public bool IsPublic { get; set; }
}

public class PetDto
{
    public int Id { get; set; }
    public string Name { get; set; } = "";
    public string Species { get; set; } = "Dog";
    public string? Breed { get; set; }
    public string? Gender { get; set; }
    public int AgeMonths { get; set; }
    public int Age { get; set; }
    public string? ImageUrl { get; set; }
    public string? Description { get; set; }
    public bool IsAdopted { get; set; }
    public bool IsPublic { get; set; }
    public bool IsHidden { get; set; }
    
    // Pet selling fields
    public bool IsForSale { get; set; }
    public decimal? Price { get; set; }
    public string? SaleDescription { get; set; }

    // Pet boarding fields
    public bool IsForBoarding { get; set; }
    public decimal? BoardingPricePerDay { get; set; }
    public DateTime? BoardingStartDate { get; set; }
    public DateTime? BoardingEndDate { get; set; }
    public string? BoardingDescription { get; set; }

    public int OwnerId { get; set; }
    public string? OwnerName { get; set; }
    public DateTime CreatedAt { get; set; }
    public DateTime? UpdatedAt { get; set; }
}



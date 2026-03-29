using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using PetCare.DTOs;
using PetCare.Entities;
using PetCare.Repositories;

namespace PetCare.Controllers;

[ApiController]
[Route("api/[controller]")]
public class PetsController : ControllerBase
{
    private readonly IUnitOfWork _unitOfWork;

    public PetsController(IUnitOfWork unitOfWork)
    {
        _unitOfWork = unitOfWork;
    }

    [Authorize]
    [HttpGet("recommendations")]
    public async Task<ActionResult<ApiResponse<IEnumerable<Pet>>>> GetRecommendations()
    {
        var uid = int.Parse(User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)!.Value);
        var pref = (await _unitOfWork.Preferences.FindAsync(p => p.UserId == uid)).FirstOrDefault();
        if (pref == null)
        {
            return Ok(ApiResponse<IEnumerable<Pet>>.SuccessResponse(Enumerable.Empty<Pet>(), "No preferences yet"));
        }
        var pets = await _unitOfWork.Pets.GetPetsByPreferenceAsync(pref, pref.MaxDistanceKm);
        return Ok(ApiResponse<IEnumerable<Pet>>.SuccessResponse(pets));
    }
    [HttpGet]
    public async Task<ActionResult<ApiResponse<IEnumerable<Pet>>>> GetAll()
    {
        var pets = await _unitOfWork.Pets.GetAllAsync();
        return Ok(ApiResponse<IEnumerable<Pet>>.SuccessResponse(pets));
    }

    [HttpGet("available")]
    public async Task<ActionResult<ApiResponse<IEnumerable<Pet>>>> GetAvailable()
    {
        var pets = await _unitOfWork.Pets.GetAvailableForAdoptionAsync();
        return Ok(ApiResponse<IEnumerable<Pet>>.SuccessResponse(pets));
    }

    [HttpGet("{id:int}")]
    public async Task<ActionResult<ApiResponse<object>>> GetById(int id)
    {
        var pet = await _unitOfWork.Pets.GetByIdWithFullDetailsAsync(id);
        if (pet is null)
        {
            return NotFound(ApiResponse<object>.ErrorResponse("Pet not found"));
        }

        // Check if pet is currently being boarded (InProgress status)
        var boardingRequests = await _unitOfWork.BoardingRequests.GetAllAsync();
        var currentBoardingRequest = boardingRequests.FirstOrDefault(br => br.PetId == pet.Id && br.Status == "InProgress");
        var isCurrentlyBoarded = currentBoardingRequest != null;
        var currentBoardingCustomerId = currentBoardingRequest?.CustomerId;

        // Create response object with additional boarding status
        var response = new
        {
            pet.Id,
            pet.Name,
            pet.Species,
            pet.Breed,
            pet.Gender,
            pet.AgeMonths,
            pet.ImageUrl,
            pet.Description,
            pet.IsAdopted,
            pet.IsPublic,
            pet.IsHidden,
            pet.IsForSale,
            pet.Price,
            pet.SaleDescription,
            pet.IsForBoarding,
            pet.BoardingPricePerDay,
            pet.BoardingStartDate,
            pet.BoardingEndDate,
            pet.BoardingDescription,
            pet.OwnerId,
            pet.Owner,
            pet.Profile,
            pet.VaccinationSchedules,
            pet.AdoptionRequests,
            pet.CreatedAt,
            pet.UpdatedAt,
            IsCurrentlyBoarded = isCurrentlyBoarded,
            CurrentBoardingCustomerId = currentBoardingCustomerId
        };

        return Ok(ApiResponse<object>.SuccessResponse(response));
    }

    [HttpGet("owner/{ownerId:int}")]
    public async Task<ActionResult<ApiResponse<IEnumerable<Pet>>>> GetByOwnerId(int ownerId)
    {
        // Check if owner exists
        if (await _unitOfWork.Users.GetByIdAsync(ownerId) == null)
        {
            return NotFound(ApiResponse<IEnumerable<Pet>>.ErrorResponse("Owner not found"));
        }

        var pets = await _unitOfWork.Pets.GetByOwnerIdAsync(ownerId);
        return Ok(ApiResponse<IEnumerable<Pet>>.SuccessResponse(pets));
    }

    [HttpGet("public")]
    public async Task<ActionResult<ApiResponse<IEnumerable<Pet>>>> GetPublic(
        [FromQuery] string? species,
        [FromQuery] int? minAgeMonths,
        [FromQuery] int? maxAgeMonths,
        [FromQuery] string? keyword,
        [FromQuery] double? lat,
        [FromQuery] double? lng,
        [FromQuery] double? maxDistanceKm,
        [FromQuery] string? filter = "all", // all, sale, boarding, free
        [FromQuery] string? sortBy = "newest") // newest, oldest, price_low, price_high
    {
        var pets = await _unitOfWork.Pets.GetPublicPetsAsync(species, minAgeMonths, maxAgeMonths, keyword, lat, lng, maxDistanceKm);
        
        // Apply filter
        pets = (filter?.ToLower() ?? "all") switch
        {
            "sale" => pets.Where(p => p.IsForSale == true && !p.IsHidden),
            "boarding" => pets.Where(p => p.IsForBoarding == true && !p.IsHidden),
            "free" => pets.Where(p => p.IsForSale != true && p.IsForBoarding != true && !p.IsHidden),
            _ => pets.Where(p => !p.IsHidden) // "all" or any other value - exclude hidden pets
        };

        // Apply sorting
        pets = (sortBy?.ToLower() ?? "newest") switch
        {
            "oldest" => pets.OrderBy(p => p.CreatedAt),
            "price_low" => pets.OrderBy(p => p.Price ?? 0),
            "price_high" => pets.OrderByDescending(p => p.Price ?? 0),
            _ => pets.OrderByDescending(p => p.CreatedAt) // "newest" or default
        };

        return Ok(ApiResponse<IEnumerable<Pet>>.SuccessResponse(pets));
    }

    [Authorize]
    [HttpPost]
    public async Task<ActionResult<ApiResponse<Pet>>> Create([FromBody] CreatePetRequestDto dto)
    {
        // Owner is current user or Admin
        if (await _unitOfWork.Users.GetByIdAsync(dto.OwnerId) == null)
        {
            return BadRequest(ApiResponse<Pet>.ErrorResponse($"Owner with ID {dto.OwnerId} does not exist"));
        }

        var pet = new Pet
        {
            Name = dto.Name,
            Species = dto.Species,
            Breed = dto.Breed,
            Gender = dto.Gender,
            AgeMonths = dto.AgeMonths,
            ImageUrl = dto.ImageUrl,
            Description = dto.Description,
            OwnerId = dto.OwnerId,
            IsPublic = dto.IsPublic,
            IsForSale = dto.IsForSale,
            Price = dto.Price,
            SaleDescription = dto.SaleDescription,
            IsForBoarding = dto.IsForBoarding,
            BoardingPricePerDay = dto.BoardingPricePerDay,
            BoardingStartDate = dto.BoardingStartDate,
            BoardingEndDate = dto.BoardingEndDate,
            BoardingDescription = dto.BoardingDescription,
        };

        var createdPet = await _unitOfWork.Pets.AddAsync(pet);

        // Optional profile
        if (!string.IsNullOrWhiteSpace(dto.Personality) ||
            !string.IsNullOrWhiteSpace(dto.FavoriteFood) ||
            !string.IsNullOrWhiteSpace(dto.Hobbies) ||
            !string.IsNullOrWhiteSpace(dto.Story) ||
            !string.IsNullOrWhiteSpace(dto.SocialImage))
        {
            var profile = new PetProfile
            {
                PetId = createdPet.Id,
                Personality = dto.Personality,
                FavoriteFood = dto.FavoriteFood,
                Hobbies = dto.Hobbies,
                Story = dto.Story,
                SocialImage = dto.SocialImage,
            };
            await _unitOfWork.PetProfiles.AddAsync(profile);
        }

        // Optional vaccination schedules
        if (dto.VaccinationDates != null && dto.VaccinationDates.Count > 0)
        {
            foreach (var d in dto.VaccinationDates)
            {
                var sch = new VaccinationSchedule
                {
                    PetId = createdPet.Id,
                    VaccineName = "Vaccine",
                    ScheduledDate = d,
                    IsCompleted = false,
                    CreatedAt = DateTime.UtcNow
                };
                await _unitOfWork.VaccinationSchedules.AddAsync(sch);
            }
        }

        return CreatedAtAction(nameof(GetById), new { id = createdPet.Id }, 
            ApiResponse<Pet>.SuccessResponse(createdPet));
    }

    [Authorize]
    [HttpPut("{id:int}")]
    public async Task<ActionResult<ApiResponse<Pet>>> Update(int id, [FromBody] Pet pet)
    {
        var existing = await _unitOfWork.Pets.GetByIdAsync(id);
        if (existing is null) 
        {
            return NotFound(ApiResponse<Pet>.ErrorResponse("Pet not found"));
        }

        // Check if owner exists if owner is being changed
        if (existing.OwnerId != pet.OwnerId && await _unitOfWork.Users.GetByIdAsync(pet.OwnerId) == null)
        {
            return BadRequest(ApiResponse<Pet>.ErrorResponse($"Owner with ID {pet.OwnerId} does not exist"));
        }

        existing.Name = pet.Name;
        existing.Species = pet.Species;
        existing.Breed = pet.Breed;
        existing.Gender = pet.Gender;
        existing.AgeMonths = pet.AgeMonths;
        existing.ImageUrl = pet.ImageUrl;
        existing.Description = pet.Description;
        existing.IsAdopted = pet.IsAdopted;
        existing.OwnerId = pet.OwnerId;
        existing.IsPublic = pet.IsPublic;
        existing.IsForSale = pet.IsForSale;
        existing.Price = pet.Price;
        existing.SaleDescription = pet.SaleDescription;
        existing.IsForBoarding = pet.IsForBoarding;
        existing.BoardingPricePerDay = pet.BoardingPricePerDay;
        existing.BoardingStartDate = pet.BoardingStartDate;
        existing.BoardingEndDate = pet.BoardingEndDate;
        existing.BoardingDescription = pet.BoardingDescription;

        await _unitOfWork.Pets.UpdateAsync(existing);
        return Ok(ApiResponse<Pet>.SuccessResponse(existing));
    }

    [Authorize]
    [HttpDelete("{id:int}")]
    public async Task<ActionResult<ApiResponse<object>>> Delete(int id)
    {
        var pet = await _unitOfWork.Pets.GetByIdAsync(id);
        if (pet == null)
        {
            return NotFound(ApiResponse<object>.ErrorResponse("Pet not found"));
        }

        // Kiểm tra quyền sở hữu
        var userIdClaim = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value;
        var isAdmin = User.IsInRole("Admin");
        
        if (!isAdmin && (!int.TryParse(userIdClaim, out var currentUserId) || currentUserId != pet.OwnerId))
        {
            return Forbid("You can only delete your own pets");
        }

        // Xóa pet
        await _unitOfWork.Pets.DeleteAsync(pet);
        await _unitOfWork.SaveAsync();

        return Ok(ApiResponse<object>.SuccessResponse(null, "Pet deleted successfully"));
    }

    [Authorize]
    [HttpPut("{id:int}/publish")]
    public async Task<ActionResult<ApiResponse<Pet>>> Publish(int id, [FromBody] PublishPetRequestDto body)
    {
        var existing = await _unitOfWork.Pets.GetByIdAsync(id);
        if (existing is null)
        {
            return NotFound(ApiResponse<Pet>.ErrorResponse("Pet not found"));
        }

        // Ownership check: only owner or Admin can change publish status
        var userIdClaim = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value;
        var userIsAdmin = User.IsInRole("Admin");
        if (!userIsAdmin && (!int.TryParse(userIdClaim, out var currentUserId) || currentUserId != existing.OwnerId))
        {
            return Forbid();
        }

        existing.IsPublic = body.IsPublic;
        await _unitOfWork.Pets.UpdateAsync(existing);
        return Ok(ApiResponse<Pet>.SuccessResponse(existing));
    }

    [Authorize]
    [HttpPut("{id:int}/show-again")]
    public async Task<ActionResult<ApiResponse<Pet>>> ShowPetAgain(int id)
    {
        var existing = await _unitOfWork.Pets.GetByIdAsync(id);
        if (existing is null)
        {
            return NotFound(ApiResponse<Pet>.ErrorResponse("Pet not found"));
        }

        // Ownership check: only owner or Admin can show pet again
        var userIdClaim = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value;
        var userIsAdmin = User.IsInRole("Admin");
        if (!userIsAdmin && (!int.TryParse(userIdClaim, out var currentUserId) || currentUserId != existing.OwnerId))
        {
            return Forbid();
        }

        // Only allow showing pet again if it's currently adopted
        if (!existing.IsAdopted)
        {
            return BadRequest(ApiResponse<Pet>.ErrorResponse("Pet is not adopted, cannot show again"));
        }

        // Reset adoption status and make it public again
        existing.IsAdopted = false;
        existing.IsPublic = true;
        existing.UpdatedAt = DateTime.UtcNow;
        
        await _unitOfWork.Pets.UpdateAsync(existing);
        return Ok(ApiResponse<Pet>.SuccessResponse(existing));
    }

    [Authorize]
    [HttpPost("{id:int}/adoptions")]
    public async Task<ActionResult<ApiResponse<AdoptionRequest>>> CreateAdoptionRequest(int id, [FromBody] CreateAdoptionRequestDto body)
    {
        var pet = await _unitOfWork.Pets.GetByIdAsync(id);
        if (pet is null)
        {
            return NotFound(ApiResponse<AdoptionRequest>.ErrorResponse("Pet not found"));
        }

        var userIdClaim = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value;
        if (!int.TryParse(userIdClaim, out var currentUserId))
        {
            return Unauthorized(ApiResponse<AdoptionRequest>.ErrorResponse("Unauthorized"));
        }
        if (pet.OwnerId == currentUserId)
        {
            return BadRequest(ApiResponse<AdoptionRequest>.ErrorResponse("You cannot adopt your own pet"));
        }

        var request = new AdoptionRequest
        {
            PetId = pet.Id,
            UserId = currentUserId,
            Message = body.Message,
            Status = "Pending",
            CreatedAt = DateTime.UtcNow
        };

        var created = await _unitOfWork.AdoptionRequests.AddAsync(request);
        return CreatedAtAction(nameof(GetById), new { id = pet.Id }, ApiResponse<AdoptionRequest>.SuccessResponse(created, "Adoption request created"));
    }

    [Authorize]
    [HttpGet("{id:int}/adoptions")]
    public async Task<ActionResult<ApiResponse<IEnumerable<AdoptionRequest>>>> GetAdoptionRequests(int id)
    {
        var pet = await _unitOfWork.Pets.GetByIdAsync(id);
        if (pet is null)
        {
            return NotFound(ApiResponse<IEnumerable<AdoptionRequest>>.ErrorResponse("Pet not found"));
        }
        var userIdClaim = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value;
        var userIsAdmin = User.IsInRole("Admin");
        if (!userIsAdmin && (!int.TryParse(userIdClaim, out var currentUserId) || currentUserId != pet.OwnerId))
        {
            return Forbid();
        }
        var list = await _unitOfWork.AdoptionRequests.FindAsync(a => a.PetId == id);
        return Ok(ApiResponse<IEnumerable<AdoptionRequest>>.SuccessResponse(list, "Adoption requests"));
    }

    [Authorize]
    [HttpPut("adoptions/{adoptionId:int}/accept")]
    public async Task<ActionResult<ApiResponse<AdoptionRequest>>> AcceptAdoption(int adoptionId)
    {
        var req = await _unitOfWork.AdoptionRequests.GetByIdAsync(adoptionId);
        if (req is null)
        {
            return NotFound(ApiResponse<AdoptionRequest>.ErrorResponse("Request not found"));
        }
        var pet = await _unitOfWork.Pets.GetByIdAsync(req.PetId);
        if (pet is null)
        {
            return NotFound(ApiResponse<AdoptionRequest>.ErrorResponse("Pet not found"));
        }
        var userIdClaim = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value;
        var userIsAdmin = User.IsInRole("Admin");
        if (!userIsAdmin && (!int.TryParse(userIdClaim, out var currentUserId) || currentUserId != pet.OwnerId))
        {
            return Forbid();
        }
        req.Status = "Accepted";
        await _unitOfWork.AdoptionRequests.UpdateAsync(req);
        // Mark pet adopted and hide from public
        pet.IsAdopted = true;
        pet.IsPublic = false;
        await _unitOfWork.Pets.UpdateAsync(pet);
        return Ok(ApiResponse<AdoptionRequest>.SuccessResponse(req, "Adoption accepted"));
    }

    [Authorize]
    [HttpPut("adoptions/{adoptionId:int}/decline")]
    public async Task<ActionResult<ApiResponse<AdoptionRequest>>> DeclineAdoption(int adoptionId)
    {
        var req = await _unitOfWork.AdoptionRequests.GetByIdAsync(adoptionId);
        if (req is null)
        {
            return NotFound(ApiResponse<AdoptionRequest>.ErrorResponse("Request not found"));
        }
        var pet = await _unitOfWork.Pets.GetByIdAsync(req.PetId);
        if (pet is null)
        {
            return NotFound(ApiResponse<AdoptionRequest>.ErrorResponse("Pet not found"));
        }
        var userIdClaim = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value;
        var userIsAdmin = User.IsInRole("Admin");
        if (!userIsAdmin && (!int.TryParse(userIdClaim, out var currentUserId) || currentUserId != pet.OwnerId))
        {
            return Forbid();
        }
        req.Status = "Declined";
        await _unitOfWork.AdoptionRequests.UpdateAsync(req);
        return Ok(ApiResponse<AdoptionRequest>.SuccessResponse(req, "Adoption declined"));
    }

    [Authorize]
    [HttpPut("adoptions/{adoptionId:int}/reopen")]
    public async Task<ActionResult<ApiResponse<AdoptionRequest>>> ReopenAdoption(int adoptionId)
    {
        var req = await _unitOfWork.AdoptionRequests.GetByIdAsync(adoptionId);
        if (req is null)
        {
            return NotFound(ApiResponse<AdoptionRequest>.ErrorResponse("Request not found"));
        }
        var pet = await _unitOfWork.Pets.GetByIdAsync(req.PetId);
        if (pet is null)
        {
            return NotFound(ApiResponse<AdoptionRequest>.ErrorResponse("Pet not found"));
        }
        var userIdClaim = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value;
        var userIsAdmin = User.IsInRole("Admin");
        if (!userIsAdmin && (!int.TryParse(userIdClaim, out var currentUserId) || currentUserId != pet.OwnerId))
        {
            return Forbid();
        }
        // Reopen request to Pending and make pet public again (not adopted)
        req.Status = "Pending";
        await _unitOfWork.AdoptionRequests.UpdateAsync(req);
        pet.IsAdopted = false;
        pet.IsPublic = true;
        await _unitOfWork.Pets.UpdateAsync(pet);
        return Ok(ApiResponse<AdoptionRequest>.SuccessResponse(req, "Adoption reopened to pending"));
    }


    [Authorize]
    [HttpPut("{id:int}/hide")]
    public async Task<ActionResult<ApiResponse<object>>> HidePet(int id)
    {
        var pet = await _unitOfWork.Pets.GetByIdAsync(id);
        if (pet == null)
        {
            return NotFound(ApiResponse<object>.ErrorResponse("Pet not found"));
        }

        // Kiểm tra quyền sở hữu
        var userIdClaim = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value;
        var isAdmin = User.IsInRole("Admin");
        
        if (!isAdmin && (!int.TryParse(userIdClaim, out var currentUserId) || currentUserId != pet.OwnerId))
        {
            return Forbid("You can only hide your own pets");
        }

        // Ẩn pet
        pet.IsPublic = false;
        await _unitOfWork.Pets.UpdateAsync(pet);
        await _unitOfWork.SaveAsync();

        return Ok(ApiResponse<object>.SuccessResponse(null, "Pet hidden successfully"));
    }

    [Authorize]
    [HttpPut("{id:int}/show")]
    public async Task<ActionResult<ApiResponse<object>>> ShowPet(int id)
    {
        var pet = await _unitOfWork.Pets.GetByIdAsync(id);
        if (pet == null)
        {
            return NotFound(ApiResponse<object>.ErrorResponse("Pet not found"));
        }

        // Kiểm tra quyền sở hữu
        var userIdClaim = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value;
        var isAdmin = User.IsInRole("Admin");
        
        if (!isAdmin && (!int.TryParse(userIdClaim, out var currentUserId) || currentUserId != pet.OwnerId))
        {
            return Forbid("You can only show your own pets");
        }

        // Hiện pet
        pet.IsPublic = true;
        await _unitOfWork.Pets.UpdateAsync(pet);
        await _unitOfWork.SaveAsync();

        return Ok(ApiResponse<object>.SuccessResponse(null, "Pet shown successfully"));
    }

    [Authorize]
    [HttpDelete("batch")]
    public async Task<ActionResult<ApiResponse<object>>> DeletePetsBatch([FromBody] int[] petIds)
    {
        if (petIds == null || petIds.Length == 0)
        {
            return BadRequest(ApiResponse<object>.ErrorResponse("No pet IDs provided"));
        }

        var userIdClaim = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value;
        var isAdmin = User.IsInRole("Admin");
        var currentUserId = int.Parse(userIdClaim!);

        var deletedCount = 0;
        var errors = new List<string>();

        foreach (var petId in petIds)
        {
            var pet = await _unitOfWork.Pets.GetByIdAsync(petId);
            if (pet == null)
            {
                errors.Add($"Pet with ID {petId} not found");
                continue;
            }

            // Kiểm tra quyền sở hữu
            if (!isAdmin && pet.OwnerId != currentUserId)
            {
                errors.Add($"You don't have permission to delete pet {petId}");
                continue;
            }

            // Xóa pet
            await _unitOfWork.Pets.DeleteAsync(pet);
            deletedCount++;
        }

        if (deletedCount > 0)
        {
            await _unitOfWork.SaveAsync();
        }

        var message = deletedCount > 0 
            ? $"Successfully deleted {deletedCount} pet(s)" 
            : "No pets were deleted";

        if (errors.Count > 0)
        {
            message += $". Errors: {string.Join(", ", errors)}";
        }

        return Ok(ApiResponse<object>.SuccessResponse(null, message));
    }
}

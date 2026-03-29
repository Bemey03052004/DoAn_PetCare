using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using PetCare.DTOs;
using PetCare.Entities;
using PetCare.Repositories;

namespace PetCare.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize]
public class AdoptionController : ControllerBase
{
    private readonly IUnitOfWork _unitOfWork;

    public AdoptionController(IUnitOfWork unitOfWork)
    {
        _unitOfWork = unitOfWork;
    }

    [HttpGet("my")]
    public async Task<ActionResult<ApiResponse<IEnumerable<AdoptionRequestWithTagDto>>>> GetMyAdoptionRequests()
    {
        var userIdClaim = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value;
        if (!int.TryParse(userIdClaim, out var currentUserId))
        {
            return Unauthorized(ApiResponse<IEnumerable<AdoptionRequestWithTagDto>>.ErrorResponse("Unauthorized"));
        }
        
        var adoptionRequests = await _unitOfWork.AdoptionRequests.FindAsync(a => a.UserId == currentUserId);
        var result = new List<AdoptionRequestWithTagDto>();
        
        foreach (var request in adoptionRequests)
        {
            var pet = await _unitOfWork.Pets.GetByIdAsync(request.PetId);
            var user = await _unitOfWork.Users.GetByIdAsync(request.UserId);
            var petOwner = pet != null ? await _unitOfWork.Users.GetByIdAsync(pet.OwnerId) : null;
            
            // Determine pet tag based on pet properties
            string petTag = "Cho"; // Default
            if (pet?.IsForSale == true)
            {
                petTag = "Bán";
            }
            else if (pet?.IsForBoarding == true)
            {
                petTag = "Giữ dùm";
            }
            
            result.Add(new AdoptionRequestWithTagDto
            {
                Id = request.Id,
                PetId = request.PetId,
                PetName = pet?.Name ?? "",
                PetImageUrl = pet?.ImageUrl,
                UserId = request.UserId,
                UserName = user?.FullName ?? "",
                PetOwnerId = pet?.OwnerId ?? 0,
                PetOwnerName = petOwner?.FullName ?? "",
                Message = request.Message,
                Status = request.Status,
                CreatedAt = request.CreatedAt,
                UpdatedAt = request.CreatedAt, // Use CreatedAt as UpdatedAt since it doesn't exist
                PetTag = petTag,
                IsForSale = pet?.IsForSale ?? false,
                IsForBoarding = pet?.IsForBoarding ?? false,
                SalePrice = pet?.Price,
                BoardingPricePerDay = pet?.BoardingPricePerDay,
            });
        }
        
        return Ok(ApiResponse<IEnumerable<AdoptionRequestWithTagDto>>.SuccessResponse(result, "My adoption requests"));
    }

    [HttpGet("received")]
    public async Task<ActionResult<ApiResponse<IEnumerable<AdoptionRequest>>>> GetReceivedAdoptionRequests()
    {
        var userIdClaim = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value;
        if (!int.TryParse(userIdClaim, out var currentUserId))
        {
            return Unauthorized(ApiResponse<IEnumerable<AdoptionRequest>>.ErrorResponse("Unauthorized"));
        }

        // Get all pets owned by current user
        var myPets = await _unitOfWork.Pets.FindAsync(p => p.OwnerId == currentUserId);
        var petIds = myPets.Select(p => p.Id).ToHashSet();
        if (petIds.Count == 0)
        {
            return Ok(ApiResponse<IEnumerable<AdoptionRequest>>.SuccessResponse(Enumerable.Empty<AdoptionRequest>(), "No requests"));
        }

        var list = await _unitOfWork.AdoptionRequests.FindAsync(a => petIds.Contains(a.PetId));
        return Ok(ApiResponse<IEnumerable<AdoptionRequest>>.SuccessResponse(list, "Received adoption requests"));
    }

    [HttpDelete("{adoptionId:int}")]
    public async Task<ActionResult<ApiResponse<object>>> CancelMyAdoptionRequest(int adoptionId)
    {
        var userIdClaim = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value;
        if (!int.TryParse(userIdClaim, out var currentUserId))
        {
            return Unauthorized(ApiResponse<object>.ErrorResponse("Unauthorized"));
        }

        var req = await _unitOfWork.AdoptionRequests.GetByIdAsync(adoptionId);
        if (req is null)
        {
            return NotFound(ApiResponse<object>.ErrorResponse("Request not found"));
        }
        if (req.UserId != currentUserId)
        {
            return Forbid();
        }
        if (req.Status != "Pending")
        {
            return BadRequest(ApiResponse<object>.ErrorResponse("Only pending requests can be cancelled"));
        }
        await _unitOfWork.AdoptionRequests.DeleteAsync(req);
        return Ok(ApiResponse<object>.SuccessResponse(null, "Cancelled"));
    }
}



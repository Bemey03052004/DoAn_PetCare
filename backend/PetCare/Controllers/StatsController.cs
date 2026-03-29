using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using PetCare.DTOs;
using PetCare.Repositories;

namespace PetCare.Controllers;

[ApiController]
[Route("api/[controller]")]
public class StatsController : ControllerBase
{
    private readonly IUnitOfWork _uow;
    public StatsController(IUnitOfWork uow)
    {
        _uow = uow;
    }

    [HttpGet("admin")]
    [Authorize(Roles = "Admin")]
    public async Task<ActionResult<ApiResponse<object>>> AdminStats()
    {
        var totalUsers = (await _uow.Users.GetAllAsync()).Count();
        var totalPets = (await _uow.Pets.GetAllAsync()).Count();
        var adoptedPets = (await _uow.Pets.FindAsync(p => p.IsAdopted)).Count();
        var pendingAdoptions = (await _uow.AdoptionRequests.FindAsync(a => a.Status == "Pending")).Count();
        var acceptedAdoptions = (await _uow.AdoptionRequests.FindAsync(a => a.Status == "Accepted")).Count();

        return Ok(ApiResponse<object>.SuccessResponse(new
        {
            totalUsers,
            totalPets,
            adoptedPets,
            pendingAdoptions,
            acceptedAdoptions
        }));
    }

    [HttpGet("user")]
    [Authorize]
    public async Task<ActionResult<ApiResponse<object>>> UserStats()
    {
        var userIdClaim = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value;
        if (!int.TryParse(userIdClaim, out var currentUserId))
        {
            return Unauthorized(ApiResponse<object>.ErrorResponse("Unauthorized"));
        }

        var myPets = await _uow.Pets.FindAsync(p => p.OwnerId == currentUserId);
        var myPetIds = myPets.Select(p => p.Id).ToHashSet();
        var givenCount = myPets.Count();
        var givenAdopted = myPets.Count(p => p.IsAdopted);

        var myRequests = await _uow.AdoptionRequests.FindAsync(a => a.UserId == currentUserId);
        var requestedCount = myRequests.Count();
        var acceptedCount = myRequests.Count(a => a.Status == "Accepted");
        var pendingCount = myRequests.Count(a => a.Status == "Pending");

        var receivedRequests = await _uow.AdoptionRequests.FindAsync(a => myPetIds.Contains(a.PetId));
        var receivedPending = receivedRequests.Count(a => a.Status == "Pending");

        return Ok(ApiResponse<object>.SuccessResponse(new
        {
            givenCount,
            givenAdopted,
            requestedCount,
            acceptedCount,
            pendingCount,
            receivedPending
        }));
    }
}



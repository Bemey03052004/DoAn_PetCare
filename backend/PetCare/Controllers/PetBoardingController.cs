using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using PetCare.DTOs;
using PetCare.Entities;
using PetCare.Repositories;

namespace PetCare.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize]
public class PetBoardingController : ControllerBase
{
    private readonly IUnitOfWork _unitOfWork;

    public PetBoardingController(IUnitOfWork unitOfWork)
    {
        _unitOfWork = unitOfWork;
    }

    [HttpPost("request")]
    public async Task<ActionResult<ApiResponse<BoardingRequestResponseDto>>> CreateBoardingRequest([FromBody] CreateBoardingRequestDto request)
    {
        try
        {
            var userId = int.Parse(User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)!.Value);

            // Get pet details
            var pet = await _unitOfWork.Pets.GetByIdAsync(request.PetId);
            if (pet == null)
            {
                return NotFound(ApiResponse<BoardingRequestResponseDto>.ErrorResponse("Pet not found"));
            }

            // Check if pet is available for boarding
            if (!pet.IsForBoarding)
            {
                return BadRequest(ApiResponse<BoardingRequestResponseDto>.ErrorResponse("This pet is not available for boarding"));
            }

            // Check if user is not the pet owner
            if (pet.OwnerId == userId)
            {
                return BadRequest(ApiResponse<BoardingRequestResponseDto>.ErrorResponse("You cannot request boarding for your own pet"));
            }

            // Validate dates
            if (request.StartDate >= request.EndDate)
            {
                return BadRequest(ApiResponse<BoardingRequestResponseDto>.ErrorResponse("End date must be after start date"));
            }

            if (request.StartDate < DateTime.Today)
            {
                return BadRequest(ApiResponse<BoardingRequestResponseDto>.ErrorResponse("Start date cannot be in the past"));
            }

            // Calculate total price
            var days = (request.EndDate - request.StartDate).Days;
            var totalPrice = days * (pet.BoardingPricePerDay ?? 0);

            // Create boarding request
            var boardingRequest = new PetBoardingRequest
            {
                PetId = request.PetId,
                RequesterId = userId,
                PetOwnerId = pet.OwnerId,
                StartDate = request.StartDate,
                EndDate = request.EndDate,
                TotalPrice = totalPrice,
                SpecialInstructions = request.SpecialInstructions,
                ContactPhone = request.ContactPhone,
                ContactAddress = request.ContactAddress,
                Status = "Pending"
            };

            await _unitOfWork.PetBoardingRequests.AddAsync(boardingRequest);
            await _unitOfWork.SaveChangesAsync();

            // Get requester and owner details
            var requester = await _unitOfWork.Users.GetByIdAsync(userId);
            var owner = await _unitOfWork.Users.GetByIdAsync(pet.OwnerId);

            var response = new BoardingRequestResponseDto
            {
                Id = boardingRequest.Id,
                PetId = pet.Id,
                PetName = pet.Name,
                PetImageUrl = pet.ImageUrl ?? "",
                RequesterId = userId,
                RequesterName = requester?.FullName ?? "",
                PetOwnerId = pet.OwnerId,
                PetOwnerName = owner?.FullName ?? "",
                StartDate = boardingRequest.StartDate,
                EndDate = boardingRequest.EndDate,
                TotalPrice = boardingRequest.TotalPrice,
                SpecialInstructions = boardingRequest.SpecialInstructions,
                ContactPhone = boardingRequest.ContactPhone,
                ContactAddress = boardingRequest.ContactAddress,
                Status = boardingRequest.Status,
                CreatedAt = boardingRequest.CreatedAt
            };

            return Ok(ApiResponse<BoardingRequestResponseDto>.SuccessResponse(response, "Boarding request created successfully"));
        }
        catch (Exception ex)
        {
            return StatusCode(500, ApiResponse<BoardingRequestResponseDto>.ErrorResponse($"An error occurred: {ex.Message}"));
        }
    }

    [HttpGet("my-requests")]
    public async Task<ActionResult<ApiResponse<IEnumerable<BoardingRequestResponseDto>>>> GetMyBoardingRequests()
    {
        try
        {
            var userId = int.Parse(User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)!.Value);

            var requests = await _unitOfWork.PetBoardingRequests.FindAsync(br => br.RequesterId == userId);
            var response = new List<BoardingRequestResponseDto>();

            foreach (var request in requests)
            {
                var pet = await _unitOfWork.Pets.GetByIdAsync(request.PetId);
                var requester = await _unitOfWork.Users.GetByIdAsync(request.RequesterId);
                var owner = await _unitOfWork.Users.GetByIdAsync(request.PetOwnerId);

                response.Add(new BoardingRequestResponseDto
                {
                    Id = request.Id,
                    PetId = request.PetId,
                    PetName = pet?.Name ?? "",
                    PetImageUrl = pet?.ImageUrl ?? "",
                    RequesterId = request.RequesterId,
                    RequesterName = requester?.FullName ?? "",
                    PetOwnerId = request.PetOwnerId,
                    PetOwnerName = owner?.FullName ?? "",
                    StartDate = request.StartDate,
                    EndDate = request.EndDate,
                    TotalPrice = request.TotalPrice,
                    SpecialInstructions = request.SpecialInstructions,
                    ContactPhone = request.ContactPhone,
                    ContactAddress = request.ContactAddress,
                    Status = request.Status,
                    CreatedAt = request.CreatedAt,
                    UpdatedAt = request.UpdatedAt,
                    OwnerNotes = request.OwnerNotes,
                    RequesterNotes = request.RequesterNotes
                });
            }

            return Ok(ApiResponse<IEnumerable<BoardingRequestResponseDto>>.SuccessResponse(response));
        }
        catch (Exception ex)
        {
            return StatusCode(500, ApiResponse<IEnumerable<BoardingRequestResponseDto>>.ErrorResponse($"An error occurred: {ex.Message}"));
        }
    }

    [HttpGet("received-requests")]
    public async Task<ActionResult<ApiResponse<IEnumerable<BoardingRequestResponseDto>>>> GetReceivedBoardingRequests()
    {
        try
        {
            var userId = int.Parse(User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)!.Value);

            var requests = await _unitOfWork.PetBoardingRequests.FindAsync(br => br.PetOwnerId == userId);
            var response = new List<BoardingRequestResponseDto>();

            foreach (var request in requests)
            {
                var pet = await _unitOfWork.Pets.GetByIdAsync(request.PetId);
                var requester = await _unitOfWork.Users.GetByIdAsync(request.RequesterId);
                var owner = await _unitOfWork.Users.GetByIdAsync(request.PetOwnerId);

                response.Add(new BoardingRequestResponseDto
                {
                    Id = request.Id,
                    PetId = request.PetId,
                    PetName = pet?.Name ?? "",
                    PetImageUrl = pet?.ImageUrl ?? "",
                    RequesterId = request.RequesterId,
                    RequesterName = requester?.FullName ?? "",
                    PetOwnerId = request.PetOwnerId,
                    PetOwnerName = owner?.FullName ?? "",
                    StartDate = request.StartDate,
                    EndDate = request.EndDate,
                    TotalPrice = request.TotalPrice,
                    SpecialInstructions = request.SpecialInstructions,
                    ContactPhone = request.ContactPhone,
                    ContactAddress = request.ContactAddress,
                    Status = request.Status,
                    CreatedAt = request.CreatedAt,
                    UpdatedAt = request.UpdatedAt,
                    OwnerNotes = request.OwnerNotes,
                    RequesterNotes = request.RequesterNotes
                });
            }

            return Ok(ApiResponse<IEnumerable<BoardingRequestResponseDto>>.SuccessResponse(response));
        }
        catch (Exception ex)
        {
            return StatusCode(500, ApiResponse<IEnumerable<BoardingRequestResponseDto>>.ErrorResponse($"An error occurred: {ex.Message}"));
        }
    }

    [HttpPut("{id:int}")]
    public async Task<ActionResult<ApiResponse<BoardingRequestResponseDto>>> UpdateBoardingRequest(int id, [FromBody] UpdateBoardingRequestDto request)
    {
        try
        {
            var userId = int.Parse(User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)!.Value);

            var boardingRequest = await _unitOfWork.PetBoardingRequests.GetByIdAsync(id);
            if (boardingRequest == null)
            {
                return NotFound(ApiResponse<BoardingRequestResponseDto>.ErrorResponse("Boarding request not found"));
            }

            // Check if user is the pet owner (can update status and notes)
            if (boardingRequest.PetOwnerId != userId)
            {
                return Forbid("You can only update boarding requests for your own pets");
            }

            // Update fields
            if (!string.IsNullOrEmpty(request.Status))
            {
                boardingRequest.Status = request.Status;
            }

            if (request.OwnerNotes != null)
            {
                boardingRequest.OwnerNotes = request.OwnerNotes;
            }

            boardingRequest.UpdatedAt = DateTime.UtcNow;

            await _unitOfWork.PetBoardingRequests.UpdateAsync(boardingRequest);
            await _unitOfWork.SaveChangesAsync();

            // Get updated details
            var pet = await _unitOfWork.Pets.GetByIdAsync(boardingRequest.PetId);
            var requester = await _unitOfWork.Users.GetByIdAsync(boardingRequest.RequesterId);
            var owner = await _unitOfWork.Users.GetByIdAsync(boardingRequest.PetOwnerId);

            var response = new BoardingRequestResponseDto
            {
                Id = boardingRequest.Id,
                PetId = boardingRequest.PetId,
                PetName = pet?.Name ?? "",
                PetImageUrl = pet?.ImageUrl ?? "",
                RequesterId = boardingRequest.RequesterId,
                RequesterName = requester?.FullName ?? "",
                PetOwnerId = boardingRequest.PetOwnerId,
                PetOwnerName = owner?.FullName ?? "",
                StartDate = boardingRequest.StartDate,
                EndDate = boardingRequest.EndDate,
                TotalPrice = boardingRequest.TotalPrice,
                SpecialInstructions = boardingRequest.SpecialInstructions,
                ContactPhone = boardingRequest.ContactPhone,
                ContactAddress = boardingRequest.ContactAddress,
                Status = boardingRequest.Status,
                CreatedAt = boardingRequest.CreatedAt,
                UpdatedAt = boardingRequest.UpdatedAt,
                OwnerNotes = boardingRequest.OwnerNotes,
                RequesterNotes = boardingRequest.RequesterNotes
            };

            return Ok(ApiResponse<BoardingRequestResponseDto>.SuccessResponse(response, "Boarding request updated successfully"));
        }
        catch (Exception ex)
        {
            return StatusCode(500, ApiResponse<BoardingRequestResponseDto>.ErrorResponse($"An error occurred: {ex.Message}"));
        }
    }
}

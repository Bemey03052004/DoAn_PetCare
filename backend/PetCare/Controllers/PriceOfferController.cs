using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using PetCare.DTOs;
using PetCare.Entities;
using PetCare.Repositories;
using System.Security.Claims;

namespace PetCare.Controllers;

[ApiController]
[Route("api/[controller]")]
public class PriceOfferController : ControllerBase
{
    private readonly IUnitOfWork _unitOfWork;

    public PriceOfferController(IUnitOfWork unitOfWork)
    {
        _unitOfWork = unitOfWork;
    }

    [Authorize]
    [HttpPost]
    public async Task<ActionResult<ApiResponse<PriceOfferDto>>> CreatePriceOffer([FromBody] CreatePriceOfferDto dto)
    {
        try
        {
            var userId = int.Parse(User.FindFirst(ClaimTypes.NameIdentifier)?.Value ?? "0");
            
            // Verify pet exists and is for sale
            var pet = await _unitOfWork.Pets.GetByIdAsync(dto.PetId);
            
            if (pet == null)
                return BadRequest(ApiResponse<PriceOfferDto>.ErrorResponse("Pet not found"));
            
            if (!pet.IsForSale)
                return BadRequest(ApiResponse<PriceOfferDto>.ErrorResponse("Pet is not for sale"));
            
            if (pet.OwnerId == userId)
                return BadRequest(ApiResponse<PriceOfferDto>.ErrorResponse("Cannot make offer for your own pet"));
            
            if (pet.IsAdopted)
                return BadRequest(ApiResponse<PriceOfferDto>.ErrorResponse("Pet is already adopted"));

            // Check if user already has an active offer for this pet
            if (await _unitOfWork.PriceOffers.HasActiveOfferAsync(dto.PetId, userId))
                return BadRequest(ApiResponse<PriceOfferDto>.ErrorResponse("You already have an active offer for this pet"));

            var priceOffer = new PriceOffer
            {
                PetId = dto.PetId,
                OffererId = userId,
                ReceiverId = pet.OwnerId,
                OfferedAmount = dto.OfferedAmount,
                Message = dto.Message,
                Status = "Pending",
                CreatedAt = DateTime.UtcNow
            };

            await _unitOfWork.PriceOffers.AddAsync(priceOffer);

            // Add to history
            var history = new PriceOfferHistory
            {
                PriceOfferId = priceOffer.Id,
                UserId = userId,
                Action = "Created",
                Amount = dto.OfferedAmount,
                Message = dto.Message,
                CreatedAt = DateTime.UtcNow
            };

            await _unitOfWork.SaveChangesAsync();

            // Send notification to pet owner
            await _sendPriceOfferNotification(priceOffer);

            var response = await _mapToPriceOfferDto(priceOffer);
            return Ok(ApiResponse<PriceOfferDto>.SuccessResponse(response));
        }
        catch (Exception ex)
        {
            return StatusCode(500, ApiResponse<PriceOfferDto>.ErrorResponse($"Internal server error: {ex.Message}"));
        }
    }

    [Authorize]
    [HttpGet("pet/{petId:int}")]
    public async Task<ActionResult<ApiResponse<IEnumerable<PriceOfferDto>>>> GetPriceOffersForPet(int petId)
    {
        try
        {
            var userId = int.Parse(User.FindFirst(ClaimTypes.NameIdentifier)?.Value ?? "0");
            
            // Verify pet exists
            var pet = await _unitOfWork.Pets.GetByIdAsync(petId);
            if (pet == null)
                return NotFound(ApiResponse<IEnumerable<PriceOfferDto>>.ErrorResponse("Pet not found"));
            
            // Only pet owner can see all offers
            if (pet.OwnerId != userId)
                return Forbid("Only pet owner can view price offers");

            var offers = await _unitOfWork.PriceOffers.GetActiveOffersForPetAsync(petId);
            var response = offers.Select(offer => _mapToPriceOfferDto(offer).Result).ToList();

            return Ok(ApiResponse<IEnumerable<PriceOfferDto>>.SuccessResponse(response));
        }
        catch (Exception ex)
        {
            return StatusCode(500, ApiResponse<IEnumerable<PriceOfferDto>>.ErrorResponse($"Internal server error: {ex.Message}"));
        }
    }

    [Authorize]
    [HttpGet("my-offers")]
    public async Task<ActionResult<ApiResponse<IEnumerable<PriceOfferDto>>>> GetMyOffers()
    {
        try
        {
            var userId = int.Parse(User.FindFirst(ClaimTypes.NameIdentifier)?.Value ?? "0");
            
            var offers = await _unitOfWork.PriceOffers.GetByOffererIdAsync(userId);
            var response = offers.Select(offer => _mapToPriceOfferDto(offer).Result).ToList();

            return Ok(ApiResponse<IEnumerable<PriceOfferDto>>.SuccessResponse(response));
        }
        catch (Exception ex)
        {
            return StatusCode(500, ApiResponse<IEnumerable<PriceOfferDto>>.ErrorResponse($"Internal server error: {ex.Message}"));
        }
    }

    [Authorize]
    [HttpGet("my-offer/pet/{petId:int}")]
    public async Task<ActionResult<ApiResponse<PriceOfferDto>>> GetMyOfferForPet(int petId)
    {
        try
        {
            var userId = int.Parse(User.FindFirst(ClaimTypes.NameIdentifier)?.Value ?? "0");
            
            var offers = await _unitOfWork.PriceOffers.GetByPetIdAsync(petId);
            var myOffer = offers.FirstOrDefault(offer => offer.OffererId == userId);
            
            if (myOffer == null)
                return NotFound(ApiResponse<PriceOfferDto>.ErrorResponse("No price offer found for this pet"));
            
            var response = await _mapToPriceOfferDto(myOffer);
            return Ok(ApiResponse<PriceOfferDto>.SuccessResponse(response));
        }
        catch (Exception ex)
        {
            return StatusCode(500, ApiResponse<PriceOfferDto>.ErrorResponse($"Internal server error: {ex.Message}"));
        }
    }

    [Authorize]
    [HttpGet("received-offers")]
    public async Task<ActionResult<ApiResponse<IEnumerable<PriceOfferDto>>>> GetReceivedOffers()
    {
        try
        {
            var userId = int.Parse(User.FindFirst(ClaimTypes.NameIdentifier)?.Value ?? "0");
            
            var offers = await _unitOfWork.PriceOffers.GetByReceiverIdAsync(userId);
            var response = offers.Select(offer => _mapToPriceOfferDto(offer).Result).ToList();

            return Ok(ApiResponse<IEnumerable<PriceOfferDto>>.SuccessResponse(response));
        }
        catch (Exception ex)
        {
            return StatusCode(500, ApiResponse<IEnumerable<PriceOfferDto>>.ErrorResponse($"Internal server error: {ex.Message}"));
        }
    }

    [Authorize]
    [HttpPost("{id:int}/counter-offer")]
    public async Task<ActionResult<ApiResponse<PriceOfferDto>>> MakeCounterOffer(int id, [FromBody] CounterOfferDto dto)
    {
        try
        {
            var userId = int.Parse(User.FindFirst(ClaimTypes.NameIdentifier)?.Value ?? "0");
            
            var priceOffer = await _unitOfWork.PriceOffers.GetWithDetailsAsync(id);
            if (priceOffer == null)
                return NotFound(ApiResponse<PriceOfferDto>.ErrorResponse("Price offer not found"));
            
            // Only pet owner can make counter offer
            if (priceOffer.ReceiverId != userId)
                return Forbid("Only pet owner can make counter offer");
            
            if (priceOffer.Status != "Pending")
                return BadRequest(ApiResponse<PriceOfferDto>.ErrorResponse("Cannot make counter offer for this status"));

            priceOffer.CounterOfferAmount = dto.CounterOfferAmount;
            priceOffer.CounterOfferMessage = dto.CounterOfferMessage;
            priceOffer.CounterOfferStatus = "Pending";
            priceOffer.CounterOfferAt = DateTime.UtcNow;
            priceOffer.Status = "CounterOffered";
            priceOffer.UpdatedAt = DateTime.UtcNow;

            await _unitOfWork.PriceOffers.UpdateAsync(priceOffer);

            // Add to history
            var history = new PriceOfferHistory
            {
                PriceOfferId = priceOffer.Id,
                UserId = userId,
                Action = "CounterOffered",
                Amount = dto.CounterOfferAmount,
                Message = dto.CounterOfferMessage,
                CreatedAt = DateTime.UtcNow
            };

            await _unitOfWork.SaveChangesAsync();

            // Send notification to offerer
            await _sendCounterOfferNotification(priceOffer);

            var response = await _mapToPriceOfferDto(priceOffer);
            return Ok(ApiResponse<PriceOfferDto>.SuccessResponse(response));
        }
        catch (Exception ex)
        {
            return StatusCode(500, ApiResponse<PriceOfferDto>.ErrorResponse($"Internal server error: {ex.Message}"));
        }
    }

    [Authorize]
    [HttpPut("{id:int}/status")]
    public async Task<ActionResult<ApiResponse<PriceOfferDto>>> UpdateOfferStatus(int id, [FromBody] UpdatePriceOfferStatusDto dto)
    {
        try
        {
            var userId = int.Parse(User.FindFirst(ClaimTypes.NameIdentifier)?.Value ?? "0");
            
            var priceOffer = await _unitOfWork.PriceOffers.GetWithDetailsAsync(id);
            if (priceOffer == null)
                return NotFound(ApiResponse<PriceOfferDto>.ErrorResponse("Price offer not found"));
            
            // Only pet owner can accept/reject offers
            if (priceOffer.ReceiverId != userId)
                return Forbid("Only pet owner can update offer status");
            
            if (priceOffer.Status != "Pending" && priceOffer.Status != "CounterOffered")
                return BadRequest(ApiResponse<PriceOfferDto>.ErrorResponse("Cannot update status for this offer"));

            priceOffer.Status = dto.Status;
            priceOffer.UpdatedAt = DateTime.UtcNow;

            await _unitOfWork.PriceOffers.UpdateAsync(priceOffer);

            // Add to history
            var history = new PriceOfferHistory
            {
                PriceOfferId = priceOffer.Id,
                UserId = userId,
                Action = dto.Status,
                CreatedAt = DateTime.UtcNow
            };

            // If accepting the offer, create a sale request with the offer amount
            if (dto.Status == "Accepted")
            {
                // Check if there's already a sale request for this pet and offerer
                var existingRequests = await _unitOfWork.SaleRequests.GetByPetIdAsync(priceOffer.PetId);
                var existingRequest = existingRequests.FirstOrDefault(sr => 
                    sr.BuyerId == priceOffer.OffererId && sr.Status == "Pending");

                if (existingRequest == null)
                {
                    // Create new sale request with the offer amount
                    var saleRequest = new SaleRequest
                    {
                        PetId = priceOffer.PetId,
                        BuyerId = priceOffer.OffererId,
                        SellerId = priceOffer.ReceiverId,
                        Amount = priceOffer.OfferedAmount, // Use offer amount, not pet price
                        Message = priceOffer.Message,
                        Status = "Confirmed", // Directly confirmed since owner accepted
                        CreatedAt = DateTime.UtcNow,
                        UpdatedAt = DateTime.UtcNow
                    };

                    await _unitOfWork.SaleRequests.AddAsync(saleRequest);
                }
                else
                {
                    // Update existing request with the offer amount
                    existingRequest.Amount = priceOffer.OfferedAmount; // Use offer amount
                    existingRequest.Status = "Confirmed"; // Directly confirmed
                    existingRequest.UpdatedAt = DateTime.UtcNow;
                    await _unitOfWork.SaleRequests.UpdateAsync(existingRequest);
                }
            }

            await _unitOfWork.SaveChangesAsync();

            // Send notification to offerer
            await _sendStatusUpdateNotification(priceOffer, dto.Status);

            var response = await _mapToPriceOfferDto(priceOffer);
            return Ok(ApiResponse<PriceOfferDto>.SuccessResponse(response));
        }
        catch (Exception ex)
        {
            return StatusCode(500, ApiResponse<PriceOfferDto>.ErrorResponse($"Internal server error: {ex.Message}"));
        }
    }

    private Task<PriceOfferDto> _mapToPriceOfferDto(PriceOffer offer)
    {
        return Task.FromResult(new PriceOfferDto
        {
            Id = offer.Id,
            PetId = offer.PetId,
            PetName = offer.Pet?.Name ?? "",
            PetImageUrl = offer.Pet?.ImageUrl ?? "",
            OffererId = offer.OffererId,
            OffererName = offer.Offerer?.FullName ?? "",
            ReceiverId = offer.ReceiverId,
            ReceiverName = offer.Receiver?.FullName ?? "",
            OfferedAmount = offer.OfferedAmount,
            Message = offer.Message,
            Status = offer.Status,
            CounterOfferAmount = offer.CounterOfferAmount,
            CounterOfferMessage = offer.CounterOfferMessage,
            CounterOfferStatus = offer.CounterOfferStatus,
            CreatedAt = offer.CreatedAt,
            UpdatedAt = offer.UpdatedAt,
            CounterOfferAt = offer.CounterOfferAt,
            History = offer.History.Select(h => new PriceOfferHistoryDto
            {
                Id = h.Id,
                UserId = h.UserId,
                UserName = h.User?.FullName ?? "",
                Action = h.Action,
                Amount = h.Amount,
                Message = h.Message,
                CreatedAt = h.CreatedAt
            }).ToList()
        });
    }

    private async Task _sendPriceOfferNotification(PriceOffer offer)
    {
        var notification = new Notification
        {
            UserId = offer.ReceiverId,
            Title = "Có đề xuất giá mới",
            Body = $"{offer.Offerer?.FullName} đã đề xuất giá {offer.OfferedAmount:N0} VNĐ cho {offer.Pet?.Name}",
            IsRead = false,
            CreatedAt = DateTime.UtcNow
        };

        await _unitOfWork.Notifications.AddAsync(notification);
        await _unitOfWork.SaveChangesAsync();
    }

    private async Task _sendCounterOfferNotification(PriceOffer offer)
    {
        var notification = new Notification
        {
            UserId = offer.OffererId,
            Title = "Có đề xuất giá ngược lại",
            Body = $"Chủ {offer.Pet?.Name} đã đề xuất giá ngược lại {offer.CounterOfferAmount:N0} VNĐ",
            IsRead = false,
            CreatedAt = DateTime.UtcNow
        };

        await _unitOfWork.Notifications.AddAsync(notification);
        await _unitOfWork.SaveChangesAsync();
    }

    private async Task _sendStatusUpdateNotification(PriceOffer offer, string status)
    {
        var statusText = status == "Accepted" ? "chấp nhận" : "từ chối";
        var notification = new Notification
        {
            UserId = offer.OffererId,
            Title = $"Đề xuất giá đã được {statusText}",
            Body = $"Chủ {offer.Pet?.Name} đã {statusText} đề xuất giá của bạn",
            IsRead = false,
            CreatedAt = DateTime.UtcNow
        };

        await _unitOfWork.Notifications.AddAsync(notification);
        await _unitOfWork.SaveChangesAsync();
    }
}

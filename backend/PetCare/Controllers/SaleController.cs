using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using PetCare.DTOs;
using PetCare.Entities;
using PetCare.Repositories;
using System.Security.Claims;

namespace PetCare.Controllers;

[ApiController]
[Route("api/[controller]")]
public class SaleController : ControllerBase
{
    private readonly IUnitOfWork _unitOfWork;

    public SaleController(IUnitOfWork unitOfWork)
    {
        _unitOfWork = unitOfWork;
    }

    [Authorize]
    [HttpPost("request")]
    public async Task<ActionResult<ApiResponse<SaleRequestDto>>> CreateSaleRequest([FromBody] CreateSaleRequestDto dto)
    {
        try
        {
            var userId = int.Parse(User.FindFirst(ClaimTypes.NameIdentifier)?.Value ?? "0");
            
            // Verify pet exists and is for sale
            var pet = await _unitOfWork.Pets.GetByIdAsync(dto.PetId);
            
            if (pet == null)
                return BadRequest(ApiResponse<SaleRequestDto>.ErrorResponse("Pet not found"));
            
            if (!pet.IsForSale)
                return BadRequest(ApiResponse<SaleRequestDto>.ErrorResponse("Pet is not for sale"));
            
            if (pet.OwnerId == userId)
                return BadRequest(ApiResponse<SaleRequestDto>.ErrorResponse("Cannot buy your own pet"));
            
            // Check if pet is adopted and if current user is the buyer
            if (pet.IsAdopted)
            {
                // Check if current user has a completed sale request for this pet
                var completedRequests = await _unitOfWork.SaleRequests.GetByPetIdAsync(dto.PetId);
                var userCompletedRequest = completedRequests.FirstOrDefault(sr => 
                    sr.BuyerId == userId && sr.Status == "Completed");
                
                if (userCompletedRequest == null)
                {
                    // Pet is adopted but not by current user
                    return BadRequest(ApiResponse<SaleRequestDto>.ErrorResponse("Pet is already adopted"));
                }
                
                // Current user is the buyer - allow creating new sale request (buy again)
                // Reset the pet's adoption status to allow new sale
                pet.IsAdopted = false;
                pet.IsPublic = true;
                await _unitOfWork.Pets.UpdateAsync(pet);
            }

            // Check if user already has a pending request for this pet
            var existingRequests = await _unitOfWork.SaleRequests.GetByPetIdAsync(dto.PetId);
            var existingRequest = existingRequests.FirstOrDefault(sr => sr.BuyerId == userId && sr.Status == "Pending");
            
            if (existingRequest != null)
                return BadRequest(ApiResponse<SaleRequestDto>.ErrorResponse("You already have a pending request for this pet"));

            // Determine status based on price comparison
            // Always set to Pending for seller confirmation
            string status = "Pending";

            var saleRequest = new SaleRequest
            {
                PetId = dto.PetId,
                SellerId = pet.OwnerId,
                BuyerId = userId,
                Amount = dto.Amount,
                Message = dto.Message,
                PaymentMethod = dto.PaymentMethod,
                Status = status
            };

            await _unitOfWork.SaleRequests.AddAsync(saleRequest);
            await _unitOfWork.SaveChangesAsync();

            // Send notifications
            await _sendSaleRequestNotifications(saleRequest, pet);

            // Load related data for response
            var saleRequestWithDetails = await _unitOfWork.SaleRequests.GetWithDetailsAsync(saleRequest.Id);
            if (saleRequestWithDetails == null)
                return StatusCode(500, ApiResponse<SaleRequestDto>.ErrorResponse("Failed to load sale request details"));

            var response = new SaleRequestDto
            {
                Id = saleRequestWithDetails.Id,
                PetId = saleRequestWithDetails.PetId,
                PetName = saleRequestWithDetails.Pet?.Name ?? "",
                PetImageUrl = saleRequestWithDetails.Pet?.ImageUrl ?? "",
                SellerId = saleRequestWithDetails.SellerId,
                SellerName = saleRequestWithDetails.Seller?.FullName ?? "",
                BuyerId = saleRequestWithDetails.BuyerId,
                BuyerName = saleRequestWithDetails.Buyer?.FullName ?? "",
                Amount = saleRequestWithDetails.Amount,
                Message = saleRequestWithDetails.Message,
                PaymentMethod = saleRequestWithDetails.PaymentMethod,
                Status = saleRequestWithDetails.Status,
                CreatedAt = saleRequestWithDetails.CreatedAt,
                UpdatedAt = saleRequestWithDetails.UpdatedAt
            };

            return Ok(ApiResponse<SaleRequestDto>.SuccessResponse(response));
        }
        catch (Exception ex)
        {
            return StatusCode(500, ApiResponse<SaleRequestDto>.ErrorResponse($"Internal server error: {ex.Message}"));
        }
    }

    [Authorize]
    [HttpGet("my")]
    public async Task<ActionResult<ApiResponse<IEnumerable<SaleRequestDto>>>> GetMySaleRequests()
    {
        try
        {
            var userId = int.Parse(User.FindFirst(ClaimTypes.NameIdentifier)?.Value ?? "0");
            
            var buyerRequests = await _unitOfWork.SaleRequests.GetByBuyerIdAsync(userId);
            var sellerRequests = await _unitOfWork.SaleRequests.GetBySellerIdAsync(userId);
            
            var allRequests = buyerRequests.Concat(sellerRequests)
                .OrderByDescending(sr => sr.CreatedAt)
                .ToList();

            var response = allRequests.Select(sr => new SaleRequestDto
            {
                Id = sr.Id,
                PetId = sr.PetId,
                PetName = sr.Pet?.Name ?? "",
                PetImageUrl = sr.Pet?.ImageUrl ?? "",
                SellerId = sr.SellerId,
                SellerName = sr.Seller?.FullName ?? "",
                BuyerId = sr.BuyerId,
                BuyerName = sr.Buyer?.FullName ?? "",
                Amount = sr.Amount,
                Message = sr.Message,
                PaymentMethod = sr.PaymentMethod,
                Status = sr.Status,
                CreatedAt = sr.CreatedAt,
                UpdatedAt = sr.UpdatedAt
            });

            return Ok(ApiResponse<IEnumerable<SaleRequestDto>>.SuccessResponse(response));
        }
        catch (Exception ex)
        {
            return StatusCode(500, ApiResponse<IEnumerable<SaleRequestDto>>.ErrorResponse($"Internal server error: {ex.Message}"));
        }
    }

    [Authorize]
    [HttpGet("pet/{petId:int}")]
    public async Task<ActionResult<ApiResponse<SaleRequestDto>>> GetSaleRequestForPet(int petId)
    {
        try
        {
            var userId = int.Parse(User.FindFirst(ClaimTypes.NameIdentifier)?.Value ?? "0");
            
            var requests = await _unitOfWork.SaleRequests.GetByPetIdAsync(petId);
            var userRequest = requests.FirstOrDefault(sr => sr.BuyerId == userId);
            
            if (userRequest == null)
                return NotFound(ApiResponse<SaleRequestDto>.ErrorResponse("No sale request found for this pet"));
            
            var response = new SaleRequestDto
            {
                Id = userRequest.Id,
                PetId = userRequest.PetId,
                PetName = userRequest.Pet?.Name ?? "",
                PetImageUrl = userRequest.Pet?.ImageUrl ?? "",
                SellerId = userRequest.SellerId,
                SellerName = userRequest.Seller?.FullName ?? "",
                BuyerId = userRequest.BuyerId,
                BuyerName = userRequest.Buyer?.FullName ?? "",
                Amount = userRequest.Amount,
                Message = userRequest.Message,
                PaymentMethod = userRequest.PaymentMethod,
                Status = userRequest.Status,
                CreatedAt = userRequest.CreatedAt,
                UpdatedAt = userRequest.UpdatedAt
            };
            
            return Ok(ApiResponse<SaleRequestDto>.SuccessResponse(response));
        }
        catch (Exception ex)
        {
            return StatusCode(500, ApiResponse<SaleRequestDto>.ErrorResponse($"Internal server error: {ex.Message}"));
        }
    }

    [Authorize]
    [HttpGet("received-requests")]
    public async Task<ActionResult<ApiResponse<IEnumerable<SaleRequestDto>>>> GetReceivedSaleRequests()
    {
        try
        {
            var userId = int.Parse(User.FindFirst(ClaimTypes.NameIdentifier)?.Value ?? "0");
            
            var requests = await _unitOfWork.SaleRequests.GetBySellerIdAsync(userId);
            var response = requests.Select(sr => new SaleRequestDto
            {
                Id = sr.Id,
                PetId = sr.PetId,
                PetName = sr.Pet?.Name ?? "",
                PetImageUrl = sr.Pet?.ImageUrl ?? "",
                SellerId = sr.SellerId,
                SellerName = sr.Seller?.FullName ?? "",
                BuyerId = sr.BuyerId,
                BuyerName = sr.Buyer?.FullName ?? "",
                Amount = sr.Amount,
                Message = sr.Message,
                PaymentMethod = sr.PaymentMethod,
                Status = sr.Status,
                CreatedAt = sr.CreatedAt,
                UpdatedAt = sr.UpdatedAt
            });

            return Ok(ApiResponse<IEnumerable<SaleRequestDto>>.SuccessResponse(response));
        }
        catch (Exception ex)
        {
            return StatusCode(500, ApiResponse<IEnumerable<SaleRequestDto>>.ErrorResponse($"Internal server error: {ex.Message}"));
        }
    }

    [Authorize]
    [HttpPut("{id:int}/status")]
    public async Task<ActionResult<ApiResponse<SaleRequestDto>>> UpdateSaleStatus(int id, [FromBody] UpdateSaleStatusDto dto)
    {
        try
        {
            var userId = int.Parse(User.FindFirst(ClaimTypes.NameIdentifier)?.Value ?? "0");
            
            var saleRequest = await _unitOfWork.SaleRequests.GetWithDetailsAsync(id);
            
            if (saleRequest == null)
                return NotFound(ApiResponse<SaleRequestDto>.ErrorResponse("Sale request not found"));
            
            // Only seller can update status
            if (saleRequest.SellerId != userId)
                return Forbid("Only the seller can update sale status");
            
            saleRequest.Status = dto.Status;
            saleRequest.UpdatedAt = DateTime.UtcNow;
            
            // Handle different status updates
            if (dto.Status == "Confirmed")
            {
                // When confirmed, it's ready for payment
                saleRequest.Status = "Confirmed";
            }
            else if (dto.Status == "Rejected")
            {
                // If rejected, refund if payment was made
                if (saleRequest.Status == "Confirmed")
                {
                    // TODO: Implement refund logic
                    saleRequest.Status = "Rejected";
                }
            }
            else if (dto.Status == "Completed")
            {
                // Mark pet as adopted when sale is completed
                saleRequest.Pet!.IsAdopted = true;
                await _unitOfWork.Pets.UpdateAsync(saleRequest.Pet);
            }
            
            await _unitOfWork.SaleRequests.UpdateAsync(saleRequest);
            await _unitOfWork.SaveChangesAsync();

            // Send status update notifications
            await _sendSaleStatusUpdateNotifications(saleRequest);

            var response = new SaleRequestDto
            {
                Id = saleRequest.Id,
                PetId = saleRequest.PetId,
                PetName = saleRequest.Pet?.Name ?? "",
                PetImageUrl = saleRequest.Pet?.ImageUrl ?? "",
                SellerId = saleRequest.SellerId,
                SellerName = saleRequest.Seller?.FullName ?? "",
                BuyerId = saleRequest.BuyerId,
                BuyerName = saleRequest.Buyer?.FullName ?? "",
                Amount = saleRequest.Amount,
                Message = saleRequest.Message,
                PaymentMethod = saleRequest.PaymentMethod,
                Status = saleRequest.Status,
                CreatedAt = saleRequest.CreatedAt,
                UpdatedAt = saleRequest.UpdatedAt
            };

            return Ok(ApiResponse<SaleRequestDto>.SuccessResponse(response));
        }
        catch (Exception ex)
        {
            return StatusCode(500, ApiResponse<SaleRequestDto>.ErrorResponse($"Internal server error: {ex.Message}"));
        }
    }

    [Authorize]
    [HttpPost("payment")]
    public async Task<ActionResult<ApiResponse<PaymentDto>>> CreatePayment([FromBody] PaymentRequestDto dto)
    {
        try
        {
            var userId = int.Parse(User.FindFirst(ClaimTypes.NameIdentifier)?.Value ?? "0");
            
            var saleRequest = await _unitOfWork.SaleRequests.GetWithDetailsAsync(dto.SaleRequestId);
            
            if (saleRequest == null)
                return NotFound(ApiResponse<PaymentDto>.ErrorResponse("Sale request not found"));
            
            // Only buyer can make payment
            if (saleRequest.BuyerId != userId)
                return Forbid("Only the buyer can make payment");
            
            if (saleRequest.Status != "Confirmed" && saleRequest.Status != "Pending")
                return BadRequest(ApiResponse<PaymentDto>.ErrorResponse("Sale request must be pending, confirmed, payment ready, or payment pending before payment"));

            var payment = new PaymentTransaction
            {
                UserId = userId,
                TransactionType = "PetSale",
                PaymentMethod = dto.PaymentMethod,
                Amount = saleRequest.Amount,
                Status = "Pending",
                Description = $"Payment for {saleRequest.Pet?.Name}",
                ReferenceId = dto.TransactionId,
                Notes = dto.Notes,
                SaleRequestId = saleRequest.Id,
                PetId = saleRequest.PetId
            };

            await _unitOfWork.PaymentTransactions.AddAsync(payment);
            await _unitOfWork.SaveChangesAsync();

            var response = new PaymentDto
            {
                Id = payment.Id,
                SaleRequestId = payment.SaleRequestId ?? 0,
                PaymentMethod = payment.PaymentMethod,
                TransactionId = payment.ReferenceId,
                Status = payment.Status,
                Notes = payment.Notes,
                CreatedAt = payment.CreatedAt,
                UpdatedAt = payment.CompletedAt
            };

            return Ok(ApiResponse<PaymentDto>.SuccessResponse(response));
        }
        catch (Exception ex)
        {
            return StatusCode(500, ApiResponse<PaymentDto>.ErrorResponse($"Internal server error: {ex.Message}"));
        }
    }

    private async Task _sendSaleRequestNotifications(SaleRequest saleRequest, Pet pet)
    {
        try
        {
            // Notification for seller
            var sellerNotification = new Notification
            {
                UserId = saleRequest.SellerId,
                Title = "Yêu cầu mua thú cưng",
                Body = $"Có người muốn mua {pet.Name} với giá {saleRequest.Amount:N0} VNĐ",
                IsRead = false,
                CreatedAt = DateTime.UtcNow
            };

            // Notification for buyer
            var buyerNotification = new Notification
            {
                UserId = saleRequest.BuyerId,
                Title = "Yêu cầu mua đã được gửi",
                Body = $"Yêu cầu mua {pet.Name} đang chờ chủ xác nhận",
                IsRead = false,
                CreatedAt = DateTime.UtcNow
            };

            await _unitOfWork.Notifications.AddAsync(sellerNotification);
            await _unitOfWork.Notifications.AddAsync(buyerNotification);
            await _unitOfWork.SaveChangesAsync();
        }
        catch (Exception ex)
        {
            // Log error but don't fail the main operation
            Console.WriteLine($"Failed to send notifications: {ex.Message}");
        }
    }

    private async Task _sendSaleStatusUpdateNotifications(SaleRequest saleRequest)
    {
        try
        {
            var pet = saleRequest.Pet;
            if (pet == null) return;

            // Notification for buyer
            var buyerNotification = new Notification
            {
                UserId = saleRequest.BuyerId,
                Title = "Cập nhật yêu cầu mua",
                Body = saleRequest.Status switch
                {
                    "Confirmed" => $"Chủ thú cưng đã xác nhận yêu cầu mua {pet.Name}. Bạn có thể thanh toán.",
                    "Rejected" => $"Yêu cầu mua {pet.Name} đã bị từ chối.",
                    "Completed" => $"Giao dịch mua {pet.Name} đã hoàn thành.",
                    _ => $"Trạng thái yêu cầu mua {pet.Name} đã được cập nhật."
                },
                IsRead = false,
                CreatedAt = DateTime.UtcNow
            };

            // Notification for seller
            var sellerNotification = new Notification
            {
                UserId = saleRequest.SellerId,
                Title = "Cập nhật yêu cầu bán",
                Body = saleRequest.Status switch
                {
                    "Confirmed" => $"Yêu cầu bán {pet.Name} đã được xác nhận. Chờ thanh toán.",
                    "Rejected" => $"Bạn đã từ chối yêu cầu mua {pet.Name}.",
                    "Completed" => $"Giao dịch bán {pet.Name} đã hoàn thành.",
                    _ => $"Trạng thái yêu cầu bán {pet.Name} đã được cập nhật."
                },
                IsRead = false,
                CreatedAt = DateTime.UtcNow
            };

            await _unitOfWork.Notifications.AddAsync(buyerNotification);
            await _unitOfWork.Notifications.AddAsync(sellerNotification);
            await _unitOfWork.SaveChangesAsync();
        }
        catch (Exception ex)
        {
            Console.WriteLine($"Failed to send status update notifications: {ex.Message}");
        }
    }
}
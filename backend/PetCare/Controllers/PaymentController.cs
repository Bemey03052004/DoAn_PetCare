using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using PetCare.DTOs;
using PetCare.Entities;
using PetCare.Repositories;

namespace PetCare.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize]
public class PaymentController : ControllerBase
{
    private readonly IUnitOfWork _unitOfWork;

    public PaymentController(IUnitOfWork unitOfWork)
    {
        _unitOfWork = unitOfWork;
    }

    [HttpPost("create")]
    public async Task<ActionResult<ApiResponse<PaymentResponseDto>>> CreatePayment([FromBody] CreatePaymentRequestDto request)
    {
        try
        {
            var userId = int.Parse(User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)!.Value);

            // Validate related entities
            if (request.PetId.HasValue)
            {
                var petToValidate = await _unitOfWork.Pets.GetByIdAsync(request.PetId.Value);
                if (petToValidate == null)
                {
                    return BadRequest(ApiResponse<PaymentResponseDto>.ErrorResponse("Pet not found"));
                }
            }

            if (request.BoardingRequestId.HasValue)
            {
                var boardingRequest = await _unitOfWork.BoardingRequests.GetByIdAsync(request.BoardingRequestId.Value);
                if (boardingRequest == null)
                {
                    return BadRequest(ApiResponse<PaymentResponseDto>.ErrorResponse("Boarding request not found"));
                }
            }

            if (request.AdoptionRequestId.HasValue)
            {
                var adoptionRequest = await _unitOfWork.AdoptionRequests.GetByIdAsync(request.AdoptionRequestId.Value);
                if (adoptionRequest == null)
                {
                    return BadRequest(ApiResponse<PaymentResponseDto>.ErrorResponse("Adoption request not found"));
                }
            }

            // Create payment transaction
            var payment = new PaymentTransaction
            {
                UserId = userId,
                TransactionType = request.TransactionType,
                PaymentMethod = request.PaymentMethod,
                Amount = request.Amount,
                DepositAmount = request.DepositAmount,
                Status = "Pending",
                Description = request.Description,
                PetId = request.PetId,
                BoardingRequestId = request.BoardingRequestId,
                AdoptionRequestId = request.AdoptionRequestId,
                Notes = request.Notes,
                ExpiresAt = DateTime.UtcNow.AddHours(24) // 24 hours expiry
            };

            await _unitOfWork.PaymentTransactions.AddAsync(payment);
            await _unitOfWork.SaveChangesAsync();

            // Get user details
            var user = await _unitOfWork.Users.GetByIdAsync(userId);
            var pet = request.PetId.HasValue ? await _unitOfWork.Pets.GetByIdAsync(request.PetId.Value) : null;

            var response = new PaymentResponseDto
            {
                Id = payment.Id,
                UserId = userId,
                UserName = user?.FullName ?? "",
                TransactionType = payment.TransactionType,
                PaymentMethod = payment.PaymentMethod,
                Amount = payment.Amount,
                DepositAmount = payment.DepositAmount,
                Status = payment.Status,
                Description = payment.Description,
                ReferenceId = payment.ReferenceId,
                PetId = payment.PetId,
                PetName = pet?.Name,
                BoardingRequestId = payment.BoardingRequestId,
                AdoptionRequestId = payment.AdoptionRequestId,
                Notes = payment.Notes,
                CreatedAt = payment.CreatedAt,
                CompletedAt = payment.CompletedAt,
                ExpiresAt = payment.ExpiresAt
            };

            return Ok(ApiResponse<PaymentResponseDto>.SuccessResponse(response, "Payment created successfully"));
        }
        catch (Exception ex)
        {
            return StatusCode(500, ApiResponse<PaymentResponseDto>.ErrorResponse($"An error occurred: {ex.Message}"));
        }
    }

    [HttpGet("my-payments")]
    public async Task<ActionResult<ApiResponse<IEnumerable<PaymentResponseDto>>>> GetMyPayments()
    {
        try
        {
            var userId = int.Parse(User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)!.Value);

            var payments = await _unitOfWork.PaymentTransactions.FindAsync(p => p.UserId == userId);
            var response = new List<PaymentResponseDto>();

            foreach (var payment in payments)
            {
                var user = await _unitOfWork.Users.GetByIdAsync(payment.UserId);
                var pet = payment.PetId.HasValue ? await _unitOfWork.Pets.GetByIdAsync(payment.PetId.Value) : null;

                response.Add(new PaymentResponseDto
                {
                    Id = payment.Id,
                    UserId = payment.UserId,
                    UserName = user?.FullName ?? "",
                    TransactionType = payment.TransactionType,
                    PaymentMethod = payment.PaymentMethod,
                    Amount = payment.Amount,
                    DepositAmount = payment.DepositAmount,
                    Status = payment.Status,
                    Description = payment.Description,
                    ReferenceId = payment.ReferenceId,
                    PetId = payment.PetId,
                    PetName = pet?.Name,
                    BoardingRequestId = payment.BoardingRequestId,
                    AdoptionRequestId = payment.AdoptionRequestId,
                    Notes = payment.Notes,
                    CreatedAt = payment.CreatedAt,
                    CompletedAt = payment.CompletedAt,
                    ExpiresAt = payment.ExpiresAt
                });
            }

            return Ok(ApiResponse<IEnumerable<PaymentResponseDto>>.SuccessResponse(response));
        }
        catch (Exception ex)
        {
            return StatusCode(500, ApiResponse<IEnumerable<PaymentResponseDto>>.ErrorResponse($"An error occurred: {ex.Message}"));
        }
    }

    [HttpPut("{id:int}/status")]
    public async Task<ActionResult<ApiResponse<PaymentResponseDto>>> UpdatePaymentStatus(int id, [FromBody] UpdatePaymentStatusDto request)
    {
        try
        {
            var userId = int.Parse(User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)!.Value);

            var payment = await _unitOfWork.PaymentTransactions.GetByIdAsync(id);
            if (payment == null)
            {
                return NotFound(ApiResponse<PaymentResponseDto>.ErrorResponse("Payment not found"));
            }

            // Check if user is the payment owner or admin
            var isAdmin = User.IsInRole("Admin");
            if (payment.UserId != userId && !isAdmin)
            {
                return Forbid("You can only update your own payments");
            }

            // Update payment status
            payment.Status = request.Status;
            payment.ReferenceId = request.ReferenceId;
            payment.Notes = request.Notes;

            if (request.Status == "Completed")
            {
                payment.CompletedAt = DateTime.UtcNow;
                
                // Update related sale request status if this is a pet sale payment
                if (payment.TransactionType == "PetSale" && payment.SaleRequestId.HasValue)
                {
                    var saleRequest = await _unitOfWork.SaleRequests.GetByIdAsync(payment.SaleRequestId.Value);
                    if (saleRequest != null)
                    {
                        saleRequest.Status = "Completed";
                        saleRequest.UpdatedAt = DateTime.UtcNow;
                        await _unitOfWork.SaleRequests.UpdateAsync(saleRequest);
                        
                        // Mark pet as adopted
                        var petToUpdate = await _unitOfWork.Pets.GetByIdAsync(saleRequest.PetId);
                        if (petToUpdate != null)
                        {
                            petToUpdate.IsAdopted = true;
                            await _unitOfWork.Pets.UpdateAsync(petToUpdate);
                        }
                        
                        // Delete all price offers for this pet since it's now sold
                        var priceOffers = await _unitOfWork.PriceOffers.GetByPetIdAsync(saleRequest.PetId);
                        foreach (var offer in priceOffers)
                        {
                            await _unitOfWork.PriceOffers.DeleteAsync(offer);
                        }
                    }
                }
            }

            await _unitOfWork.PaymentTransactions.UpdateAsync(payment);
            await _unitOfWork.SaveChangesAsync();

            // Get updated details
            var user = await _unitOfWork.Users.GetByIdAsync(payment.UserId);
            var pet = payment.PetId.HasValue ? await _unitOfWork.Pets.GetByIdAsync(payment.PetId.Value) : null;

            var response = new PaymentResponseDto
            {
                Id = payment.Id,
                UserId = payment.UserId,
                UserName = user?.FullName ?? "",
                TransactionType = payment.TransactionType,
                PaymentMethod = payment.PaymentMethod,
                Amount = payment.Amount,
                DepositAmount = payment.DepositAmount,
                Status = payment.Status,
                Description = payment.Description,
                ReferenceId = payment.ReferenceId,
                PetId = payment.PetId,
                PetName = pet?.Name,
                BoardingRequestId = payment.BoardingRequestId,
                AdoptionRequestId = payment.AdoptionRequestId,
                Notes = payment.Notes,
                CreatedAt = payment.CreatedAt,
                CompletedAt = payment.CompletedAt,
                ExpiresAt = payment.ExpiresAt
            };

            return Ok(ApiResponse<PaymentResponseDto>.SuccessResponse(response, "Payment status updated successfully"));
        }
        catch (Exception ex)
        {
            return StatusCode(500, ApiResponse<PaymentResponseDto>.ErrorResponse($"An error occurred: {ex.Message}"));
        }
    }

    [HttpGet("methods")]
    public ActionResult<ApiResponse<IEnumerable<string>>> GetPaymentMethods()
    {
        var methods = new List<string>
        {
            "Cash",
            "BankTransfer",
            "Momo",
            "ZaloPay",
            "VNPay"
        };

        return Ok(ApiResponse<IEnumerable<string>>.SuccessResponse(methods));
    }
}

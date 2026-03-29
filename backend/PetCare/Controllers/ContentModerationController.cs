using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using PetCare.DTOs;
using PetCare.Entities;
using PetCare.Repositories;

namespace PetCare.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize(Roles = "Staff,Admin")]
public class ContentModerationController : ControllerBase
{
    private readonly IUnitOfWork _unitOfWork;

    public ContentModerationController(IUnitOfWork unitOfWork)
    {
        _unitOfWork = unitOfWork;
    }

    [HttpPost("moderate")]
    public async Task<ActionResult<ApiResponse<ContentModerationResponseDto>>> CreateContentModeration([FromBody] CreateContentModerationDto request)
    {
        try
        {
            var moderatorId = int.Parse(User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)!.Value);

            // Check if content exists
            bool contentExists = false;
            switch (request.ContentType.ToLower())
            {
                case "pet":
                    var pet = await _unitOfWork.Pets.GetByIdAsync(request.ContentId);
                    contentExists = pet != null;
                    break;
                case "petboardingrequest":
                    var boardingRequest = await _unitOfWork.PetBoardingRequests.GetByIdAsync(request.ContentId);
                    contentExists = boardingRequest != null;
                    break;
                case "adoptionrequest":
                    var adoptionRequest = await _unitOfWork.AdoptionRequests.GetByIdAsync(request.ContentId);
                    contentExists = adoptionRequest != null;
                    break;
            }

            if (!contentExists)
            {
                return BadRequest(ApiResponse<ContentModerationResponseDto>.ErrorResponse("Content not found"));
            }

            // Create content moderation record
            var moderation = new ContentModeration
            {
                ContentType = request.ContentType,
                ContentId = request.ContentId,
                ModeratorId = moderatorId,
                Status = request.Status,
                RejectionReason = request.RejectionReason,
                ModeratorNotes = request.ModeratorNotes,
                InternalNotes = request.InternalNotes,
                IsInappropriateContent = request.IsInappropriateContent,
                IsSpam = request.IsSpam,
                IsFakeListing = request.IsFakeListing,
                IsPriceManipulation = request.IsPriceManipulation,
                IsIncompleteInformation = request.IsIncompleteInformation,
                IsViolationOfTerms = request.IsViolationOfTerms,
                ReviewedAt = DateTime.UtcNow,
                ExpiresAt = DateTime.UtcNow.AddDays(30) // 30 days expiry
            };

            await _unitOfWork.ContentModerations.AddAsync(moderation);
            await _unitOfWork.SaveChangesAsync();

            // Get moderator details
            var moderator = await _unitOfWork.Users.GetByIdAsync(moderatorId);

            var response = new ContentModerationResponseDto
            {
                Id = moderation.Id,
                ContentType = moderation.ContentType,
                ContentId = moderation.ContentId,
                ModeratorId = moderation.ModeratorId,
                ModeratorName = moderator?.FullName ?? "",
                Status = moderation.Status,
                RejectionReason = moderation.RejectionReason,
                ModeratorNotes = moderation.ModeratorNotes,
                InternalNotes = moderation.InternalNotes,
                CreatedAt = moderation.CreatedAt,
                ReviewedAt = moderation.ReviewedAt,
                ExpiresAt = moderation.ExpiresAt,
                IsInappropriateContent = moderation.IsInappropriateContent,
                IsSpam = moderation.IsSpam,
                IsFakeListing = moderation.IsFakeListing,
                IsPriceManipulation = moderation.IsPriceManipulation,
                IsIncompleteInformation = moderation.IsIncompleteInformation,
                IsViolationOfTerms = moderation.IsViolationOfTerms
            };

            return Ok(ApiResponse<ContentModerationResponseDto>.SuccessResponse(response, "Content moderation created successfully"));
        }
        catch (Exception ex)
        {
            return StatusCode(500, ApiResponse<ContentModerationResponseDto>.ErrorResponse($"An error occurred: {ex.Message}"));
        }
    }

    [HttpGet("pending")]
    public async Task<ActionResult<ApiResponse<IEnumerable<ContentModerationResponseDto>>>> GetPendingModerations()
    {
        try
        {
            var moderations = await _unitOfWork.ContentModerations.FindAsync(cm => cm.Status == "Pending");
            var response = new List<ContentModerationResponseDto>();

            foreach (var moderation in moderations)
            {
                var moderator = await _unitOfWork.Users.GetByIdAsync(moderation.ModeratorId);

                response.Add(new ContentModerationResponseDto
                {
                    Id = moderation.Id,
                    ContentType = moderation.ContentType,
                    ContentId = moderation.ContentId,
                    ModeratorId = moderation.ModeratorId,
                    ModeratorName = moderator?.FullName ?? "",
                    Status = moderation.Status,
                    RejectionReason = moderation.RejectionReason,
                    ModeratorNotes = moderation.ModeratorNotes,
                    InternalNotes = moderation.InternalNotes,
                    CreatedAt = moderation.CreatedAt,
                    ReviewedAt = moderation.ReviewedAt,
                    ExpiresAt = moderation.ExpiresAt,
                    IsInappropriateContent = moderation.IsInappropriateContent,
                    IsSpam = moderation.IsSpam,
                    IsFakeListing = moderation.IsFakeListing,
                    IsPriceManipulation = moderation.IsPriceManipulation,
                    IsIncompleteInformation = moderation.IsIncompleteInformation,
                    IsViolationOfTerms = moderation.IsViolationOfTerms
                });
            }

            return Ok(ApiResponse<IEnumerable<ContentModerationResponseDto>>.SuccessResponse(response));
        }
        catch (Exception ex)
        {
            return StatusCode(500, ApiResponse<IEnumerable<ContentModerationResponseDto>>.ErrorResponse($"An error occurred: {ex.Message}"));
        }
    }

    [HttpPut("{id:int}")]
    public async Task<ActionResult<ApiResponse<ContentModerationResponseDto>>> UpdateContentModeration(int id, [FromBody] UpdateContentModerationDto request)
    {
        try
        {
            var moderatorId = int.Parse(User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)!.Value);

            var moderation = await _unitOfWork.ContentModerations.GetByIdAsync(id);
            if (moderation == null)
            {
                return NotFound(ApiResponse<ContentModerationResponseDto>.ErrorResponse("Content moderation not found"));
            }

            // Update fields
            if (!string.IsNullOrEmpty(request.Status))
            {
                moderation.Status = request.Status;
            }

            if (request.RejectionReason != null)
            {
                moderation.RejectionReason = request.RejectionReason;
            }

            if (request.ModeratorNotes != null)
            {
                moderation.ModeratorNotes = request.ModeratorNotes;
            }

            if (request.InternalNotes != null)
            {
                moderation.InternalNotes = request.InternalNotes;
            }

            if (request.IsInappropriateContent.HasValue)
            {
                moderation.IsInappropriateContent = request.IsInappropriateContent.Value;
            }

            if (request.IsSpam.HasValue)
            {
                moderation.IsSpam = request.IsSpam.Value;
            }

            if (request.IsFakeListing.HasValue)
            {
                moderation.IsFakeListing = request.IsFakeListing.Value;
            }

            if (request.IsPriceManipulation.HasValue)
            {
                moderation.IsPriceManipulation = request.IsPriceManipulation.Value;
            }

            if (request.IsIncompleteInformation.HasValue)
            {
                moderation.IsIncompleteInformation = request.IsIncompleteInformation.Value;
            }

            if (request.IsViolationOfTerms.HasValue)
            {
                moderation.IsViolationOfTerms = request.IsViolationOfTerms.Value;
            }

            moderation.ReviewedAt = DateTime.UtcNow;

            await _unitOfWork.ContentModerations.UpdateAsync(moderation);
            await _unitOfWork.SaveChangesAsync();

            // Get updated details
            var moderator = await _unitOfWork.Users.GetByIdAsync(moderation.ModeratorId);

            var response = new ContentModerationResponseDto
            {
                Id = moderation.Id,
                ContentType = moderation.ContentType,
                ContentId = moderation.ContentId,
                ModeratorId = moderation.ModeratorId,
                ModeratorName = moderator?.FullName ?? "",
                Status = moderation.Status,
                RejectionReason = moderation.RejectionReason,
                ModeratorNotes = moderation.ModeratorNotes,
                InternalNotes = moderation.InternalNotes,
                CreatedAt = moderation.CreatedAt,
                ReviewedAt = moderation.ReviewedAt,
                ExpiresAt = moderation.ExpiresAt,
                IsInappropriateContent = moderation.IsInappropriateContent,
                IsSpam = moderation.IsSpam,
                IsFakeListing = moderation.IsFakeListing,
                IsPriceManipulation = moderation.IsPriceManipulation,
                IsIncompleteInformation = moderation.IsIncompleteInformation,
                IsViolationOfTerms = moderation.IsViolationOfTerms
            };

            return Ok(ApiResponse<ContentModerationResponseDto>.SuccessResponse(response, "Content moderation updated successfully"));
        }
        catch (Exception ex)
        {
            return StatusCode(500, ApiResponse<ContentModerationResponseDto>.ErrorResponse($"An error occurred: {ex.Message}"));
        }
    }

    [HttpGet("stats")]
    public async Task<ActionResult<ApiResponse<object>>> GetModerationStats()
    {
        try
        {
            var allModerations = await _unitOfWork.ContentModerations.GetAllAsync();
            var allReports = await _unitOfWork.ContentReports.GetAllAsync();

            var stats = new
            {
                totalModerations = allModerations.Count(),
                pendingModerations = allModerations.Count(m => m.Status == "Pending"),
                approvedModerations = allModerations.Count(m => m.Status == "Approved"),
                rejectedModerations = allModerations.Count(m => m.Status == "Rejected"),
                totalReports = allReports.Count(),
                pendingReports = allReports.Count(r => r.Status == "Pending"),
                resolvedReports = allReports.Count(r => r.Status == "Resolved"),
                dismissedReports = allReports.Count(r => r.Status == "Dismissed")
            };

            return Ok(ApiResponse<object>.SuccessResponse(stats));
        }
        catch (Exception ex)
        {
            return StatusCode(500, ApiResponse<object>.ErrorResponse($"An error occurred: {ex.Message}"));
        }
    }
}

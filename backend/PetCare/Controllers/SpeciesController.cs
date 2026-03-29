using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using PetCare.DTOs;
using PetCare.Entities;
using PetCare.Repositories;

namespace PetCare.Controllers;

[ApiController]
[Route("api/[controller]")]
public class SpeciesController : ControllerBase
{
    private readonly IUnitOfWork _unitOfWork;

    public SpeciesController(IUnitOfWork unitOfWork)
    {
        _unitOfWork = unitOfWork;
    }

    // Public endpoint: anyone (kể cả user thường, chưa đăng nhập) có thể lấy danh sách Species
    [HttpGet]
    [AllowAnonymous]
    public async Task<ActionResult<ApiResponse<IEnumerable<Species>>>> GetAll()
    {
        try
        {
            var list = (await _unitOfWork.Species.GetAllAsync())
                .OrderBy(s => s.Name)
                .ToList();
            return Ok(ApiResponse<IEnumerable<Species>>.SuccessResponse(list));
        }
        catch (Exception ex)
        {
            return StatusCode(500, ApiResponse<IEnumerable<Species>>.ErrorResponse($"Internal server error: {ex.Message}"));
        }
    }
}



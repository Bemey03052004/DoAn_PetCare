using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using PetCare.DTOs;
using PetCare.Entities;
using PetCare.Repositories;

namespace PetCare.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize]
public class PreferencesController : ControllerBase
{
    private readonly IUnitOfWork _uow;
    public PreferencesController(IUnitOfWork uow) { _uow = uow; }

    [HttpGet]
    public async Task<ActionResult<ApiResponse<Preference>>> Get()
    {
        var uid = int.Parse(User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)!.Value);
        var pref = (await _uow.Preferences.FindAsync(p => p.UserId == uid)).FirstOrDefault();
        if (pref == null)
        {
            pref = new Preference { UserId = uid, PreferredSpecies = "Dog", UpdatedAt = DateTime.UtcNow };
            await _uow.Preferences.AddAsync(pref);
        }
        return Ok(ApiResponse<Preference>.SuccessResponse(pref));
    }

    public class UpdatePrefDto
    {
        public string PreferredSpecies { get; set; } = "Dog";
        public string? PreferredGender { get; set; }
        public int? MinAgeMonths { get; set; }
        public int? MaxAgeMonths { get; set; }
        public double? MaxDistanceKm { get; set; }
    }

    [HttpPut]
    public async Task<ActionResult<ApiResponse<Preference>>> Update([FromBody] UpdatePrefDto dto)
    {
        var uid = int.Parse(User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)!.Value);
        var pref = (await _uow.Preferences.FindAsync(p => p.UserId == uid)).FirstOrDefault();
        if (pref == null)
        {
            pref = new Preference { UserId = uid };
            await _uow.Preferences.AddAsync(pref);
        }
        pref.PreferredSpecies = dto.PreferredSpecies;
        pref.PreferredGender = dto.PreferredGender;
        pref.MinAgeMonths = dto.MinAgeMonths;
        pref.MaxAgeMonths = dto.MaxAgeMonths;
        pref.MaxDistanceKm = dto.MaxDistanceKm;
        pref.UpdatedAt = DateTime.UtcNow;
        await _uow.Preferences.UpdateAsync(pref);
        return Ok(ApiResponse<Preference>.SuccessResponse(pref));
    }
}




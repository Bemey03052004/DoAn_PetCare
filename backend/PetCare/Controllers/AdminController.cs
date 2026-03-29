using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using PetCare.DTOs;
using PetCare.Entities;
using PetCare.Repositories;
using System.Security.Claims;
using PetCare.Data;

namespace PetCare.Controllers;

[ApiController]
[Route("api/admin")]
[Authorize(Roles = "Admin")]
public class AdminController : ControllerBase
{
    private readonly IUnitOfWork _unitOfWork;

    public AdminController(IUnitOfWork unitOfWork)
    {
        _unitOfWork = unitOfWork;
    }

    #region Pet Management

    [HttpGet("pets")]
    public async Task<ActionResult<ApiResponse<IEnumerable<PetDto>>>> GetAllPets()
    {
        try
        {
            var pets = await _unitOfWork.Pets.GetAllAsync();
            var petDtos = pets.Select(p => new PetDto
            {
                Id = p.Id,
                Name = p.Name,
                Species = p.Species,
                Breed = p.Breed,
                Age = p.Age,
                Gender = p.Gender,
                Description = p.Description,
                ImageUrl = p.ImageUrl,
                Price = p.Price,
                IsPublic = p.IsPublic,
                IsAdopted = p.IsAdopted,
                IsHidden = p.IsHidden,
                OwnerId = p.OwnerId,
                OwnerName = p.Owner?.FullName ?? "",
                CreatedAt = p.CreatedAt,
                UpdatedAt = p.UpdatedAt
            });

            return Ok(ApiResponse<IEnumerable<PetDto>>.SuccessResponse(petDtos));
        }
        catch (Exception ex)
        {
            return StatusCode(500, ApiResponse<IEnumerable<PetDto>>.ErrorResponse($"Internal server error: {ex.Message}"));
        }
    }

    [HttpPut("pets/{id:int}")]
    public async Task<ActionResult<ApiResponse<PetDto>>> UpdatePet(int id, [FromBody] UpdatePetDto dto)
    {
        try
        {
            var pet = await _unitOfWork.Pets.GetByIdAsync(id);
            if (pet == null)
                return NotFound(ApiResponse<PetDto>.ErrorResponse("Pet not found"));

            // Update pet properties
            pet.Name = dto.Name ?? pet.Name;
            pet.Species = dto.Species ?? pet.Species;
            pet.Breed = dto.Breed ?? pet.Breed;
            pet.AgeMonths = dto.AgeMonths ?? pet.AgeMonths;
            pet.Gender = dto.Gender ?? pet.Gender;
            pet.Description = dto.Description ?? pet.Description;
            pet.ImageUrl = dto.ImageUrl ?? pet.ImageUrl;
            pet.Price = dto.Price ?? pet.Price;
            pet.IsPublic = dto.IsPublic ?? pet.IsPublic;
            pet.IsAdopted = dto.IsAdopted ?? pet.IsAdopted;
            pet.IsHidden = dto.IsHidden ?? pet.IsHidden;
            pet.UpdatedAt = DateTime.UtcNow;

            await _unitOfWork.Pets.UpdateAsync(pet);

            var response = new PetDto
            {
                Id = pet.Id,
                Name = pet.Name,
                Species = pet.Species,
                Breed = pet.Breed,
                Age = pet.Age,
                Gender = pet.Gender,
                Description = pet.Description,
                ImageUrl = pet.ImageUrl,
                Price = pet.Price,
                IsPublic = pet.IsPublic,
                IsAdopted = pet.IsAdopted,
                IsHidden = pet.IsHidden,
                OwnerId = pet.OwnerId,
                OwnerName = pet.Owner?.FullName ?? "",
                CreatedAt = pet.CreatedAt,
                UpdatedAt = pet.UpdatedAt
            };

            return Ok(ApiResponse<PetDto>.SuccessResponse(response));
        }
        catch (Exception ex)
        {
            return StatusCode(500, ApiResponse<PetDto>.ErrorResponse($"Internal server error: {ex.Message}"));
        }
    }

    [HttpDelete("pets/{id:int}")]
    public async Task<ActionResult<ApiResponse<object>>> DeletePet(int id)
    {
        try
        {
            var pet = await _unitOfWork.Pets.GetByIdAsync(id);
            if (pet == null)
                return NotFound(ApiResponse<object>.ErrorResponse("Pet not found"));

            await _unitOfWork.Pets.DeleteAsync(pet);
            return Ok(ApiResponse<object>.SuccessResponse(null, "Pet deleted successfully"));
        }
        catch (Exception ex)
        {
            return StatusCode(500, ApiResponse<object>.ErrorResponse($"Internal server error: {ex.Message}"));
        }
    }

    #endregion

    #region Species Management

    [HttpGet("species")]
    public async Task<ActionResult<ApiResponse<IEnumerable<Species>>>> GetAllSpecies()
    {
        try
        {
            var list = (await _unitOfWork.Species.GetAllAsync()).OrderBy(s => s.Name);
            return Ok(ApiResponse<IEnumerable<Species>>.SuccessResponse(list));
        }
        catch (Exception ex)
        {
            return StatusCode(500, ApiResponse<IEnumerable<Species>>.ErrorResponse($"Internal server error: {ex.Message}"));
        }
    }

    [HttpGet("species/{id:int}")]
    public async Task<ActionResult<ApiResponse<Species>>> GetSpecies(int id)
    {
        try
        {
            var sp = await _unitOfWork.Species.GetByIdAsync(id);
            if (sp == null) return NotFound(ApiResponse<Species>.ErrorResponse("Species not found"));
            return Ok(ApiResponse<Species>.SuccessResponse(sp));
        }
        catch (Exception ex)
        {
            return StatusCode(500, ApiResponse<Species>.ErrorResponse($"Internal server error: {ex.Message}"));
        }
    }

    public class UpsertSpeciesDto { public string Name { get; set; } = string.Empty; public string? Description { get; set; } public bool IsActive { get; set; } = true; }

    [HttpPost("species")]
    public async Task<ActionResult<ApiResponse<Species>>> CreateSpecies([FromBody] UpsertSpeciesDto dto)
    {
        try
        {
            if (string.IsNullOrWhiteSpace(dto.Name))
                return BadRequest(ApiResponse<Species>.ErrorResponse("Name is required"));

            var exists = await _unitOfWork.Species.ExistsAsync(s => s.Name == dto.Name);
            if (exists) return Conflict(ApiResponse<Species>.ErrorResponse("Species name already exists"));

            var sp = new Species { Name = dto.Name.Trim(), Description = dto.Description, IsActive = dto.IsActive, CreatedAt = DateTime.UtcNow };
            await _unitOfWork.Species.AddAsync(sp);
            await _unitOfWork.SaveChangesAsync();
            return Ok(ApiResponse<Species>.SuccessResponse(sp, "Species created"));
        }
        catch (Exception ex)
        {
            return StatusCode(500, ApiResponse<Species>.ErrorResponse($"Internal server error: {ex.Message}"));
        }
    }

    [HttpPut("species/{id:int}")]
    public async Task<ActionResult<ApiResponse<Species>>> UpdateSpecies(int id, [FromBody] UpsertSpeciesDto dto)
    {
        try
        {
            var sp = await _unitOfWork.Species.GetByIdAsync(id);
            if (sp == null) return NotFound(ApiResponse<Species>.ErrorResponse("Species not found"));

            if (!string.Equals(sp.Name, dto.Name, StringComparison.Ordinal))
            {
                var exists = await _unitOfWork.Species.ExistsAsync(s => s.Name == dto.Name);
                if (exists) return Conflict(ApiResponse<Species>.ErrorResponse("Species name already exists"));
            }

            sp.Name = dto.Name.Trim();
            sp.Description = dto.Description;
            sp.IsActive = dto.IsActive;
            sp.UpdatedAt = DateTime.UtcNow;
            await _unitOfWork.Species.UpdateAsync(sp);
            await _unitOfWork.SaveChangesAsync();
            return Ok(ApiResponse<Species>.SuccessResponse(sp, "Species updated"));
        }
        catch (Exception ex)
        {
            return StatusCode(500, ApiResponse<Species>.ErrorResponse($"Internal server error: {ex.Message}"));
        }
    }

    [HttpDelete("species/{id:int}")]
    public async Task<ActionResult<ApiResponse<object>>> DeleteSpecies(int id)
    {
        try
        {
            var sp = await _unitOfWork.Species.GetByIdAsync(id);
            if (sp == null) return NotFound(ApiResponse<object>.ErrorResponse("Species not found"));
            await _unitOfWork.Species.DeleteAsync(sp);
            await _unitOfWork.SaveChangesAsync();
            return Ok(ApiResponse<object>.SuccessResponse(null, "Species deleted"));
        }
        catch (Exception ex)
        {
            return StatusCode(500, ApiResponse<object>.ErrorResponse($"Internal server error: {ex.Message}"));
        }
    }

    #endregion

    #region Transaction Management

    [HttpGet("transactions")]
    public async Task<ActionResult<ApiResponse<IEnumerable<TransactionDto>>>> GetAllTransactions()
    {
        try
        {
            // Aggregate transactions from PaymentTransactions and SaleRequests
            var payments = await _unitOfWork.PaymentTransactions.GetAllAsync();
            var saleRequests = await _unitOfWork.SaleRequests.GetAllAsync();

            var paymentDtos = payments.Select(p => new TransactionDto
            {
                Id = p.Id,
                UserId = p.UserId,
                UserName = p.User?.FullName ?? "",
                Amount = p.Amount,
                Type = p.TransactionType,
                Status = p.Status,
                Description = !string.IsNullOrWhiteSpace(p.Description)
                    ? p.Description!
                    : ($"Thanh toán {p.TransactionType}" + (p.PetId.HasValue ? $" - Pet #{p.PetId}" : "")),
                CreatedAt = p.CreatedAt,
                UpdatedAt = p.CompletedAt
            });

            var saleDtos = saleRequests.Select(sr => new TransactionDto
            {
                Id = sr.Id,
                UserId = sr.BuyerId,
                UserName = sr.Buyer?.FullName ?? "",
                Amount = sr.Amount,
                Type = "SaleRequest",
                Status = sr.Status,
                Description = $"Yêu cầu mua thú cưng: {sr.Pet?.Name ?? ("#" + sr.PetId)}",
                CreatedAt = sr.CreatedAt,
                UpdatedAt = sr.UpdatedAt
            });

            var all = paymentDtos.Concat(saleDtos)
                .OrderByDescending(x => x.CreatedAt)
                .ToList();

            return Ok(ApiResponse<IEnumerable<TransactionDto>>.SuccessResponse(all));
        }
        catch (Exception ex)
        {
            return StatusCode(500, ApiResponse<IEnumerable<TransactionDto>>.ErrorResponse($"Internal server error: {ex.Message}"));
        }
    }

    [HttpGet("transactions/{id:int}")]
    public async Task<ActionResult<ApiResponse<TransactionDto>>> GetTransactionById(int id)
    {
        try
        {
            var transaction = await _unitOfWork.Transactions.GetByIdAsync(id);
            if (transaction == null)
                return NotFound(ApiResponse<TransactionDto>.ErrorResponse("Transaction not found"));

            var response = new TransactionDto
            {
                Id = transaction.Id,
                UserId = transaction.UserId,
                UserName = transaction.User?.FullName ?? "",
                Amount = transaction.Amount,
                Type = transaction.Type,
                Status = transaction.Status,
                Description = transaction.Description,
                CreatedAt = transaction.CreatedAt,
                UpdatedAt = transaction.UpdatedAt
            };

            return Ok(ApiResponse<TransactionDto>.SuccessResponse(response));
        }
        catch (Exception ex)
        {
            return StatusCode(500, ApiResponse<TransactionDto>.ErrorResponse($"Internal server error: {ex.Message}"));
        }
    }

    [HttpPut("transactions/{id:int}/status")]
    public async Task<ActionResult<ApiResponse<TransactionDto>>> UpdateTransactionStatus(int id, [FromBody] UpdateTransactionStatusDto dto)
    {
        try
        {
            var transaction = await _unitOfWork.Transactions.GetByIdAsync(id);
            if (transaction == null)
                return NotFound(ApiResponse<TransactionDto>.ErrorResponse("Transaction not found"));

            transaction.Status = dto.Status;
            transaction.UpdatedAt = DateTime.UtcNow;

            await _unitOfWork.Transactions.UpdateAsync(transaction);

            var response = new TransactionDto
            {
                Id = transaction.Id,
                UserId = transaction.UserId,
                UserName = transaction.User?.FullName ?? "",
                Amount = transaction.Amount,
                Type = transaction.Type,
                Status = transaction.Status,
                Description = transaction.Description,
                CreatedAt = transaction.CreatedAt,
                UpdatedAt = transaction.UpdatedAt
            };

            return Ok(ApiResponse<TransactionDto>.SuccessResponse(response));
        }
        catch (Exception ex)
        {
            return StatusCode(500, ApiResponse<TransactionDto>.ErrorResponse($"Internal server error: {ex.Message}"));
        }
    }

    #endregion

    #region Dashboard

    [HttpGet("dashboard")]
    public async Task<ActionResult<ApiResponse<DashboardDto>>> GetDashboard()
    {
        try
        {
            var totalPets = await _unitOfWork.Pets.CountAsync();
            var totalUsers = await _unitOfWork.Users.CountAsync();
            var totalTransactions = await _unitOfWork.Transactions.CountAsync();
            var totalBoardingRequests = await _unitOfWork.BoardingRequests.CountAsync();
            var totalAdoptionRequests = await _unitOfWork.AdoptionRequests.CountAsync();

            // Calculate revenue
            var transactions = await _unitOfWork.Transactions.FindAsync(t => t.Status == "Completed");
            var totalRevenue = transactions.Sum(t => t.Amount);

            // Calculate success rate
            var completedTransactions = transactions.Count();
            var successRate = totalTransactions > 0 ? (double)completedTransactions / totalTransactions * 100 : 0;

            // Get recent activities
            var recentPets = await _unitOfWork.Pets.GetRecentAsync(5);
            var recentTransactions = await _unitOfWork.Transactions.GetRecentAsync(5);

            var dashboard = new DashboardDto
            {
                TotalPets = totalPets,
                TotalUsers = totalUsers,
                TotalTransactions = totalTransactions,
                TotalBoardingRequests = totalBoardingRequests,
                TotalAdoptionRequests = totalAdoptionRequests,
                TotalRevenue = totalRevenue,
                SuccessRate = Math.Round(successRate, 2),
                RecentPets = recentPets.Select(p => new PetDto
                {
                    Id = p.Id,
                    Name = p.Name,
                    Species = p.Species,
                    Breed = p.Breed,
                    Age = p.Age,
                    Gender = p.Gender,
                    Description = p.Description,
                    ImageUrl = p.ImageUrl,
                    Price = p.Price,
                    IsPublic = p.IsPublic,
                    IsAdopted = p.IsAdopted,
                    IsHidden = p.IsHidden,
                    OwnerId = p.OwnerId,
                    OwnerName = p.Owner?.FullName ?? "",
                    CreatedAt = p.CreatedAt,
                    UpdatedAt = p.UpdatedAt
                }).ToList(),
                RecentTransactions = recentTransactions.Select(t => new TransactionDto
                {
                    Id = t.Id,
                    UserId = t.UserId,
                    UserName = t.User?.FullName ?? "",
                    Amount = t.Amount,
                    Type = t.Type,
                    Status = t.Status,
                    Description = t.Description,
                    CreatedAt = t.CreatedAt,
                    UpdatedAt = t.UpdatedAt
                }).ToList()
            };

            return Ok(ApiResponse<DashboardDto>.SuccessResponse(dashboard));
        }
        catch (Exception ex)
        {
            return StatusCode(500, ApiResponse<DashboardDto>.ErrorResponse($"Internal server error: {ex.Message}"));
        }
    }

    #endregion

    #region User Management

    [HttpGet("users-mgmt")]
    public async Task<ActionResult<ApiResponse<IEnumerable<UserDto>>>> GetAllUsers()
    {
        try
        {
            var users = await _unitOfWork.Users.GetAllAsync();
            var userDtos = users.Select(u => new UserDto
            {
                Id = u.Id,
                FullName = u.FullName,
                Email = u.Email,
                PhoneNumber = u.PhoneNumber,
                IsActive = u.IsActive,
                IsEmailVerified = u.IsEmailVerified,
                CreatedAt = u.CreatedAt,
                UpdatedAt = u.UpdatedAt,
                Roles = u.UserRoles?.Select(ur => ur.Role?.Name ?? "").ToList() ?? new List<string>()
            });

            return Ok(ApiResponse<IEnumerable<UserDto>>.SuccessResponse(userDtos));
        }
        catch (Exception ex)
        {
            return StatusCode(500, ApiResponse<IEnumerable<UserDto>>.ErrorResponse($"Internal server error: {ex.Message}"));
        }
    }

    [HttpGet("users-mgmt/{id:int}/roles")]
    public async Task<ActionResult<ApiResponse<IEnumerable<string>>>> GetUserRolesAdmin(int id)
    {
        try
        {
            var user = await _unitOfWork.Users.GetByIdAsync(id);
            if (user == null)
                return NotFound(ApiResponse<IEnumerable<string>>.ErrorResponse("User not found"));

            var roles = await _unitOfWork.Users.GetUserRolesAsync(id);
            return Ok(ApiResponse<IEnumerable<string>>.SuccessResponse(roles));
        }
        catch (Exception ex)
        {
            return StatusCode(500, ApiResponse<IEnumerable<string>>.ErrorResponse($"Internal server error: {ex.Message}"));
        }
    }

    public class UpdateUserRolesRequest { public List<string> Roles { get; set; } = new(); }

    [HttpPut("users-mgmt/{id:int}/roles")]
    public async Task<ActionResult<ApiResponse<object>>> UpdateUserRoles(int id, [FromBody] UpdateUserRolesRequest request)
    {
        try
        {
            var user = await _unitOfWork.Users.GetByIdAsync(id);
            if (user == null)
                return NotFound(ApiResponse<object>.ErrorResponse("User not found"));

            // Current roles
            var currentRoles = (await _unitOfWork.Users.GetUserRolesAsync(id)).ToHashSet(StringComparer.OrdinalIgnoreCase);
            var desiredRoles = (request.Roles ?? new List<string>()).ToHashSet(StringComparer.OrdinalIgnoreCase);

            // Ensure at least 'User' role
            if (desiredRoles.Count == 0)
            {
                desiredRoles.Add("User");
            }

            // Roles to add
            var toAdd = desiredRoles.Except(currentRoles, StringComparer.OrdinalIgnoreCase).ToList();
            // Roles to remove
            var toRemove = currentRoles.Except(desiredRoles, StringComparer.OrdinalIgnoreCase).ToList();

            // Add
            foreach (var roleName in toAdd)
            {
                var role = (await _unitOfWork.Roles.FindAsync(r => r.Name == roleName)).FirstOrDefault();
                if (role != null)
                {
                    await _unitOfWork.UserRoles.AddAsync(new UserRole { UserId = id, RoleId = role.Id, AssignedAt = DateTime.UtcNow });
                }
            }

            // Remove
            foreach (var roleName in toRemove)
            {
                var role = (await _unitOfWork.Roles.FindAsync(r => r.Name == roleName)).FirstOrDefault();
                if (role != null)
                {
                    var link = (await _unitOfWork.UserRoles.FindAsync(ur => ur.UserId == id && ur.RoleId == role.Id)).FirstOrDefault();
                    if (link != null)
                    {
                        await _unitOfWork.UserRoles.DeleteAsync(link);
                    }
                }
            }

            await _unitOfWork.SaveChangesAsync();
            return Ok(ApiResponse<object>.SuccessResponse(null, "User roles updated"));
        }
        catch (Exception ex)
        {
            return StatusCode(500, ApiResponse<object>.ErrorResponse($"Internal server error: {ex.Message}"));
        }
    }

    [HttpGet("users-mgmt/{id:int}")]
    public async Task<ActionResult<ApiResponse<UserDto>>> GetUserById(int id)
    {
        try
        {
            var user = await _unitOfWork.Users.GetByIdAsync(id);
            if (user == null)
                return NotFound(ApiResponse<UserDto>.ErrorResponse("User not found"));

            var response = new UserDto
            {
                Id = user.Id,
                FullName = user.FullName,
                Email = user.Email,
                PhoneNumber = user.PhoneNumber,
                IsActive = user.IsActive,
                IsEmailVerified = user.IsEmailVerified,
                CreatedAt = user.CreatedAt,
                UpdatedAt = user.UpdatedAt,
                Roles = user.UserRoles?.Select(ur => ur.Role?.Name ?? "").ToList() ?? new List<string>()
            };

            return Ok(ApiResponse<UserDto>.SuccessResponse(response));
        }
        catch (Exception ex)
        {
            return StatusCode(500, ApiResponse<UserDto>.ErrorResponse($"Internal server error: {ex.Message}"));
        }
    }

    [HttpPut("users-mgmt/{id:int}/status")]
    public async Task<ActionResult<ApiResponse<UserDto>>> UpdateUserStatus(int id, [FromBody] UpdateUserStatusDto dto)
    {
        try
        {
            var user = await _unitOfWork.Users.GetByIdAsync(id);
            if (user == null)
                return NotFound(ApiResponse<UserDto>.ErrorResponse("User not found"));

            user.IsActive = dto.IsActive;
            user.UpdatedAt = DateTime.UtcNow;

            await _unitOfWork.Users.UpdateAsync(user);

            var response = new UserDto
            {
                Id = user.Id,
                FullName = user.FullName,
                Email = user.Email,
                PhoneNumber = user.PhoneNumber,
                IsActive = user.IsActive,
                IsEmailVerified = user.IsEmailVerified,
                CreatedAt = user.CreatedAt,
                UpdatedAt = user.UpdatedAt,
                Roles = user.UserRoles?.Select(ur => ur.Role?.Name ?? "").ToList() ?? new List<string>()
            };

            return Ok(ApiResponse<UserDto>.SuccessResponse(response));
        }
        catch (Exception ex)
        {
            return StatusCode(500, ApiResponse<UserDto>.ErrorResponse($"Internal server error: {ex.Message}"));
        }
    }

    [HttpPost("users-mgmt/{id:int}/roles")]
    public async Task<ActionResult<ApiResponse<object>>> AssignRole(int id, [FromBody] AssignRoleDto dto)
    {
        try
        {
            var user = await _unitOfWork.Users.GetByIdAsync(id);
            if (user == null)
                return NotFound(ApiResponse<object>.ErrorResponse("User not found"));

            var role = await _unitOfWork.Roles.FindAsync(r => r.Name == dto.RoleName);
            var existingRole = role.FirstOrDefault();
            if (existingRole == null)
                return BadRequest(ApiResponse<object>.ErrorResponse("Role not found"));

            // Check if user already has this role
            var existingUserRole = await _unitOfWork.UserRoles.FindAsync(ur => ur.UserId == id && ur.RoleId == existingRole.Id);
            if (existingUserRole.Any())
                return BadRequest(ApiResponse<object>.ErrorResponse("User already has this role"));

            var userRole = new UserRole
            {
                UserId = id,
                RoleId = existingRole.Id
            };

            await _unitOfWork.UserRoles.AddAsync(userRole);
            await _unitOfWork.SaveChangesAsync();

            return Ok(ApiResponse<object>.SuccessResponse(null, "Role assigned successfully"));
        }
        catch (Exception ex)
        {
            return StatusCode(500, ApiResponse<object>.ErrorResponse($"Internal server error: {ex.Message}"));
        }
    }

    [HttpDelete("users-mgmt/{id:int}/roles/{roleId:int}")]
    public async Task<ActionResult<ApiResponse<object>>> RemoveRole(int id, int roleId)
    {
        try
        {
            var userRole = await _unitOfWork.UserRoles.FindAsync(ur => ur.UserId == id && ur.RoleId == roleId);
            var existingUserRole = userRole.FirstOrDefault();
            if (existingUserRole == null)
                return NotFound(ApiResponse<object>.ErrorResponse("User role not found"));

            await _unitOfWork.UserRoles.DeleteAsync(existingUserRole);
            await _unitOfWork.SaveChangesAsync();

            return Ok(ApiResponse<object>.SuccessResponse(null, "Role removed successfully"));
        }
        catch (Exception ex)
        {
            return StatusCode(500, ApiResponse<object>.ErrorResponse($"Internal server error: {ex.Message}"));
        }
    }

    #endregion

    #region Boarding Management

    [HttpGet("boarding-requests")]
    public async Task<ActionResult<ApiResponse<IEnumerable<BoardingRequestDto>>>> GetAllBoardingRequests()
    {
        try
        {
            var requests = await _unitOfWork.BoardingRequests.GetAllAsync();
            var requestDtos = requests.Select(r => new BoardingRequestDto
            {
                Id = r.Id,
                PetId = r.PetId,
                PetName = r.Pet?.Name ?? "",
                PetImageUrl = r.Pet?.ImageUrl ?? "",
                OwnerId = r.OwnerId,
                OwnerName = r.Owner?.FullName ?? "",
                CustomerId = r.CustomerId,
                CustomerName = r.Customer?.FullName ?? "",
                StartDate = r.StartDate,
                EndDate = r.EndDate,
                PricePerDay = r.PricePerDay,
                TotalAmount = r.TotalAmount,
                SpecialInstructions = r.SpecialInstructions,
                ContactPhone = r.ContactPhone,
                ContactAddress = r.ContactAddress,
                Status = r.Status,
                CreatedAt = r.CreatedAt,
                UpdatedAt = r.UpdatedAt,
                ChatRoomId = r.ChatRoomId
            });

            return Ok(ApiResponse<IEnumerable<BoardingRequestDto>>.SuccessResponse(requestDtos));
        }
        catch (Exception ex)
        {
            return StatusCode(500, ApiResponse<IEnumerable<BoardingRequestDto>>.ErrorResponse($"Internal server error: {ex.Message}"));
        }
    }

    [HttpPut("boarding-requests/{id:int}/status")]
    public async Task<ActionResult<ApiResponse<BoardingRequestDto>>> UpdateBoardingRequestStatus(int id, [FromBody] UpdateBoardingRequestStatusDto dto)
    {
        try
        {
            var request = await _unitOfWork.BoardingRequests.GetByIdAsync(id);
            if (request == null)
                return NotFound(ApiResponse<BoardingRequestDto>.ErrorResponse("Boarding request not found"));

            request.Status = dto.Status;
            request.UpdatedAt = DateTime.UtcNow;

            await _unitOfWork.BoardingRequests.UpdateAsync(request);

            var response = new BoardingRequestDto
            {
                Id = request.Id,
                PetId = request.PetId,
                PetName = request.Pet?.Name ?? "",
                PetImageUrl = request.Pet?.ImageUrl ?? "",
                OwnerId = request.OwnerId,
                OwnerName = request.Owner?.FullName ?? "",
                CustomerId = request.CustomerId,
                CustomerName = request.Customer?.FullName ?? "",
                StartDate = request.StartDate,
                EndDate = request.EndDate,
                PricePerDay = request.PricePerDay,
                TotalAmount = request.TotalAmount,
                SpecialInstructions = request.SpecialInstructions,
                ContactPhone = request.ContactPhone,
                ContactAddress = request.ContactAddress,
                Status = request.Status,
                CreatedAt = request.CreatedAt,
                UpdatedAt = request.UpdatedAt,
                ChatRoomId = request.ChatRoomId
            };

            return Ok(ApiResponse<BoardingRequestDto>.SuccessResponse(response));
        }
        catch (Exception ex)
        {
            return StatusCode(500, ApiResponse<BoardingRequestDto>.ErrorResponse($"Internal server error: {ex.Message}"));
        }
    }

    #endregion

    #region Adoption Management

    [HttpGet("adoption-requests")]
    public async Task<ActionResult<ApiResponse<IEnumerable<AdoptionRequestDto>>>> GetAllAdoptionRequests()
    {
        try
        {
            var requests = await _unitOfWork.AdoptionRequests.GetAllAsync();
            var requestDtos = requests.Select(r => new AdoptionRequestDto
            {
                Id = r.Id,
                PetId = r.PetId,
                PetName = r.Pet?.Name ?? "",
                PetImageUrl = r.Pet?.ImageUrl ?? "",
                UserId = r.UserId,
                UserName = r.User?.FullName ?? "",
                Message = r.Message,
                Status = r.Status,
                CreatedAt = r.CreatedAt,
                UpdatedAt = r.UpdatedAt
            });

            return Ok(ApiResponse<IEnumerable<AdoptionRequestDto>>.SuccessResponse(requestDtos));
        }
        catch (Exception ex)
        {
            return StatusCode(500, ApiResponse<IEnumerable<AdoptionRequestDto>>.ErrorResponse($"Internal server error: {ex.Message}"));
        }
    }

    [HttpPut("adoption-requests/{id:int}/status")]
    public async Task<ActionResult<ApiResponse<AdoptionRequestDto>>> UpdateAdoptionRequestStatus(int id, [FromBody] UpdateAdoptionRequestStatusDto dto)
    {
        try
        {
            var request = await _unitOfWork.AdoptionRequests.GetByIdAsync(id);
            if (request == null)
                return NotFound(ApiResponse<AdoptionRequestDto>.ErrorResponse("Adoption request not found"));

            request.Status = dto.Status;
            request.UpdatedAt = DateTime.UtcNow;

            // If accepted, mark pet as adopted
            if (dto.Status == "Accepted")
            {
                var pet = await _unitOfWork.Pets.GetByIdAsync(request.PetId);
                if (pet != null)
                {
                    pet.IsAdopted = true;
                    pet.IsPublic = false;
                    await _unitOfWork.Pets.UpdateAsync(pet);
                }
            }

            await _unitOfWork.AdoptionRequests.UpdateAsync(request);

            var response = new AdoptionRequestDto
            {
                Id = request.Id,
                PetId = request.PetId,
                PetName = request.Pet?.Name ?? "",
                PetImageUrl = request.Pet?.ImageUrl ?? "",
                UserId = request.UserId,
                UserName = request.User?.FullName ?? "",
                Message = request.Message,
                Status = request.Status,
                CreatedAt = request.CreatedAt,
                UpdatedAt = request.UpdatedAt
            };

            return Ok(ApiResponse<AdoptionRequestDto>.SuccessResponse(response));
        }
        catch (Exception ex)
        {
            return StatusCode(500, ApiResponse<AdoptionRequestDto>.ErrorResponse($"Internal server error: {ex.Message}"));
        }
    }

    #endregion

    #region System Management

    [HttpGet("system-stats")]
    public async Task<ActionResult<ApiResponse<SystemStatsDto>>> GetSystemStats()
    {
        try
        {
            var totalUsers = await _unitOfWork.Users.CountAsync();
            var activeUsers = await _unitOfWork.Users.CountAsync(u => u.IsActive);
            var totalPets = await _unitOfWork.Pets.CountAsync();
            var publicPets = await _unitOfWork.Pets.CountAsync(p => p.IsPublic);
            var adoptedPets = await _unitOfWork.Pets.CountAsync(p => p.IsAdopted);
            var totalTransactions = await _unitOfWork.Transactions.CountAsync();
            var completedTransactions = await _unitOfWork.Transactions.CountAsync(t => t.Status == "Completed");
            var totalRevenue = (await _unitOfWork.Transactions.FindAsync(t => t.Status == "Completed")).Sum(t => t.Amount);

            var stats = new SystemStatsDto
            {
                TotalUsers = totalUsers,
                ActiveUsers = activeUsers,
                TotalPets = totalPets,
                PublicPets = publicPets,
                AdoptedPets = adoptedPets,
                TotalTransactions = totalTransactions,
                CompletedTransactions = completedTransactions,
                TotalRevenue = totalRevenue,
                SuccessRate = totalTransactions > 0 ? (double)completedTransactions / totalTransactions * 100 : 0
            };

            return Ok(ApiResponse<SystemStatsDto>.SuccessResponse(stats));
        }
        catch (Exception ex)
        {
            return StatusCode(500, ApiResponse<SystemStatsDto>.ErrorResponse($"Internal server error: {ex.Message}"));
        }
    }

    [HttpGet("recent-activities")]
    public async Task<ActionResult<ApiResponse<RecentActivitiesDto>>> GetRecentActivities()
    {
        try
        {
            var recentPets = await _unitOfWork.Pets.GetRecentAsync(10);
            var recentTransactions = await _unitOfWork.Transactions.GetRecentAsync(10);
            var recentBoardingRequests = await _unitOfWork.BoardingRequests.GetRecentAsync(10);
            var recentAdoptionRequests = await _unitOfWork.AdoptionRequests.GetRecentAsync(10);

            var activities = new RecentActivitiesDto
            {
                RecentPets = recentPets.Select(p => new PetDto
                {
                    Id = p.Id,
                    Name = p.Name,
                    Species = p.Species,
                    Breed = p.Breed,
                    Age = p.Age,
                    Gender = p.Gender,
                    Description = p.Description,
                    ImageUrl = p.ImageUrl,
                    Price = p.Price,
                    IsPublic = p.IsPublic,
                    IsAdopted = p.IsAdopted,
                    IsHidden = p.IsHidden,
                    OwnerId = p.OwnerId,
                    OwnerName = p.Owner?.FullName ?? "",
                    CreatedAt = p.CreatedAt,
                    UpdatedAt = p.UpdatedAt
                }).ToList(),
                RecentTransactions = recentTransactions.Select(t => new TransactionDto
                {
                    Id = t.Id,
                    UserId = t.UserId,
                    UserName = t.User?.FullName ?? "",
                    Amount = t.Amount,
                    Type = t.Type,
                    Status = t.Status,
                    Description = t.Description,
                    CreatedAt = t.CreatedAt,
                    UpdatedAt = t.UpdatedAt
                }).ToList(),
                RecentBoardingRequests = recentBoardingRequests.Select(r => new BoardingRequestDto
                {
                    Id = r.Id,
                    PetId = r.PetId,
                    PetName = r.Pet?.Name ?? "",
                    PetImageUrl = r.Pet?.ImageUrl ?? "",
                    OwnerId = r.OwnerId,
                    OwnerName = r.Owner?.FullName ?? "",
                    CustomerId = r.CustomerId,
                    CustomerName = r.Customer?.FullName ?? "",
                    StartDate = r.StartDate,
                    EndDate = r.EndDate,
                    PricePerDay = r.PricePerDay,
                    TotalAmount = r.TotalAmount,
                    SpecialInstructions = r.SpecialInstructions,
                    ContactPhone = r.ContactPhone,
                    ContactAddress = r.ContactAddress,
                    Status = r.Status,
                    CreatedAt = r.CreatedAt,
                    UpdatedAt = r.UpdatedAt,
                    ChatRoomId = r.ChatRoomId
                }).ToList(),
                RecentAdoptionRequests = recentAdoptionRequests.Select(r => new AdoptionRequestDto
                {
                    Id = r.Id,
                    PetId = r.PetId,
                    PetName = r.Pet?.Name ?? "",
                    PetImageUrl = r.Pet?.ImageUrl ?? "",
                    UserId = r.UserId,
                    UserName = r.User?.FullName ?? "",
                    Message = r.Message,
                    Status = r.Status,
                    CreatedAt = r.CreatedAt,
                    UpdatedAt = r.UpdatedAt
                }).ToList()
            };

            return Ok(ApiResponse<RecentActivitiesDto>.SuccessResponse(activities));
        }
        catch (Exception ex)
        {
            return StatusCode(500, ApiResponse<RecentActivitiesDto>.ErrorResponse($"Internal server error: {ex.Message}"));
        }
    }

    #endregion

    #region Test Data

    [HttpPost("create-sample-transaction")]
    public async Task<ActionResult<ApiResponse<TransactionDto>>> CreateSampleTransaction([FromBody] CreateSampleTransactionDto dto)
    {
        try
        {
            var transaction = new Transaction
            {
                UserId = dto.UserId,
                Amount = dto.Amount,
                Type = dto.Type,
                Status = dto.Status,
                Description = dto.Description,
                CreatedAt = DateTime.UtcNow
            };

            await _unitOfWork.Transactions.AddAsync(transaction);
            await _unitOfWork.SaveChangesAsync();

            var response = new TransactionDto
            {
                Id = transaction.Id,
                UserId = transaction.UserId,
                UserName = transaction.User?.FullName ?? "",
                Amount = transaction.Amount,
                Type = transaction.Type,
                Status = transaction.Status,
                Description = transaction.Description,
                CreatedAt = transaction.CreatedAt,
                UpdatedAt = transaction.UpdatedAt
            };

            return Ok(ApiResponse<TransactionDto>.SuccessResponse(response));
        }
        catch (Exception ex)
        {
            return StatusCode(500, ApiResponse<TransactionDto>.ErrorResponse($"Internal server error: {ex.Message}"));
    }
}

    #endregion
}
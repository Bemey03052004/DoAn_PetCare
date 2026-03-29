using Microsoft.AspNetCore.Mvc;
using PetCare.DTOs;
using PetCare.Services;
using FluentValidation;
using FluentValidation.Results;

namespace PetCare.Controllers;

[ApiController]
[Route("api/[controller]")]
public class AuthController : ControllerBase
{
    private readonly IAuthService _authService;
    private readonly IValidator<UserRegistrationDto> _registrationValidator;
    private readonly IValidator<LoginDto> _loginValidator;
    private readonly IEmailService _emailService;

    public AuthController(
        IAuthService authService, 
        IValidator<UserRegistrationDto> registrationValidator,
        IValidator<LoginDto> loginValidator,
        IEmailService emailService)
    {
        _authService = authService;
        _registrationValidator = registrationValidator;
        _loginValidator = loginValidator;
        _emailService = emailService;
    }

    [HttpPost("register")]
    public async Task<ActionResult<ApiResponse<UserResponseDto>>> Register([FromBody] UserRegistrationDto registrationDto)
    {
        try
        {
            // Validate registration data
            ValidationResult validationResult = _registrationValidator.Validate(registrationDto);
            if (!validationResult.IsValid)
            {
                var errors = validationResult.Errors.Select(e => $"{e.PropertyName}: {e.ErrorMessage}").ToList();
                return BadRequest(ApiResponse<UserResponseDto>.ErrorResponse("Validation failed", errors));
            }

            // Register the user (email uniqueness is checked inside the service)
            var userResponse = await _authService.RegisterUserAsync(registrationDto);
            
            // Send verification email
            await _authService.ResendVerificationCodeAsync(registrationDto.Email, _emailService);
            
            // Return success response
            var response = ApiResponse<UserResponseDto>.SuccessResponse(userResponse, "Registration successful. Please check your email for verification code.");
            return CreatedAtAction(nameof(GetUserById), new { id = userResponse.Id }, response);
        }
        catch (InvalidOperationException ex)
        {
            return Conflict(ApiResponse<UserResponseDto>.ErrorResponse(ex.Message));
        }
        catch (Exception ex)
        {
            return StatusCode(500, ApiResponse<UserResponseDto>.ErrorResponse($"An error occurred during registration: {ex.Message}"));
        }
    }

    [HttpPost("refresh-token")]
    public async Task<ActionResult<ApiResponse<AuthResponseDto>>> RefreshToken([FromBody] RefreshTokenDto refreshTokenDto)
    {
        try
        {
            var response = await _authService.RefreshTokenAsync(refreshTokenDto.RefreshToken);
            return Ok(ApiResponse<AuthResponseDto>.SuccessResponse(response, "Token refreshed successfully"));
        }
        catch (UnauthorizedAccessException ex)
        {
            return Unauthorized(ApiResponse<AuthResponseDto>.ErrorResponse(ex.Message));
        }
        catch (Exception ex)
        {
            return StatusCode(500, ApiResponse<AuthResponseDto>.ErrorResponse("An error occurred while refreshing token", new List<string> { ex.Message }));
        }
    }

    [HttpPost("login")]
    public async Task<ActionResult<ApiResponse<AuthResponseDto>>> Login([FromBody] LoginRequestDto loginDto)
    {
        try
        {
            // Get client IP address
            var ipAddress = GetClientIpAddress();

            // Attempt to login with session tracking
            var authResponse = await _authService.LoginWithSessionAsync(loginDto, ipAddress);
            
            // Return success response
            return Ok(ApiResponse<AuthResponseDto>.SuccessResponse(authResponse, "Login successful"));
        }
        catch (InvalidOperationException ex)
        {
            return Unauthorized(ApiResponse<AuthResponseDto>.ErrorResponse(ex.Message));
        }
        catch (Exception ex)
        {
            return StatusCode(500, ApiResponse<AuthResponseDto>.ErrorResponse($"An error occurred during login: {ex.Message}"));
        }
    }

    [HttpGet("users/{id}")]
    public IActionResult GetUserById(int id)
    {
        // This method is just to support CreatedAtAction
        // The actual implementation would retrieve a user by ID
        return Ok();
    }

    [HttpPost("forgot-password")]
    public async Task<ActionResult<ApiResponse<object>>> ForgotPassword([FromBody] ForgotPasswordRequestDto request)
    {
        try
        {
            await _authService.ForgotPasswordAsync(request.Email, _emailService);
            return Ok(ApiResponse<object>.SuccessResponse(null, "Password reset email sent successfully"));
        }
        catch (InvalidOperationException ex)
        {
            return NotFound(ApiResponse<object>.ErrorResponse(ex.Message));
        }
        catch (Exception ex)
        {
            return StatusCode(500, ApiResponse<object>.ErrorResponse($"An error occurred: {ex.Message}"));
        }
    }

    [HttpPost("verify-reset-code")]
    public async Task<ActionResult<ApiResponse<object>>> VerifyResetCode([FromBody] VerifyResetCodeRequestDto request)
    {
        try
        {
            await _authService.VerifyResetCodeAsync(request.Email, request.Code);
            return Ok(ApiResponse<object>.SuccessResponse(null, "Reset code verified successfully"));
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(ApiResponse<object>.ErrorResponse(ex.Message));
        }
        catch (Exception ex)
        {
            return StatusCode(500, ApiResponse<object>.ErrorResponse($"An error occurred: {ex.Message}"));
        }
    }

    [HttpPost("reset-password")]
    public async Task<ActionResult<ApiResponse<object>>> ResetPassword([FromBody] ResetPasswordRequestDto request)
    {
        try
        {
            await _authService.ResetPasswordAsync(request.Email, request.Code, request.NewPassword);
            return Ok(ApiResponse<object>.SuccessResponse(null, "Password reset successfully"));
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(ApiResponse<object>.ErrorResponse(ex.Message));
        }
        catch (Exception ex)
        {
            return StatusCode(500, ApiResponse<object>.ErrorResponse($"An error occurred: {ex.Message}"));
        }
    }

    [HttpPost("verify-email")]
    public async Task<ActionResult<ApiResponse<object>>> VerifyEmail([FromBody] VerifyEmailRequestDto request)
    {
        try
        {
            await _authService.VerifyEmailAsync(request.Email, request.Code);
            return Ok(ApiResponse<object>.SuccessResponse(null, "Email verified successfully"));
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(ApiResponse<object>.ErrorResponse(ex.Message));
        }
        catch (Exception ex)
        {
            return StatusCode(500, ApiResponse<object>.ErrorResponse($"An error occurred: {ex.Message}"));
        }
    }

    [HttpPost("resend-verification")]
    public async Task<ActionResult<ApiResponse<object>>> ResendVerification([FromBody] ResendVerificationRequestDto request)
    {
        try
        {
            await _authService.ResendVerificationCodeAsync(request.Email, _emailService);
            return Ok(ApiResponse<object>.SuccessResponse(null, "Verification code sent successfully"));
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(ApiResponse<object>.ErrorResponse(ex.Message));
        }
        catch (Exception ex)
        {
            return StatusCode(500, ApiResponse<object>.ErrorResponse($"An error occurred: {ex.Message}"));
        }
    }

    [HttpPost("google")]
    public async Task<ActionResult<ApiResponse<AuthResponseDto>>> GoogleAuth([FromBody] GoogleAuthRequestDto request)
    {
        try
        {
            // Validate Google tokens (simplified - in production, verify with Google)
            if (string.IsNullOrEmpty(request.IdToken) || string.IsNullOrEmpty(request.AccessToken))
            {
                return BadRequest(ApiResponse<AuthResponseDto>.ErrorResponse("Invalid Google tokens"));
            }

            // Check if user exists by email
            var existingUser = await _authService.GetUserByEmailAsync(request.Email);
            
            if (existingUser == null)
            {
                // Create new user from Google data
                var newUserDto = new UserRegistrationDto
                {
                    FullName = request.Name,
                    Email = request.Email,
                    Password = "GoogleAuth_" + Guid.NewGuid().ToString(), // Random password for Google users
                    ConfirmPassword = "GoogleAuth_" + Guid.NewGuid().ToString(),
                    Phone = null,
                    Address = null,
                    Latitude = null,
                    Longitude = null
                };

                var registrationResult = await _authService.RegisterAsync(newUserDto);
                if (!registrationResult.Success)
                {
                    return BadRequest(ApiResponse<AuthResponseDto>.ErrorResponse("Failed to create user from Google account"));
                }

                existingUser = registrationResult.Data;
            }

            // Generate JWT token for the user
            var token = _authService.GenerateJwtToken(existingUser);
            
            var authResponse = new AuthResponseDto
            {
                User = existingUser,
                Token = token
            };

            return Ok(ApiResponse<AuthResponseDto>.SuccessResponse(authResponse, "Google authentication successful"));
        }
        catch (Exception ex)
        {
            return StatusCode(500, ApiResponse<AuthResponseDto>.ErrorResponse($"Google authentication failed: {ex.Message}"));
        }
    }

    private string GetClientIpAddress()
    {
        // Try to get IP from X-Forwarded-For header (for load balancers/proxies)
        var forwardedFor = Request.Headers["X-Forwarded-For"].FirstOrDefault();
        if (!string.IsNullOrEmpty(forwardedFor))
        {
            return forwardedFor.Split(',')[0].Trim();
        }

        // Try to get IP from X-Real-IP header
        var realIp = Request.Headers["X-Real-IP"].FirstOrDefault();
        if (!string.IsNullOrEmpty(realIp))
        {
            return realIp;
        }

        // Fall back to connection remote IP
        return HttpContext.Connection.RemoteIpAddress?.ToString() ?? "Unknown";
    }
}
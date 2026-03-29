using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using Microsoft.Extensions.Configuration;
using PetCare.DTOs;
using PetCare.Entities;
using PetCare.Repositories;

namespace PetCare.Services;

public interface IAuthService
{
    Task<UserResponseDto> RegisterUserAsync(UserRegistrationDto registrationDto);
    Task<AuthResponseDto> LoginAsync(LoginDto loginDto);
    Task<AuthResponseDto> LoginWithSessionAsync(LoginRequestDto loginDto, string ipAddress);
    Task ForgotPasswordAsync(string email, IEmailService emailService);
    Task VerifyResetCodeAsync(string email, string code);
    Task ResetPasswordAsync(string email, string code, string newPassword);
    Task VerifyEmailAsync(string email, string code);
    Task ResendVerificationCodeAsync(string email, IEmailService emailService);
    
    // Additional methods for Google Auth
    Task<UserResponseDto?> GetUserByEmailAsync(string email);
    Task<ApiResponse<UserResponseDto>> RegisterAsync(UserRegistrationDto registrationDto);
    string GenerateJwtToken(UserResponseDto user);
    
    // Refresh token method
    Task<AuthResponseDto> RefreshTokenAsync(string refreshToken);
}

public class AuthService : IAuthService
{
    private readonly IUnitOfWork _unitOfWork;
    private readonly IConfiguration _configuration;
    private readonly ILocationService _locationService;

    public AuthService(IUnitOfWork unitOfWork, IConfiguration configuration, ILocationService locationService)
    {
        _unitOfWork = unitOfWork;
        _configuration = configuration;
        _locationService = locationService;
    }

    public async Task<UserResponseDto> RegisterUserAsync(UserRegistrationDto dto)
    {
        // Check if email is already in use
        if (!await _unitOfWork.Users.IsEmailUniqueAsync(dto.Email))
        {
            throw new InvalidOperationException("Email already in use");
        }

        // Begin transaction
        await _unitOfWork.BeginTransactionAsync();

        try
        {
            // Create new user
            var user = new User
            {
                FullName = dto.FullName,
                Email = dto.Email,
                PasswordHash = BCrypt.Net.BCrypt.HashPassword(dto.Password),
                Phone = dto.Phone,
                Address = dto.Address,
                Latitude = dto.Latitude,
                Longitude = dto.Longitude,
                CreatedAt = DateTime.UtcNow
            };

            // Add user to database
            await _unitOfWork.Users.AddAsync(user);

            // Get default 'User' role
            var defaultRole = await _unitOfWork.Roles.FindAsync(r => r.Name == "User");
            if (!defaultRole.Any())
            {
                throw new InvalidOperationException("Default role 'User' not found");
            }

            // Assign default role to user
            var userRole = new UserRole
            {
                UserId = user.Id,
                RoleId = defaultRole.First().Id,
                AssignedAt = DateTime.UtcNow
            };

            await _unitOfWork.UserRoles.AddAsync(userRole);

            // Generate verification code
            var verificationCode = new Random().Next(100000, 999999).ToString();
            var expiresAt = DateTime.UtcNow.AddMinutes(15); // Code expires in 15 minutes

            var emailVerificationCode = new EmailVerificationCode
            {
                Email = user.Email,
                Code = verificationCode,
                ExpiresAt = expiresAt,
                CreatedAt = DateTime.UtcNow,
                IsUsed = false
            };

            await _unitOfWork.EmailVerificationCodes.AddAsync(emailVerificationCode);

            // Commit transaction
            await _unitOfWork.CommitAsync();

            // Return user data (without password)
            return MapUserToDto(user, new[] { "User" });
        }
        catch (Exception)
        {
            await _unitOfWork.RollbackAsync();
            throw;
        }
    }

    public async Task<AuthResponseDto> LoginAsync(LoginDto loginDto)
    {
        // Find user by email
        var user = await _unitOfWork.Users.GetByEmailAsync(loginDto.Email);
        
        // Check if user exists
        if (user == null)
        {
            throw new InvalidOperationException("Invalid email or password");
        }

        // Verify password
        if (!BCrypt.Net.BCrypt.Verify(loginDto.Password, user.PasswordHash))
        {
            throw new InvalidOperationException("Invalid email or password");
        }

        // Check if email is verified
        if (!user.IsEmailVerified)
        {
            throw new InvalidOperationException("Email not verified. Please verify your email before logging in.");
        }

        // Get user roles
        var userRoles = await _unitOfWork.UserRoles
            .FindAsync(ur => ur.UserId == user.Id);
        
        var roleIds = userRoles.Select(ur => ur.RoleId).ToList();
        
        var roles = new List<string>();
        if (roleIds.Any())
        {
            var roleEntities = await _unitOfWork.Roles
                .FindAsync(r => roleIds.Contains(r.Id));
            roles = roleEntities.Select(r => r.Name).ToList();
        }

        // Generate JWT token
        var token = GenerateJwtToken(user, roles);
        
        // Generate refresh token (using same method but with longer expiration)
        var refreshToken = GenerateJwtToken(user, roles);

        // Return auth response with user data and tokens
        return new AuthResponseDto
        {
            User = MapUserToDto(user, roles),
            Token = token.token,
            RefreshToken = refreshToken.token,
            Expiration = token.expiration
        };
    }

    public async Task<AuthResponseDto> LoginWithSessionAsync(LoginRequestDto loginDto, string ipAddress)
    {
        // Find user by email
        var user = await _unitOfWork.Users.GetByEmailAsync(loginDto.Email);
        
        // Check if user exists
        if (user == null)
        {
            throw new InvalidOperationException("Invalid email or password");
        }

        // Verify password
        if (!BCrypt.Net.BCrypt.Verify(loginDto.Password, user.PasswordHash))
        {
            throw new InvalidOperationException("Invalid email or password");
        }

        // Check if email is verified
        if (!user.IsEmailVerified)
        {
            throw new InvalidOperationException("Email not verified. Please verify your email before logging in.");
        }

        // Get user roles
        var userRoles = await _unitOfWork.UserRoles
            .FindAsync(ur => ur.UserId == user.Id);
        
        var roleIds = userRoles.Select(ur => ur.RoleId).ToList();
        
        var roles = new List<string>();
        if (roleIds.Any())
        {
            var roleEntities = await _unitOfWork.Roles
                .FindAsync(r => roleIds.Contains(r.Id));
            roles = roleEntities.Select(r => r.Name).ToList();
        }

        // Generate JWT tokens
        var accessToken = GenerateJwtToken(user, roles);
        var refreshTokenInfo = GenerateRefreshToken(user, roles);

        // Get location from IP
        var location = await _locationService.GetLocationFromIpAsync(ipAddress);

        // Create login session
        var loginSession = new LoginSession
        {
            UserId = user.Id,
            RefreshToken = refreshTokenInfo.token,
            DeviceName = loginDto.DeviceName,
            DeviceType = loginDto.DeviceType,
            UserAgent = loginDto.UserAgent,
            IpAddress = ipAddress,
            Location = location,
            CreatedAt = DateTime.UtcNow,
            ExpiresAt = refreshTokenInfo.expiration,
            LastUsedAt = DateTime.UtcNow,
            IsActive = true
        };

        await _unitOfWork.LoginSessions.AddAsync(loginSession);
        await _unitOfWork.SaveAsync();

        // Return auth response with user data and tokens
        return new AuthResponseDto
        {
            User = MapUserToDto(user, roles),
            Token = accessToken.token,
            RefreshToken = refreshTokenInfo.token,
            Expiration = accessToken.expiration
        };
    }

    private UserResponseDto MapUserToDto(User user, IEnumerable<string> roles)
    {
        return new UserResponseDto
        {
            Id = user.Id,
            FullName = user.FullName,
            Email = user.Email,
            Phone = user.Phone,
            Address = user.Address,
            Latitude = user.Latitude,
            Longitude = user.Longitude,
            Roles = roles.ToList(),
            CreatedAt = user.CreatedAt
        };
    }

    private (string token, DateTime expiration) GenerateJwtToken(User user, IEnumerable<string> roles)
    {
        var jwtSettings = _configuration.GetSection("Jwt");
        var key = Encoding.ASCII.GetBytes(jwtSettings["Key"]!);
        var expirationMinutes = Convert.ToInt32(jwtSettings["ExpiresMinutes"] ?? "120");
        var expiration = DateTime.UtcNow.AddMinutes(expirationMinutes);

        var claims = new List<Claim>
        {
            new Claim(ClaimTypes.NameIdentifier, user.Id.ToString()),
            new Claim(ClaimTypes.Email, user.Email),
            new Claim(ClaimTypes.Name, user.FullName)
        };

        // Add roles to claims
        foreach (var role in roles)
        {
            claims.Add(new Claim(ClaimTypes.Role, role));
        }

        var tokenDescriptor = new SecurityTokenDescriptor
        {
            Subject = new ClaimsIdentity(claims),
            Expires = expiration,
            SigningCredentials = new SigningCredentials(new SymmetricSecurityKey(key), SecurityAlgorithms.HmacSha256Signature),
            Issuer = jwtSettings["Issuer"],
            Audience = jwtSettings["Audience"]
        };

        var tokenHandler = new JwtSecurityTokenHandler();
        var token = tokenHandler.CreateToken(tokenDescriptor);

        return (tokenHandler.WriteToken(token), expiration);
    }

    private (string token, DateTime expiration) GenerateRefreshToken(User user, IEnumerable<string> roles)
    {
        var jwtSettings = _configuration.GetSection("Jwt");
        var key = Encoding.ASCII.GetBytes(jwtSettings["Key"]!);
        
        // Refresh token has longer expiration (30 days)
        var expiration = DateTime.UtcNow.AddDays(30);

        var claims = new List<Claim>
        {
            new Claim(ClaimTypes.NameIdentifier, user.Id.ToString()),
            new Claim(ClaimTypes.Email, user.Email),
            new Claim(ClaimTypes.Name, user.FullName),
            new Claim("token_type", "refresh") // Mark as refresh token
        };

        // Add roles to claims
        foreach (var role in roles)
        {
            claims.Add(new Claim(ClaimTypes.Role, role));
        }

        var tokenDescriptor = new SecurityTokenDescriptor
        {
            Subject = new ClaimsIdentity(claims),
            Expires = expiration,
            SigningCredentials = new SigningCredentials(new SymmetricSecurityKey(key), SecurityAlgorithms.HmacSha256Signature),
            Issuer = jwtSettings["Issuer"],
            Audience = jwtSettings["Audience"]
        };

        var tokenHandler = new JwtSecurityTokenHandler();
        var token = tokenHandler.CreateToken(tokenDescriptor);
        return (tokenHandler.WriteToken(token), expiration);
    }

    public async Task ForgotPasswordAsync(string email, IEmailService emailService)
    {
        // Check if user exists
        var user = await _unitOfWork.Users.GetByEmailAsync(email);
        if (user == null)
        {
            throw new InvalidOperationException("Email not found");
        }

        // Generate 6-digit reset code
        var resetCode = new Random().Next(100000, 999999).ToString();
        var expiresAt = DateTime.UtcNow.AddMinutes(15); // Code expires in 15 minutes

        // Invalidate any existing tokens for this email
        var existingTokens = await _unitOfWork.PasswordResetTokens
            .FindAsync(t => t.Email == email && !t.IsUsed);
        
        foreach (var token in existingTokens)
        {
            token.IsUsed = true;
        }

        // Create new reset token with code
        var passwordResetToken = new PasswordResetToken
        {
            Email = email,
            Token = resetCode, // Store the 6-digit code as token
            ExpiresAt = expiresAt,
            CreatedAt = DateTime.UtcNow,
            IsUsed = false
        };

        await _unitOfWork.PasswordResetTokens.AddAsync(passwordResetToken);
        await _unitOfWork.SaveChangesAsync();

        // Send email with 6-digit code
        await emailService.SendPasswordResetCodeAsync(email, resetCode);
    }

    public async Task VerifyResetCodeAsync(string email, string code)
    {
        // Find valid reset code
        var resetToken = await _unitOfWork.PasswordResetTokens
            .FindAsync(t => t.Token == code && t.Email == email && !t.IsUsed && t.ExpiresAt > DateTime.UtcNow);

        if (!resetToken.Any())
        {
            throw new InvalidOperationException("Invalid or expired reset code");
        }

        // Code is valid, no need to mark as used yet (will be used in reset password)
    }

    public async Task ResetPasswordAsync(string email, string code, string newPassword)
    {
        // Find valid reset code
        var resetToken = await _unitOfWork.PasswordResetTokens
            .FindAsync(t => t.Token == code && t.Email == email && !t.IsUsed && t.ExpiresAt > DateTime.UtcNow);

        if (!resetToken.Any())
        {
            throw new InvalidOperationException("Invalid or expired reset code");
        }

        var tokenEntity = resetToken.First();

        // Find user
        var user = await _unitOfWork.Users.GetByEmailAsync(email);
        if (user == null)
        {
            throw new InvalidOperationException("User not found");
        }

        // Update password
        user.PasswordHash = BCrypt.Net.BCrypt.HashPassword(newPassword);

        // Mark token as used
        tokenEntity.IsUsed = true;

        await _unitOfWork.SaveChangesAsync();
    }

    public async Task VerifyEmailAsync(string email, string code)
    {
        // Find valid verification code
        var verificationCode = await _unitOfWork.EmailVerificationCodes
            .FindAsync(c => c.Email == email && c.Code == code && !c.IsUsed && c.ExpiresAt > DateTime.UtcNow);

        if (!verificationCode.Any())
        {
            throw new InvalidOperationException("Invalid or expired verification code");
        }

        var codeEntity = verificationCode.First();

        // Find user
        var user = await _unitOfWork.Users.GetByEmailAsync(email);
        if (user == null)
        {
            throw new InvalidOperationException("User not found");
        }

        // Mark code as used and verify user email
        codeEntity.IsUsed = true;
        user.IsEmailVerified = true;

        await _unitOfWork.SaveChangesAsync();
    }

    public async Task ResendVerificationCodeAsync(string email, IEmailService emailService)
    {
        // Check if user exists
        var user = await _unitOfWork.Users.GetByEmailAsync(email);
        if (user == null)
        {
            throw new InvalidOperationException("Email not found");
        }

        // Generate verification code
        var verificationCode = new Random().Next(100000, 999999).ToString();
        var expiresAt = DateTime.UtcNow.AddMinutes(15); // Code expires in 15 minutes

        // Invalidate any existing codes for this email
        var existingCodes = await _unitOfWork.EmailVerificationCodes
            .FindAsync(c => c.Email == email && !c.IsUsed);
        
        foreach (var code in existingCodes)
        {
            code.IsUsed = true;
        }

        // Create new verification code
        var emailVerificationCode = new EmailVerificationCode
        {
            Email = email,
            Code = verificationCode,
            ExpiresAt = expiresAt,
            CreatedAt = DateTime.UtcNow,
            IsUsed = false
        };

        await _unitOfWork.EmailVerificationCodes.AddAsync(emailVerificationCode);
        await _unitOfWork.SaveChangesAsync();

        // Send email
        await emailService.SendEmailVerificationAsync(email, verificationCode);
    }

    // Additional methods for Google Auth
    public async Task<UserResponseDto?> GetUserByEmailAsync(string email)
    {
        var user = await _unitOfWork.Users.FindAsync(u => u.Email == email);
        var foundUser = user.FirstOrDefault();
        
        if (foundUser == null) return null;

        var roles = await _unitOfWork.Users.GetUserRolesAsync(foundUser.Id);
        return new UserResponseDto
        {
            Id = foundUser.Id,
            FullName = foundUser.FullName,
            Email = foundUser.Email,
            Phone = foundUser.Phone,
            Address = foundUser.Address,
            Latitude = foundUser.Latitude,
            Longitude = foundUser.Longitude,
            IsEmailVerified = foundUser.IsEmailVerified,
            Roles = roles.ToList(),
            CreatedAt = foundUser.CreatedAt
        };
    }

    public async Task<ApiResponse<UserResponseDto>> RegisterAsync(UserRegistrationDto registrationDto)
    {
        try
        {
            var result = await RegisterUserAsync(registrationDto);
            return ApiResponse<UserResponseDto>.SuccessResponse(result, "User registered successfully");
        }
        catch (Exception ex)
        {
            return ApiResponse<UserResponseDto>.ErrorResponse(ex.Message);
        }
    }

    public string GenerateJwtToken(UserResponseDto user)
    {
        var jwtSettings = _configuration.GetSection("Jwt");
        var key = Encoding.ASCII.GetBytes(jwtSettings["Key"] ?? throw new InvalidOperationException("JWT Key not found"));

        var claims = new List<Claim>
        {
            new(ClaimTypes.NameIdentifier, user.Id.ToString()),
            new(ClaimTypes.Email, user.Email),
            new(ClaimTypes.Name, user.FullName),
        };

        // Add roles
        foreach (var role in user.Roles)
        {
            claims.Add(new Claim(ClaimTypes.Role, role));
        }

        var tokenDescriptor = new SecurityTokenDescriptor
        {
            Subject = new ClaimsIdentity(claims),
            Expires = DateTime.UtcNow.AddDays(7),
            Issuer = jwtSettings["Issuer"],
            Audience = jwtSettings["Audience"],
            SigningCredentials = new SigningCredentials(new SymmetricSecurityKey(key), SecurityAlgorithms.HmacSha256Signature)
        };

        var tokenHandler = new JwtSecurityTokenHandler();
        var token = tokenHandler.CreateToken(tokenDescriptor);
        return tokenHandler.WriteToken(token);
    }

    public async Task<AuthResponseDto> RefreshTokenAsync(string refreshToken)
    {
        try
        {
            // Find the login session with this refresh token
            var loginSession = await _unitOfWork.LoginSessions.GetByRefreshTokenAsync(refreshToken);
            if (loginSession == null)
            {
                throw new UnauthorizedAccessException("Invalid refresh token");
            }

            // Check if session is expired
            if (loginSession.ExpiresAt < DateTime.UtcNow)
            {
                // Remove expired session
                await _unitOfWork.LoginSessions.RevokeSessionAsync(loginSession.Id);
                await _unitOfWork.SaveAsync();
                throw new UnauthorizedAccessException("Refresh token expired");
            }

            // Get user roles
            var userRoles = await _unitOfWork.UserRoles
                .FindAsync(ur => ur.UserId == loginSession.UserId);
            
            var roleIds = userRoles.Select(ur => ur.RoleId).ToList();
            
            var roles = new List<string>();
            if (roleIds.Any())
            {
                var roleEntities = await _unitOfWork.Roles
                    .FindAsync(r => roleIds.Contains(r.Id));
                roles = roleEntities.Select(r => r.Name).ToList();
            }

            // Generate new access token
            var newAccessToken = GenerateJwtToken(loginSession.User, roles);
            var newRefreshTokenInfo = GenerateRefreshToken(loginSession.User, roles);

            // Update the login session with new refresh token
            loginSession.RefreshToken = newRefreshTokenInfo.token;
            loginSession.ExpiresAt = newRefreshTokenInfo.expiration;
            loginSession.LastUsedAt = DateTime.UtcNow;

            await _unitOfWork.LoginSessions.UpdateAsync(loginSession);
            await _unitOfWork.SaveAsync();

            return new AuthResponseDto
            {
                Token = newAccessToken.token,
                RefreshToken = newRefreshTokenInfo.token,
                User = MapUserToDto(loginSession.User, roles),
                Expiration = newAccessToken.expiration
            };
        }
        catch (Exception ex) when (!(ex is UnauthorizedAccessException))
        {
            throw new UnauthorizedAccessException("Token refresh failed");
        }
    }
}
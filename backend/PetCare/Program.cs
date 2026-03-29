using System.Text;
using System.Text.Json;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.EntityFrameworkCore;
// using PetCare.Api.Data; // nếu DbContext ở namespace này
using PetCare.Data;          // KHỚP namespace với AppDbContext.cs
using Microsoft.IdentityModel.Tokens;
using FluentValidation;
using FluentValidation.AspNetCore;
using PetCare.Validators;
using PetCare.DTOs;
using PetCare.Services;
using PetCare.Repositories;
using PetCare.Entities;
using PetCare.Hubs;
using PetCare.Controllers;

var builder = WebApplication.CreateBuilder(args);

// EF Core + MySQL (Pomelo)
builder.Services.AddDbContext<AppDbContext>(opt =>
{
    var cs = builder.Configuration.GetConnectionString("Default");
    opt.UseMySql(cs, ServerVersion.AutoDetect(cs));
});

// Repository layer
builder.Services.AddScoped<IUnitOfWork, UnitOfWork>();
builder.Services.AddScoped<IUserRepository, UserRepository>();
builder.Services.AddScoped<IPetRepository, PetRepository>();
builder.Services.AddScoped(typeof(IRepository<>), typeof(Repository<>));

// Services
builder.Services.AddScoped<IAuthService, AuthService>();
builder.Services.AddScoped<IUserService, UserService>();
builder.Services.AddScoped<IEmailService, EmailService>();
builder.Services.AddScoped<ILocationService, LocationService>();
builder.Services.AddHttpClient<ILocationService, LocationService>();

// HttpClient for ImageProxy
builder.Services.AddHttpClient<ImageProxyController>();

// JWT Authentication
var jwtSettings = builder.Configuration.GetSection("Jwt");
var key = Encoding.ASCII.GetBytes(jwtSettings["Key"] ?? throw new InvalidOperationException("JWT Key not found"));

builder.Services.AddAuthentication(options =>
{
    options.DefaultAuthenticateScheme = JwtBearerDefaults.AuthenticationScheme;
    options.DefaultChallengeScheme = JwtBearerDefaults.AuthenticationScheme;
})
.AddJwtBearer(options =>
{
    options.RequireHttpsMetadata = false; // Set to true in production
    options.SaveToken = true;
    options.TokenValidationParameters = new TokenValidationParameters
    {
        ValidateIssuerSigningKey = true,
        IssuerSigningKey = new SymmetricSecurityKey(key),
        ValidateIssuer = true,
        ValidateAudience = true,
        ValidIssuer = jwtSettings["Issuer"],
        ValidAudience = jwtSettings["Audience"],
        ClockSkew = TimeSpan.Zero
    };
    // Enable JWT via query string for SignalR WebSocket connections
    options.Events = new JwtBearerEvents
    {
        OnMessageReceived = context =>
        {
            var accessToken = context.Request.Query["access_token"]; 
            var path = context.HttpContext.Request.Path;
            if (!string.IsNullOrEmpty(accessToken) && path.StartsWithSegments("/hubs/chat"))
            {
                context.Token = accessToken;
            }
            return Task.CompletedTask;
        }
    };
});

// FluentValidation - MODIFIED: Disable automatic validation
builder.Services.AddFluentValidationAutoValidation(config => 
{
    // Disable automatic validation for async validators
    config.DisableDataAnnotationsValidation = true;
});
builder.Services.AddScoped<IValidator<UserRegistrationDto>, UserRegistrationValidator>();
builder.Services.AddScoped<IValidator<LoginDto>, LoginDtoValidator>();
builder.Services.AddScoped<IValidator<UserUpdateDto>, UserUpdateValidator>();

// Application Services
builder.Services.AddScoped<IAuthService, AuthService>();
builder.Services.AddHostedService<VaccinationReminderService>();

// MVC + Swagger
builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();
builder.Services.AddSignalR();

// CORS
var corsOrigins = builder.Configuration.GetSection("Cors:AllowedOrigins").Get<string[]>() ?? new[] { "http://localhost:5173" };
builder.Services.AddCors(options =>
{
    options.AddDefaultPolicy(policy =>
    {
        policy.WithOrigins(corsOrigins)
              .AllowAnyHeader()
              .AllowAnyMethod()
              .AllowCredentials();
    });
});

// (Tuỳ chọn) Bật log EF chi tiết khi DEV
builder.Logging.ClearProviders();
builder.Logging.AddConsole();

var app = builder.Build();

// Swagger Dev
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

// ⚠️ Nếu bạn test bằng http từ Android emulator/thiết bị, có thể tạm tắt HTTPS redirect ở DEV
app.UseHttpsRedirection();

// Enable CORS
app.UseCors();

// Add authentication middleware
app.UseAuthentication();
app.UseAuthorization();

app.MapControllers();
app.MapHub<ChatHub>("/hubs/chat");

// TỰ ĐỘNG APPLY MIGRATIONS khi khởi động
using (var scope = app.Services.CreateScope())
{
    var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
    try
    {
        await db.Database.MigrateAsync();
        app.Logger.LogInformation("✅ EF Migrate OK. Provider: {Provider}, CanConnect: {CanConnect}",
            db.Database.ProviderName, await db.Database.CanConnectAsync());
    }
    catch (Exception ex)
    {
        app.Logger.LogError(ex, "❌ EF Migrate FAILED. Vui lòng kiểm tra ConnectionStrings:Default, quyền MySQL, hoặc migration.");
        // Gợi ý: có thể throw lại để fail fast
        // throw;
    }
}

app.Run();

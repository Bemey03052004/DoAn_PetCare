using Microsoft.EntityFrameworkCore;
using PetCare.Data;
using PetCare.Entities;

namespace PetCare.Services;

public class VaccinationReminderService : BackgroundService
{
    private readonly IServiceProvider _services;
    private readonly ILogger<VaccinationReminderService> _logger;

    public VaccinationReminderService(IServiceProvider services, ILogger<VaccinationReminderService> logger)
    {
        _services = services;
        _logger = logger;
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        while (!stoppingToken.IsCancellationRequested)
        {
            try
            {
                using var scope = _services.CreateScope();
                var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
                var now = DateTime.UtcNow;
                var upcoming = await db.VaccinationSchedules
                    .Include(v => v.Pet)
                    .ThenInclude(p => p.Owner)
                    .Where(v => !v.IsCompleted && v.ScheduledDate.Date == now.Date)
                    .ToListAsync(stoppingToken);

                foreach (var v in upcoming)
                {
                    if (v.Pet?.Owner == null) continue;
                    var notification = new Notification
                    {
                        UserId = v.Pet.OwnerId,
                        Title = $"Nhắc nhở tiêm phòng cho {v.Pet.Name}",
                        Body = $"Vaccine: {v.VaccineName} vào {v.ScheduledDate:dd/MM/yyyy}",
                        IsRead = false,
                        CreatedAt = DateTime.UtcNow
                    };
                    db.Notifications.Add(notification);
                }
                await db.SaveChangesAsync(stoppingToken);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Vaccination reminder failed");
            }

            await Task.Delay(TimeSpan.FromHours(1), stoppingToken);
        }
    }
}



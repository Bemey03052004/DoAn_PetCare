using System.Text.Json;

namespace PetCare.Services;

public interface ILocationService
{
    Task<string> GetLocationFromIpAsync(string ipAddress);
}

public class LocationService : ILocationService
{
    private readonly HttpClient _httpClient;
    private readonly ILogger<LocationService> _logger;

    public LocationService(HttpClient httpClient, ILogger<LocationService> logger)
    {
        _httpClient = httpClient;
        _logger = logger;
    }

    public async Task<string> GetLocationFromIpAsync(string ipAddress)
    {
        try
        {
            // Skip localhost and private IPs
            if (string.IsNullOrEmpty(ipAddress) || 
                ipAddress == "127.0.0.1" || 
                ipAddress == "::1" || 
                ipAddress.StartsWith("192.168.") ||
                ipAddress.StartsWith("10.") ||
                ipAddress.StartsWith("172."))
            {
                return "Local Network";
            }

            // Use a free IP geolocation service (ip-api.com)
            var response = await _httpClient.GetAsync($"http://ip-api.com/json/{ipAddress}?fields=status,country,regionName,city");
            
            if (response.IsSuccessStatusCode)
            {
                var json = await response.Content.ReadAsStringAsync();
                var locationData = JsonSerializer.Deserialize<JsonElement>(json);
                
                if (locationData.GetProperty("status").GetString() == "success")
                {
                    var city = locationData.TryGetProperty("city", out var cityProp) ? cityProp.GetString() : "";
                    var region = locationData.TryGetProperty("regionName", out var regionProp) ? regionProp.GetString() : "";
                    var country = locationData.TryGetProperty("country", out var countryProp) ? countryProp.GetString() : "";
                    
                    var location = new List<string>();
                    if (!string.IsNullOrEmpty(city)) location.Add(city);
                    if (!string.IsNullOrEmpty(region)) location.Add(region);
                    if (!string.IsNullOrEmpty(country)) location.Add(country);
                    
                    return location.Count > 0 ? string.Join(", ", location) : "Unknown Location";
                }
            }
            
            return "Unknown Location";
        }
        catch (Exception ex)
        {
            _logger.LogWarning(ex, "Failed to get location for IP: {IpAddress}", ipAddress);
            return "Unknown Location";
        }
    }
}

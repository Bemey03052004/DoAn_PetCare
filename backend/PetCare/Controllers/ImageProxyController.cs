using Microsoft.AspNetCore.Mvc;
using System.Net.Http;
using System.Net;

namespace PetCare.Controllers;

[ApiController]
[Route("api/[controller]")]
public class ImageProxyController : ControllerBase
{
    private readonly HttpClient _httpClient;
    private readonly ILogger<ImageProxyController> _logger;

    public ImageProxyController(HttpClient httpClient, ILogger<ImageProxyController> logger)
    {
        _httpClient = httpClient;
        _logger = logger;
    }

    [HttpGet("proxy")]
    public async Task<IActionResult> ProxyImage([FromQuery] string url)
    {
        try
        {
            // Validate URL
            if (string.IsNullOrEmpty(url) || !Uri.TryCreate(url, UriKind.Absolute, out var uri))
            {
                return BadRequest("Invalid URL provided");
            }

            // Security check - only allow HTTP/HTTPS URLs
            if (uri.Scheme != "http" && uri.Scheme != "https")
            {
                return BadRequest("Only HTTP and HTTPS URLs are allowed");
            }

            // Optional: Add domain whitelist for security
            // var allowedDomains = new[] { "cellphones.com.vn", "example.com" }; // Add your trusted domains
            // var host = uri.Host.ToLower();
            // if (!allowedDomains.Any(domain => host.Contains(domain)))
            // {
            //     _logger.LogWarning("Blocked request to untrusted domain: {Host}", host);
            //     return BadRequest("Domain not allowed");
            // }

            // Set user agent to avoid blocking
            _httpClient.DefaultRequestHeaders.UserAgent.ParseAdd("Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36");

            // Fetch the image
            var response = await _httpClient.GetAsync(url);
            
            if (!response.IsSuccessStatusCode)
            {
                _logger.LogWarning("Failed to fetch image from {Url}: {StatusCode}", url, response.StatusCode);
                return NotFound("Image not found or inaccessible");
            }

            var imageBytes = await response.Content.ReadAsByteArrayAsync();
            var contentType = response.Content.Headers.ContentType?.ToString() ?? "image/jpeg";

            // Validate that it's actually an image
            if (!contentType.StartsWith("image/"))
            {
                _logger.LogWarning("URL does not return an image: {ContentType}", contentType);
                return BadRequest("URL does not return an image");
            }

            // Set cache headers
            Response.Headers["Cache-Control"] = "public, max-age=3600"; // Cache for 1 hour
            Response.Headers["Access-Control-Allow-Origin"] = "*";

            return File(imageBytes, contentType);
        }
        catch (HttpRequestException ex)
        {
            _logger.LogError(ex, "HTTP error while fetching image from {Url}", url);
            return BadRequest("Failed to fetch image");
        }
        catch (TaskCanceledException ex)
        {
            _logger.LogError(ex, "Timeout while fetching image from {Url}", url);
            return BadRequest("Request timeout");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Unexpected error while fetching image from {Url}", url);
            return StatusCode(500, "Internal server error");
        }
    }

    [HttpGet("proxy-safe")]
    public async Task<IActionResult> ProxyImageSafe([FromQuery] string url)
    {
        try
        {
            // Validate URL
            if (string.IsNullOrEmpty(url) || !Uri.TryCreate(url, UriKind.Absolute, out var uri))
            {
                return BadRequest("Invalid URL provided");
            }

            // Security check - only allow HTTP/HTTPS URLs
            if (uri.Scheme != "http" && uri.Scheme != "https")
            {
                return BadRequest("Only HTTP and HTTPS URLs are allowed");
            }

            //// More restrictive domain whitelist
            //var allowedDomains = new[] { 
            //    "cellphones.com.vn", 
            //    "example.com",
            //    "localhost",
            //    "127.0.0.1"
            //};
            
            //var host = uri.Host.ToLower();
            //if (!allowedDomains.Any(domain => host.Contains(domain)))
            //{
            //    _logger.LogWarning("Blocked request to untrusted domain: {Host}", host);
            //    return BadRequest("Domain not allowed");
            //}

            // Set timeout
            using var cts = new CancellationTokenSource(TimeSpan.FromSeconds(10));
            
            // Set user agent
            _httpClient.DefaultRequestHeaders.UserAgent.ParseAdd("Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36");

            // Fetch the image with timeout
            var response = await _httpClient.GetAsync(url, cts.Token);
            
            if (!response.IsSuccessStatusCode)
            {
                _logger.LogWarning("Failed to fetch image from {Url}: {StatusCode}", url, response.StatusCode);
                return NotFound("Image not found or inaccessible");
            }

            var imageBytes = await response.Content.ReadAsByteArrayAsync();
            var contentType = response.Content.Headers.ContentType?.ToString() ?? "image/jpeg";

            // Validate content type
            if (!contentType.StartsWith("image/"))
            {
                _logger.LogWarning("URL does not return an image: {ContentType}", contentType);
                return BadRequest("URL does not return an image");
            }

            // Validate file size (max 5MB)
            if (imageBytes.Length > 5 * 1024 * 1024)
            {
                _logger.LogWarning("Image too large: {Size} bytes", imageBytes.Length);
                return BadRequest("Image too large");
            }

            // Set security headers
            Response.Headers["Cache-Control"] = "public, max-age=3600";
            Response.Headers["Access-Control-Allow-Origin"] = "*";
            Response.Headers["X-Content-Type-Options"] = "nosniff";

            return File(imageBytes, contentType);
        }
        catch (OperationCanceledException)
        {
            _logger.LogWarning("Request timeout for URL: {Url}", url);
            return BadRequest("Request timeout");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error while fetching image from {Url}", url);
            return StatusCode(500, "Internal server error");
        }
    }
}

using System.Collections.Concurrent;
using System.Text.Json;
using portfolio_app_slc.Models;

namespace portfolio_app_slc.Services;

// Starts each project's backend waking when a visitor opens the home page, so a scaled-to-zero API and its
// paused database are ready by the time they click through (docs/adr/0009-wake-projects-on-visit.md).
// Calls are fire-and-forget, and each project is woken at most once per WakeInterval however many people
// visit, which keeps a busy page from holding a free database awake all month.
public class WakeService(IHttpClientFactory httpClientFactory, ProjectService projects, ILogger<WakeService> logger)
{
    public static readonly TimeSpan WakeInterval = TimeSpan.FromMinutes(10);
    private static readonly TimeSpan SettingsLifetime = TimeSpan.FromHours(1);

    private readonly ConcurrentDictionary<string, DateTimeOffset> lastWoken = new();
    private readonly ConcurrentDictionary<string, (string ApiBaseUrl, DateTimeOffset ReadAt)> settings = new();

    public void WakeAll()
    {
        foreach (var project in projects.Projects)
        {
            if (project.Wake is null || !ShouldWake(project.Title)) continue;
            _ = Task.Run(() => WakeAsync(project.Title, project.Wake));
        }
    }

    private bool ShouldWake(string key)
    {
        var now = DateTimeOffset.UtcNow;
        var previous = lastWoken.GetOrAdd(key, DateTimeOffset.MinValue);
        return now - previous >= WakeInterval && lastWoken.TryUpdate(key, now, previous);
    }

    private async Task WakeAsync(string title, WakeTarget wake)
    {
        try
        {
            var url = !string.IsNullOrEmpty(wake.Url) ? wake.Url : await ResolveFromSettingsAsync(wake);
            if (string.IsNullOrEmpty(url)) return;

            // A cold start that also resumes a paused database can take most of a minute.
            using var client = httpClientFactory.CreateClient();
            client.Timeout = TimeSpan.FromSeconds(90);
            using var response = await client.GetAsync(url);
            logger.LogInformation("Woke {Project}: {Url} answered {Status}", title, url, (int)response.StatusCode);
        }
        catch (Exception ex)
        {
            logger.LogWarning(ex, "Couldn't wake {Project}", title);
        }
    }

    private async Task<string?> ResolveFromSettingsAsync(WakeTarget wake)
    {
        if (string.IsNullOrEmpty(wake.SettingsUrl)) return null;
        if (settings.TryGetValue(wake.SettingsUrl, out var cached) && DateTimeOffset.UtcNow - cached.ReadAt < SettingsLifetime)
        {
            return Combine(cached.ApiBaseUrl, wake.Path);
        }

        using var client = httpClientFactory.CreateClient();
        client.Timeout = TimeSpan.FromSeconds(15);
        using var document = JsonDocument.Parse(await client.GetStringAsync(wake.SettingsUrl));
        var apiBaseUrl = document.RootElement.TryGetProperty("ApiBaseUrl", out var value) ? value.GetString() : null;
        if (string.IsNullOrEmpty(apiBaseUrl))
        {
            logger.LogWarning("{SettingsUrl} has no ApiBaseUrl", wake.SettingsUrl);
            return null;
        }
        settings[wake.SettingsUrl] = (apiBaseUrl, DateTimeOffset.UtcNow);
        return Combine(apiBaseUrl, wake.Path);
    }

    private static string Combine(string baseUrl, string path) => baseUrl.TrimEnd('/') + "/" + path.TrimStart('/');
}

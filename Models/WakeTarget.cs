namespace portfolio_app_slc.Models;

// How the home page wakes a project's backend when a visitor arrives (docs/adr/0009-wake-projects-on-visit.md).
// Set Url to a health check to call, or, for a Blazor WebAssembly front end whose API address changes,
// SettingsUrl to its published appsettings file: the API address is read from its "ApiBaseUrl" and Path
// is called on it.
public class WakeTarget
{
    public string Url { get; set; } = string.Empty;
    public string SettingsUrl { get; set; } = string.Empty;
    public string Path { get; set; } = "/health/ready";
}

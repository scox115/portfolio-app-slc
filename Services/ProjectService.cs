using System.Text.Json;
using portfolio_app_slc.Models;

namespace portfolio_app_slc.Services;

// Loads the Project Showcase from wwwroot/data/projects.json once at startup.
public class ProjectService
{
    public IReadOnlyList<Project> Projects { get; }

    public ProjectService(IWebHostEnvironment env)
    {
        var file = env.WebRootFileProvider.GetFileInfo("data/projects.json");
        using var stream = file.CreateReadStream();
        Projects = JsonSerializer.Deserialize<List<Project>>(stream, new JsonSerializerOptions(JsonSerializerDefaults.Web)) ?? [];
    }
}

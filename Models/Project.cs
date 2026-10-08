namespace portfolio_app_slc.Models;

public class Project
{
    public string Title { get; set; } = string.Empty;
    public string Description { get; set; } = string.Empty;
    public string Type { get; set; } = string.Empty;
    public string[] Tags { get; set; } = [];
    public string GitHubUrl { get; set; } = string.Empty;
    public string LiveUrl { get; set; } = string.Empty;
    // Optional screenshot, a path under wwwroot such as "images/projects/my-app.png".
    public string ImageUrl { get; set; } = string.Empty;
}

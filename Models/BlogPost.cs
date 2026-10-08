namespace portfolio_app_slc.Models;

public class BlogPost
{
    // The file name without ".md", used in the URL: /blog/{Slug}.
    public string Slug { get; init; } = string.Empty;
    public string Title { get; init; } = string.Empty;
    public DateOnly Date { get; init; }
    // One or two sentences shown on the Blog page and in link previews.
    public string Summary { get; init; } = string.Empty;
    public string[] Tags { get; init; } = [];
    public string Html { get; init; } = string.Empty;
}

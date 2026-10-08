using System.Globalization;
using Markdig;
using portfolio_app_slc.Models;

namespace portfolio_app_slc.Services;

// Loads the blog posts from wwwroot/data/blog/*.md once, newest first.
// Each file starts with a front matter block of "key: value" lines between "---" lines.
public class BlogService
{
    private static readonly MarkdownPipeline Pipeline = new MarkdownPipelineBuilder()
        .UseAdvancedExtensions()
        .DisableHtml()
        .Build();

    public IReadOnlyList<BlogPost> Posts { get; }

    public BlogService(IWebHostEnvironment env, ILogger<BlogService> logger)
    {
        var posts = new List<BlogPost>();
        foreach (var file in env.WebRootFileProvider.GetDirectoryContents("data/blog"))
        {
            if (file.IsDirectory || !file.Name.EndsWith(".md", StringComparison.OrdinalIgnoreCase))
                continue;

            using var reader = new StreamReader(file.CreateReadStream());
            var post = Parse(Path.GetFileNameWithoutExtension(file.Name), reader.ReadToEnd());
            if (post is null)
                logger.LogWarning("Skipped blog post {File}: its front matter needs a 'date: yyyy-MM-dd' line.", file.Name);
            else
                posts.Add(post);
        }

        Posts = posts
            .OrderByDescending(p => p.Date)
            .ThenBy(p => p.Slug)
            .ToList();
    }

    public BlogPost? Find(string slug) =>
        Posts.FirstOrDefault(p => string.Equals(p.Slug, slug, StringComparison.OrdinalIgnoreCase));

    // Returns null when the post has no valid date, so one bad file can't take the blog down.
    private static BlogPost? Parse(string slug, string text)
    {
        var lines = text.Replace("\r\n", "\n").Split('\n');
        var fields = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase);
        var bodyStart = 0;

        if (lines.Length > 0 && lines[0].Trim() == "---")
        {
            var end = Array.FindIndex(lines, 1, l => l.Trim() == "---");
            if (end < 0)
                return null;
            foreach (var line in lines[1..end])
            {
                var colon = line.IndexOf(':');
                if (colon > 0)
                    fields[line[..colon].Trim()] = line[(colon + 1)..].Trim();
            }
            bodyStart = end + 1;
        }

        if (!fields.TryGetValue("date", out var date) ||
            !DateOnly.TryParseExact(date, "yyyy-MM-dd", CultureInfo.InvariantCulture, DateTimeStyles.None, out var parsedDate))
            return null;

        var body = string.Join('\n', lines[bodyStart..]);
        var words = body.Split((char[]?)null, StringSplitOptions.RemoveEmptyEntries).Length;

        return new BlogPost
        {
            Slug = slug,
            Title = fields.GetValueOrDefault("title") ?? slug,
            Date = parsedDate,
            Summary = fields.GetValueOrDefault("summary") ?? string.Empty,
            Tags = (fields.GetValueOrDefault("tags") ?? string.Empty)
                .Split(',', StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries),
            Image = fields.GetValueOrDefault("image") ?? string.Empty,
            ImageAlt = fields.GetValueOrDefault("imageAlt") ?? string.Empty,
            ReadingMinutes = Math.Max(1, (int)Math.Round(words / 200.0)),
            Html = Markdown.ToHtml(body, Pipeline),
        };
    }
}

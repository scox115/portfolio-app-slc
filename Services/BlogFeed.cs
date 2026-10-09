using System.Globalization;
using System.Xml.Linq;

namespace portfolio_app_slc.Services;

// Serves the blog as an RSS 2.0 feed at /blog/feed.xml, so feed readers can follow new posts.
// It lists the same posts as the Blog page, so a scheduled post joins the feed on its date.
public static class BlogFeed
{
    public const string Path = "/blog/feed.xml";

    private static readonly XNamespace Atom = "http://www.w3.org/2005/Atom";
    private static readonly XNamespace Content = "http://purl.org/rss/1.0/modules/content/";

    public static IEndpointRouteBuilder MapBlogFeed(this IEndpointRouteBuilder endpoints)
    {
        endpoints.MapGet(Path, (HttpRequest request, BlogService blog) =>
        {
            var site = $"{request.Scheme}://{request.Host}";
            var xml = Build(site, blog.Posts);
            return Results.Text(xml.Declaration + Environment.NewLine + xml, "application/rss+xml; charset=utf-8");
        });
        return endpoints;
    }

    public static XDocument Build(string site, IReadOnlyList<Models.BlogPost> posts)
    {
        var channel = new XElement("channel",
            new XElement("title", "Human in the Loop | Scott Cox"),
            new XElement("link", $"{site}/blog"),
            new XElement("description", "What I'm building with AI coding tools, what they get wrong, and what I'm learning on the job search."),
            new XElement("language", "en-us"),
            new XElement(Atom + "link",
                new XAttribute("href", site + Path),
                new XAttribute("rel", "self"),
                new XAttribute("type", "application/rss+xml")));

        if (posts.Count > 0)
            channel.Add(new XElement("lastBuildDate", Rfc822(posts.Max(BlogService.PublishedAt))));

        foreach (var post in posts)
        {
            var url = $"{site}/blog/{post.Slug}";
            var item = new XElement("item",
                new XElement("title", post.Title),
                new XElement("link", url),
                new XElement("guid", new XAttribute("isPermaLink", "true"), url),
                new XElement("pubDate", Rfc822(BlogService.PublishedAt(post))),
                new XElement("description", post.Summary),
                post.Tags.Select(tag => new XElement("category", tag)),
                new XElement(Content + "encoded", new XCData(Absolute(post.Html, site))));
            channel.Add(item);
        }

        return new XDocument(
            new XDeclaration("1.0", "utf-8", null),
            new XElement("rss",
                new XAttribute("version", "2.0"),
                new XAttribute(XNamespace.Xmlns + "atom", Atom),
                new XAttribute(XNamespace.Xmlns + "content", Content),
                channel));
    }

    // Feed readers show posts away from the site, so site-relative links and images need the host.
    private static string Absolute(string html, string site) =>
        html.Replace("href=\"/", $"href=\"{site}/").Replace("src=\"/", $"src=\"{site}/");

    private static string Rfc822(DateTimeOffset when) =>
        when.ToUniversalTime().ToString("ddd, dd MMM yyyy HH:mm:ss 'GMT'", CultureInfo.InvariantCulture);
}

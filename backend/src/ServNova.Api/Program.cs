var builder = WebApplication.CreateBuilder(args);

var app = builder.Build();

app.Run();

// Makes the entry point visible to WebApplicationFactory<Program> in the tests.
public partial class Program;

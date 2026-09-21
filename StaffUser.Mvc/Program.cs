using BLL;
using BLL.DTOs.Customer;
using BLL.Services.Interfaces;
using BLL.Settings;
using DAL.Enums;
using Microsoft.AspNetCore.Authentication.Cookies;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Localization;
using Microsoft.AspNetCore.Mvc.Authorization;
using System.Globalization;

var builder = WebApplication.CreateBuilder(args);

// Add services to the container. Add authorization policy to require authentication for all controllers by default
builder.Services.AddControllersWithViews( options =>
{
    var policy = new AuthorizationPolicyBuilder()
        .RequireAuthenticatedUser()
        .RequireRole("Customer")
        .Build();   
    options.Filters.Add(new AuthorizeFilter(policy));
});
builder.Services.AddSession();

// Cookie authentication for users
builder.Services.AddAuthentication(CookieAuthenticationDefaults.AuthenticationScheme)
    .AddCookie(options =>
    {
        options.LoginPath = "/Auth/Login";
        options.LogoutPath = "/Auth/Logout";
        options.ExpireTimeSpan = TimeSpan.FromDays(7);
        options.SlidingExpiration = true;
    });

// lấy connection string từ appsettings.json
var connectionString = builder.Configuration.GetConnectionString("DefaultConnection");

// Add business logic layer services
builder.Services.AddBusinessLogicLayer(connectionString!);
builder.Services.Configure<VnpaySettings>(builder.Configuration.GetSection("VNPAY"));

var app = builder.Build();

// Configure the HTTP request pipeline.
if (!app.Environment.IsDevelopment())
{
    app.UseExceptionHandler("/Home/Error");
    // The default HSTS value is 30 days. You may want to change this for production scenarios, see https://aka.ms/aspnetcore-hsts.
    app.UseHsts();
}

app.UseHttpsRedirection();

var sharedUploadsFolder = Path.GetFullPath(Path.Combine(app.Environment.ContentRootPath, "..", "shared-uploads"));
if (!Directory.Exists(sharedUploadsFolder))
{
    Directory.CreateDirectory(sharedUploadsFolder);
}

app.UseStaticFiles(new StaticFileOptions
{
    FileProvider = new Microsoft.Extensions.FileProviders.PhysicalFileProvider(sharedUploadsFolder),
    RequestPath = "/uploads"
});

app.UseRouting();

app.UseSession();
app.UseAuthentication();
app.UseAuthorization();

app.MapStaticAssets();

// Set the default culture to Vietnamese (Vietnam)
var supportedCultures = new[] { new CultureInfo("vi-VN") };
app.UseRequestLocalization(new RequestLocalizationOptions
{
    DefaultRequestCulture = new RequestCulture("vi-VN"),
    SupportedCultures = supportedCultures,
    SupportedUICultures = supportedCultures
});

app.MapControllerRoute(
    name: "default",
    pattern: "{controller=Home}/{action=Index}/{id?}")
    .WithStaticAssets();

app.Run();

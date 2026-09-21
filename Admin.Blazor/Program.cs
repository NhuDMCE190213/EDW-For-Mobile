using Admin.Blazor.Components;
using Admin.Blazor.Components.Auth;
using Admin.Blazor.Hubs;
using BLL;
using BLL.DTOs.Validators.PromotionValidator;
using BLL.Settings;
using DAL.Data;
using FluentValidation;
using Microsoft.AspNetCore.Authentication.Cookies;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Components.Authorization;
using Microsoft.EntityFrameworkCore;

var builder = WebApplication.CreateBuilder(args);

// Lấy connection string từ appsettings.json
var connectionString = builder.Configuration.GetConnectionString("DefaultConnection");

// Add services to the container.
builder.Services.AddRazorComponents()
    .AddInteractiveServerComponents();

builder.Services.AddValidatorsFromAssemblyContaining<PromotionCreateDtoValidator>();

builder.Services.AddRazorPages();
builder.Services.AddSignalR();
builder.Services.AddBusinessLogicLayer(connectionString!);
builder.Services.Configure<VnpaySettings>(builder.Configuration.GetSection("VNPAY"));

// Add authentication
builder.Services.AddAuthentication(CookieAuthenticationDefaults.AuthenticationScheme)
    .AddCookie(CookieAuthenticationDefaults.AuthenticationScheme, options =>
    {
        options.LoginPath = "/auth/login";
        options.LogoutPath = "/auth/logout";
        options.Cookie.SameSite = SameSiteMode.Strict; // Đặt SameSite để tăng cường bảo mật
    });

builder.Services.AddAuthorization();
builder.Services.AddHttpContextAccessor();
builder.Services.AddScoped<StaffAuthenticationStateProvider>();
builder.Services.AddScoped<AuthenticationStateProvider>(sp => sp.GetRequiredService<StaffAuthenticationStateProvider>());

builder.Services.AddCascadingAuthenticationState(); // Đăng ký dịch vụ CascadingAuthenticationState

var app = builder.Build();

// --- ĐÃ SỬA: Chuyển Seed Data sang Async hoàn toàn ---
using (var scope = app.Services.CreateScope())
{
    var db = scope.ServiceProvider.GetRequiredService<DAL.Data.AppDbContext>();
    await db.Database.MigrateAsync();
    db.EnsureSeedData();

    if (!await db.Staffs.AnyAsync(s => s.Email == "admin@electronexus.com"))
    {
        var adminPassword = BCrypt.Net.BCrypt.HashPassword("Admin@123");
        var admin = new DAL.Models.Staff
        {
            FullName = "Administrator",
            Email = "admin@electronexus.com",
            PasswordHash = adminPassword,
            Role = DAL.Enums.RoleEnum.Admin,
            IsActive = true,
            IsDeleted = false,
            CreatedAt = DateTime.UtcNow
        };
        await db.Staffs.AddAsync(admin);
        await db.SaveChangesAsync();
    }
}

// Configure the HTTP request pipeline.
if (!app.Environment.IsDevelopment())
{
    app.UseExceptionHandler("/Error", createScopeForErrors: true);
    app.UseHsts();
}

app.UseHttpsRedirection();

// --- ĐY ĐƯỢC CHUẨN HÓA VỀ THỨ TỰ MIDDLEWARE ---
app.UseAntiforgery();
app.MapStaticAssets(); // Tối ưu hóa file tĩnh hệ thống của .NET 9

app.UseAuthentication();
app.UseAuthorization();

// --- ĐÃ SỬA: Đặt StaticFiles của upload sau Auth để tránh lộ dữ liệu bừa bãi ---
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

app.MapHub<AdminHub>("/adminHub");
app.MapRazorPages();
app.MapRazorComponents<App>()
   .AddInteractiveServerRenderMode();

await app.RunAsync(); // Đã chuyển sang Async

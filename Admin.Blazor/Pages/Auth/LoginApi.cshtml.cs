using BLL.Services.Interfaces;
using Microsoft.AspNetCore.Authentication;
using Microsoft.AspNetCore.Authentication.Cookies;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using System.Security.Claims;

namespace Admin.Blazor.Pages.Auth
{
    // Admin.Blazor/Pages/Auth/LoginApi.cshtml.cs
    [IgnoreAntiforgeryToken]
    public class LoginApi : PageModel
    {
        private readonly IStaffService _staffService;
        public LoginApi(IStaffService staffService) => _staffService = staffService;

        public async Task<IActionResult> OnPostAsync(string email, string password)
        {
            var staff = await _staffService.ValidateLoginAsync(email, password);
            if (staff == null)
                return LocalRedirect("/auth/login");

            var claims = new List<Claim>
        {
            new(ClaimTypes.NameIdentifier, staff.StaffId.ToString()),
            new(ClaimTypes.Name, staff.FullName),
            new(ClaimTypes.Email, staff.Email),
            new(ClaimTypes.Role, staff.Role.ToString())
        };

            var identity = new ClaimsIdentity(claims, CookieAuthenticationDefaults.AuthenticationScheme);
            var principal = new ClaimsPrincipal(identity);

            await HttpContext.SignInAsync(CookieAuthenticationDefaults.AuthenticationScheme, principal);
            return LocalRedirect("/");
        }
    }
}
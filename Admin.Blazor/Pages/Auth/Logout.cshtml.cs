using Microsoft.AspNetCore.Authentication;
using Microsoft.AspNetCore.Authentication.Cookies;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;

namespace Admin.Blazor.Pages.Auth
{
    // Admin.Blazor/Pages/Auth/Logout.cshtml.cs
    [IgnoreAntiforgeryToken]
    public class Logout : PageModel
    {
        public async Task<IActionResult> OnGetAsync()
        {
            await HttpContext.SignOutAsync(CookieAuthenticationDefaults.AuthenticationScheme);
            return LocalRedirect("/auth/login");
        }
    }
}
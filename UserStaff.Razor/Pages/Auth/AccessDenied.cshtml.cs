using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc.RazorPages;

namespace Staff.Razor.Pages.Auth
{
    [AllowAnonymous]
    public class AccessDeniedModel : PageModel
    {
        public void OnGet() { }
    }
}
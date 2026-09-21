using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc.RazorPages;

namespace Staff.Razor.Pages.Products
{
    [Authorize]
    public class UpdateModel : PageModel
    {
        public void OnGet()
        {
        }
    }
}

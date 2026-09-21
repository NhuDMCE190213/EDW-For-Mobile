using BLL.Services.Interfaces;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using System.ComponentModel.DataAnnotations;

namespace Staff.Razor.Pages.Auth
{
    public class SetNewPasswordModel : PageModel
    {
        private readonly IStaffService _staffService;

        public SetNewPasswordModel(IStaffService staffService)
        {
            _staffService = staffService;
        }

        [BindProperty]
        public string Email { get; set; } = string.Empty;

        [BindProperty]
        [StringLength(100, MinimumLength = 8, ErrorMessage = "Password must be at least 8 characters.")]
        [RegularExpression(@"^(?=.*[a-zA-Z])(?=.*\d)(?=.*[!@#$%^&*()_+\-=\[\]{};':""\\|,.<>\/?]).+$", 
            ErrorMessage = "Password must contain at least one letter, one number, and one special character.")]
        public string Password { get; set; } = string.Empty;

        [BindProperty]
        [Compare("Password", ErrorMessage = "Passwords do not match.")]
        public string ConfirmPassword { get; set; } = string.Empty;

        public void OnGet(string? email)
        {
            if (!string.IsNullOrWhiteSpace(email))
            {
                Email = email;
            }
        }

        public async Task<IActionResult> OnPostAsync()
        {
            if (string.IsNullOrWhiteSpace(Email)) return RedirectToPage("ForgotPassword");

            if (!ModelState.IsValid)
            {
                return Page();
            }

            // Find staff and set new password (BLL will hash internally)
            var staff = await _staffService.GetByEmailAsync(Email);
            if (staff == null)
            {
                return RedirectToPage("/Auth/Login");
            }

            await _staffService.SetPasswordAsync(staff.StaffId, Password);
            return RedirectToPage("/Auth/Login");
        }
    }
}

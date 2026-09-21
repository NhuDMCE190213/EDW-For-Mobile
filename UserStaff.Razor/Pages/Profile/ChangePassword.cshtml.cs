using BLL.DTOs.Staff;
using BLL.Services.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using System.Security.Claims;

namespace Staff.Razor.Pages.Profile
{
    [Authorize]
    public class ChangePasswordModel : PageModel
    {
        private readonly IStaffService _staffService;

        public ChangePasswordModel(IStaffService staffService)
        {
            _staffService = staffService;
        }

        [BindProperty]
        public StaffChangePasswordDto Input { get; set; } = default!;

        public IActionResult OnGet()
        {
            return Page();
        }

        public async Task<IActionResult> OnPostAsync()
        {
            var email = User.FindFirst(ClaimTypes.Email)?.Value;
            if (string.IsNullOrEmpty(email))
            {
                return RedirectToPage("/Auth/Login");
            }

            var staff = await _staffService.GetByEmailAsync(email);
            if (staff == null)
            {
                return RedirectToPage("/Auth/Login");
            }

            if (!ModelState.IsValid)
            {
                return Page();
            }

            await _staffService.SetPasswordAsync(staff.StaffId, Input.NewPassword);
            TempData["SuccessMessage"] = "Password changed successfully.";
            return RedirectToPage("Index");
        }
    }
}
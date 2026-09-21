using BLL.DTOs.Staff;
using BLL.Services.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using System.Security.Claims;

namespace Staff.Razor.Pages.Profile
{
    [Authorize]
    public class IndexModel : PageModel
    {
        private readonly IStaffService _staffService;

        public IndexModel(IStaffService staffService)
        {
            _staffService = staffService;
        }

        [BindProperty]
        public StaffProfileDto Input { get; set; } = default!;

        public async Task<IActionResult> OnGetAsync()
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

            Input = new StaffProfileDto
            {
                StaffId = staff.StaffId,
                Email = staff.Email,
                FullName = staff.FullName,
                IsActive = staff.IsActive,
                CreatedAt = staff.CreatedAt,
                UpdatedAt = staff.UpdatedAt
            };

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
                Input.Email = staff.Email;
                Input.IsActive = staff.IsActive;
                return Page();
            }

            var profileDto = new StaffProfileDto
            {
                StaffId = staff.StaffId,
                FullName = Input.FullName,
                Email = staff.Email,
                IsActive = staff.IsActive,
                CreatedAt = staff.CreatedAt,
                UpdatedAt = staff.UpdatedAt
            };

            await _staffService.UpdateProfileAsync(staff.StaffId, profileDto);
            TempData["SuccessMessage"] = "Profile updated successfully.";
            return RedirectToPage();
        }
    }
}
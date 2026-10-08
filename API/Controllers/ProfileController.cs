using BLL.DTOs.Customer;
using BLL.DTOs.Staff;
using BLL.Services.Interfaces;
using DAL.Enums;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Security.Claims;

namespace API.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    [Authorize] // Allows all authenticated users (Customer, Staff, Admin)
    public class ProfileController : ControllerBase
    {
        private readonly ICustomerService _customerService;
        private readonly IStaffService _staffService;

        public ProfileController(ICustomerService customerService, IStaffService staffService)
        {
            _customerService = customerService;
            _staffService = staffService;
        }

        private (int UserId, bool IsCustomer) GetCurrentUser()
        {
            var userIdClaim = User.FindFirstValue(ClaimTypes.NameIdentifier);
            if (string.IsNullOrEmpty(userIdClaim) || !int.TryParse(userIdClaim, out int userId))
            {
                throw new UnauthorizedAccessException("Invalid or missing user identity claim.");
            }
            
            bool isCustomer = User.IsInRole(RoleEnum.Customer.ToString());
            return (userId, isCustomer);
        }

        // ══════════════════════════════════════════════════════════════════════════
        // UC-05.1 – View Profile
        // ══════════════════════════════════════════════════════════════════════════

        /// <summary>
        /// Retrieves the profile information of the currently authenticated user (Customer/Staff/Admin) (UC-05.1).
        /// </summary>
        [HttpGet]
        public async Task<IActionResult> ViewProfile()
        {
            try
            {
                var (userId, isCustomer) = GetCurrentUser();

                if (isCustomer)
                {
                    var profile = await _customerService.GetProfileAsync(userId);
                    if (profile == null) return NotFound(new { message = "Customer profile not found." });
                    return Ok(profile);
                }
                else
                {
                    var profile = await _staffService.GetProfileAsync(userId);
                    if (profile == null) return NotFound(new { message = "Staff profile not found." });
                    return Ok(profile);
                }
            }
            catch (UnauthorizedAccessException ex)
            {
                return Unauthorized(new { message = ex.Message });
            }
        }

        // ══════════════════════════════════════════════════════════════════════════
        // UC-05.2 – Edit Profile
        // ══════════════════════════════════════════════════════════════════════════

        /// <summary>
        /// Updates the profile information of the currently authenticated user (UC-05.2).
        /// </summary>
        [HttpPut]
        public async Task<IActionResult> EditProfile([FromBody] CustomerUpdateProfileDto dto)
        {
            if (!ModelState.IsValid) return BadRequest(ModelState);

            try
            {
                var (userId, isCustomer) = GetCurrentUser();

                if (isCustomer)
                {
                    var profileDto = new CustomerProfileDto
                    {
                        FullName = dto.FullName,
                        PhoneNumber = dto.PhoneNumber
                    };
                    bool success = await _customerService.UpdateProfileAsync(userId, profileDto);
                    if (!success) return BadRequest(new { message = "Failed to update profile." });
                }
                else
                {
                    var staffProfile = await _staffService.GetProfileAsync(userId);
                    if (staffProfile == null) return NotFound();
                    
                    staffProfile.FullName = dto.FullName; // Staff doesn't have phone number
                    bool success = await _staffService.UpdateProfileAsync(userId, staffProfile);
                    if (!success) return BadRequest(new { message = "Failed to update profile." });
                }

                return Ok(new { message = "Profile updated successfully." });
            }
            catch (UnauthorizedAccessException ex)
            {
                return Unauthorized(new { message = ex.Message });
            }
        }

        // ══════════════════════════════════════════════════════════════════════════
        // UC-05.3 – Change Password
        // ══════════════════════════════════════════════════════════════════════════

        /// <summary>
        /// Changes the password of the currently authenticated user (UC-05.3).
        /// </summary>
        [HttpPut("password")]
        public async Task<IActionResult> ChangePassword([FromBody] CustomerChangePasswordDto dto)
        {
            if (!ModelState.IsValid) return BadRequest(ModelState);

            try
            {
                var (userId, isCustomer) = GetCurrentUser();
                bool success = false;

                if (isCustomer)
                {
                    success = await _customerService.SetPasswordAsync(userId, dto.NewPassword);
                }
                else
                {
                    success = await _staffService.SetPasswordAsync(userId, dto.NewPassword);
                }

                if (!success)
                    return StatusCode(500, new { message = "Failed to update password." });

                return Ok(new { message = "Password updated successfully." });
            }
            catch (UnauthorizedAccessException ex)
            {
                return Unauthorized(new { message = ex.Message });
            }
        }
    }
}

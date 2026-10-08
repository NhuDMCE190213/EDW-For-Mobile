using BLL.DTOs.Auth;
using BLL.DTOs.Customer;
using BLL.Services.Interfaces;
using DAL.Enums;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace API.Controllers
{
    /// <summary>
    /// Handles authentication for both Customer (UC-01.1) and Staff (UC-01.2) actors,
    /// Registration (UC-03), as well as Logout for all authenticated roles (UC-02).
    ///
    /// Authentication scheme: JWT Bearer (cookie auth is used by MVC/Razor frontends;
    /// this API uses JWT so that Flutter mobile clients and other consumers can authenticate).
    ///
    /// Business rules applied
    /// ───────────────────────
    /// BR-01 / FR-01: password verification via BCrypt is done inside ICustomerService /
    ///                IStaffService before this controller receives the result — the
    ///                controller never touches raw or hashed passwords.
    /// FR-01 (UC-02): JWT logout is stateless; the client is instructed to discard the token.
    ///                For truly server-side revocation a token blacklist (Redis / DB) should
    ///                be added in a future iteration.
    /// FR-01 (UC-03): Unique Email validation on customer registration.
    /// </summary>
    [Route("api/auth")]
    [ApiController]
    public class AuthController : ControllerBase
    {
        private readonly ICustomerService _customerService;
        private readonly IStaffService    _staffService;
        private readonly IJwtService      _jwtService;

        public AuthController(
            ICustomerService customerService,
            IStaffService    staffService,
            IJwtService      jwtService)
        {
            _customerService = customerService;
            _staffService    = staffService;
            _jwtService      = jwtService;
        }

        // ══════════════════════════════════════════════════════════════════════════
        // UC-01.1 – Login for Customer
        // ══════════════════════════════════════════════════════════════════════════

        /// <summary>
        /// Authenticates a guest as a Customer and returns a JWT bearer token.
        /// </summary>
        /// <remarks>
        /// Normal flow (01.1.1 → 01.1.5):
        ///   1. Guest sends email + password (+ optional rememberMe flag).
        ///   2. BLL validates credentials via BCrypt (BR-01).
        ///   3. JWT is generated and returned.
        ///   4. Client stores the token and includes it as "Authorization: Bearer {token}"
        ///      on subsequent requests.
        ///
        /// Alternative flow (01.1.1): RememberMe = true → token lifetime extended to 30 days.
        ///
        /// Exception (01.1.0.E1): Invalid credentials → 401 Unauthorized with error message.
        /// </remarks>
        [AllowAnonymous]
        [HttpPost("customer/login")]
        public async Task<ActionResult<LoginResponseDto>> CustomerLogin([FromBody] LoginDto dto)
        {
            // 01.1.2: Validate request shape
            if (!ModelState.IsValid)
                return BadRequest(ModelState);

            // 01.1.3: BLL validates credentials (BCrypt.Verify inside service — BR-01)
            var customer = await _customerService.ValidateLoginAsync(dto.Email, dto.Password);

            // Exception 01.1.0.E1
            if (customer is null)
                return Unauthorized(new { message = "Invalid email or password." });

            // 01.1.4: Generate JWT (session equivalent for stateless API)
            var response = _jwtService.GenerateToken(
                userId:     customer.CustomerId,
                email:      customer.Email,
                fullName:   customer.FullName,
                role:       RoleEnum.Customer.ToString(),
                rememberMe: dto.RememberMe);

            response.Role = RoleEnum.Customer;

            // 01.1.5: Return token to client → client redirects to Home
            return Ok(response);
        }

        // ══════════════════════════════════════════════════════════════════════════
        // UC-03 – Register for Customer
        // ══════════════════════════════════════════════════════════════════════════

        /// <summary>
        /// Registers a new Guest as a Customer account (UC-03).
        /// </summary>
        /// <remarks>
        /// Normal flow (03.1 → 03.5):
        ///   1. Guest sends Full Name, Email, Phone Number, and Password.
        ///   2. System checks for duplicate email (FR-01 Unique Email).
        ///   3. If valid, hashes password via BCrypt and creates account in DB (POST-1).
        ///   4. Returns 200 OK / 201 Created with created customer details.
        ///
        /// Exception (03.0.E1): Email already registered -> 400 Bad Request with error message.
        /// </remarks>
        [AllowAnonymous]
        [HttpPost("customer/register")]
        public async Task<ActionResult<CustomerDto>> CustomerRegister([FromBody] CustomerRegisterDto dto)
        {
            // 03.2: Validate request body
            if (!ModelState.IsValid)
                return BadRequest(ModelState);

            try
            {
                // 03.3 & 03.4: Validate duplicate email and create customer account
                var customer = await _customerService.RegisterAsync(dto);
                return Ok(customer);
            }
            catch (InvalidOperationException ex)
            {
                // Exception 03.0.E1: Email already registered
                return BadRequest(new { message = ex.Message });
            }
        }

        // ══════════════════════════════════════════════════════════════════════════
        // UC-04 – Forget Password
        // ══════════════════════════════════════════════════════════════════════════

        /// <summary>
        /// Verifies if the email exists for the Forgot Password flow (UC-04.1 → 04.2).
        /// </summary>
        [AllowAnonymous]
        [HttpPost("customer/verify-email")]
        public async Task<IActionResult> CustomerVerifyEmail([FromBody] VerifyEmailDto dto)
        {
            if (!ModelState.IsValid) return BadRequest(ModelState);

            var customer = await _customerService.GetByEmailAsync(dto.Email);
            if (customer == null)
            {
                // Exception 04.0.E1: Email not found
                return NotFound(new { message = "Email not found." });
            }

            return Ok(new { message = "Email verified. Proceed to reset password." });
        }

        /// <summary>
        /// Resets the customer's password (UC-04.4 → 04.5).
        /// </summary>
        [AllowAnonymous]
        [HttpPost("customer/reset-password")]
        public async Task<IActionResult> CustomerResetPassword([FromBody] CustomerSetPasswordDto dto)
        {
            if (!ModelState.IsValid) return BadRequest(ModelState);

            var customer = await _customerService.GetByEmailAsync(dto.Email);
            if (customer == null)
            {
                return NotFound(new { message = "Email not found." });
            }

            var success = await _customerService.SetPasswordAsync(customer.CustomerId, dto.Password);
            if (!success)
            {
                return StatusCode(500, new { message = "Failed to update password." });
            }

            return Ok(new { message = "Password updated successfully. You can now login." });
        }

        /// <summary>
        /// Verifies if the email exists for the Forgot Password flow (Staff) (UC-04.1 → 04.2).
        /// </summary>
        [AllowAnonymous]
        [HttpPost("staff/verify-email")]
        public async Task<IActionResult> StaffVerifyEmail([FromBody] VerifyEmailDto dto)
        {
            if (!ModelState.IsValid) return BadRequest(ModelState);

            var staff = await _staffService.GetByEmailAsync(dto.Email);
            if (staff == null)
            {
                return NotFound(new { message = "Email not found." });
            }

            return Ok(new { message = "Email verified. Proceed to reset password." });
        }

        /// <summary>
        /// Resets the staff's password (UC-04.4 → 04.5).
        /// </summary>
        [AllowAnonymous]
        [HttpPost("staff/reset-password")]
        public async Task<IActionResult> StaffResetPassword([FromBody] CustomerSetPasswordDto dto)
        {
            if (!ModelState.IsValid) return BadRequest(ModelState);

            var staff = await _staffService.GetByEmailAsync(dto.Email);
            if (staff == null)
            {
                return NotFound(new { message = "Email not found." });
            }

            var success = await _staffService.SetPasswordAsync(staff.StaffId, dto.Password);
            if (!success)
            {
                return StatusCode(500, new { message = "Failed to update password." });
            }

            return Ok(new { message = "Password updated successfully. You can now login." });
        }

        // ══════════════════════════════════════════════════════════════════════════
        // UC-01.2 – Login for Staff
        // ══════════════════════════════════════════════════════════════════════════

        /// <summary>
        /// Authenticates a Staff member (or Admin) and returns a JWT bearer token.
        /// </summary>
        /// <remarks>
        /// Normal flow (01.2.1 → 01.2.5):
        ///   1. Staff member sends email + password (+ optional rememberMe flag).
        ///   2. BLL validates credentials via BCrypt (FR-01).
        ///   3. JWT is generated and returned.
        ///   4. Client stores the token.
        ///
        /// Alternative flow (01.2.1): RememberMe = true → extended token lifetime.
        ///
        /// Exception (01.2.0.E1): Invalid credentials → 401 Unauthorized.
        ///
        /// Known gap: inactive Staff accounts are rejected here via BLL
        ///            (ValidateLoginAsync checks IsActive).
        /// </remarks>
        [AllowAnonymous]
        [HttpPost("staff/login")]
        public async Task<ActionResult<LoginResponseDto>> StaffLogin([FromBody] LoginDto dto)
        {
            // 01.2.2: Validate request shape
            if (!ModelState.IsValid)
                return BadRequest(ModelState);

            // 01.2.3: BLL validates credentials (BCrypt.Verify — FR-01)
            var staff = await _staffService.ValidateLoginAsync(dto.Email, dto.Password);

            // Exception 01.2.0.E1
            if (staff is null)
                return Unauthorized(new { message = "Invalid email or password." });

            // 01.2.4: Generate JWT (session equivalent for stateless API)
            var response = _jwtService.GenerateToken(
                userId:     staff.StaffId,
                email:      staff.Email,
                fullName:   staff.FullName,
                role:       staff.Role.ToString(),  // "Staff" or "Admin"
                rememberMe: dto.RememberMe);

            response.Role = staff.Role;

            // 01.2.5: Return token; client redirects to appropriate Staff page
            return Ok(response);
        }

        // ══════════════════════════════════════════════════════════════════════════
        // UC-02 – Logout (Admin, Staff, Customer)
        // ══════════════════════════════════════════════════════════════════════════

        /// <summary>
        /// Ends the authenticated user's session.
        /// </summary>
        /// <remarks>
        /// Normal flow (02.1 → 02.3):
        ///   1. Authenticated user calls this endpoint (Bearer token required).
        ///   2. Server-side: JWT is stateless — the response instructs the client to delete
        ///      the stored token (POST-1: session terminated from client perspective).
        ///   3. Client discards the token and redirects to the Login page (POST-2).
        ///
        /// Business rule FR-01 (UC-02): Session Termination — the client MUST discard the token.
        ///   True server-side revocation (blacklist) is a future enhancement.
        ///
        /// Precondition: Bearer token must be valid (returns 401 otherwise).
        /// </remarks>
        [Authorize]
        [HttpPost("logout")]
        public IActionResult Logout()
        {
            // UC-02: 02.2 – "terminate the current session"
            // For JWT the token is stateless; we signal success and the client must discard it.
            // POST-1: session terminated (client-side).
            // POST-2: client redirects to Login page (client-side action after receiving 200).
            return Ok(new { message = "You have been logged out successfully. Please discard your token." });
        }
    }
}

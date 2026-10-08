using BLL.DTOs.Auth;
using BLL.Services.Interfaces;
using Microsoft.Extensions.Configuration;
using Microsoft.IdentityModel.Tokens;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;

namespace BLL.Services
{
    /// <summary>
    /// Concrete implementation of <see cref="IJwtService"/>.
    /// Reads Jwt:Key, Jwt:Issuer, Jwt:Audience from IConfiguration (appsettings.json / secrets).
    ///
    /// Design notes
    /// ──────────────
    /// • This class lives in BLL so the token-generation logic stays testable without an HTTP context.
    /// • The API project only wires up the implementation; MVC/Razor frontends never call this service
    ///   because they use cookie authentication, not JWT.
    /// </summary>
    public class JwtService : IJwtService
    {
        private readonly IConfiguration _config;

        // ── Config keys (must match appsettings.json) ─────────────────────────────
        private const string SectionKey      = "Jwt:Key";
        private const string SectionIssuer   = "Jwt:Issuer";
        private const string SectionAudience = "Jwt:Audience";

        public JwtService(IConfiguration config)
        {
            _config = config;
        }

        /// <inheritdoc/>
        public LoginResponseDto GenerateToken(
            int userId, string email, string fullName, string role, bool rememberMe = false)
        {
            // BR-01 / FR-01: credentials have already been verified (BCrypt) by the
            // calling service layer before this method is invoked.

            var key      = _config[SectionKey]      ?? throw new InvalidOperationException("JWT key is not configured.");
            var issuer   = _config[SectionIssuer]   ?? throw new InvalidOperationException("JWT issuer is not configured.");
            var audience = _config[SectionAudience] ?? throw new InvalidOperationException("JWT audience is not configured.");

            var securityKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(key));
            var credentials = new SigningCredentials(securityKey, SecurityAlgorithms.HmacSha256);

            // Token lifetime: 30 days if "Remember Me", 1 day otherwise.
            var expires = rememberMe
                ? DateTime.UtcNow.AddDays(30)
                : DateTime.UtcNow.AddDays(1);

            var claims = new[]
            {
                new Claim(JwtRegisteredClaimNames.Sub,   userId.ToString()),
                new Claim(JwtRegisteredClaimNames.Email, email),
                new Claim(JwtRegisteredClaimNames.Name,  fullName),
                new Claim(ClaimTypes.NameIdentifier,     userId.ToString()),
                new Claim(ClaimTypes.Email,              email),
                new Claim(ClaimTypes.Name,               fullName),
                new Claim(ClaimTypes.Role,               role),
                new Claim(JwtRegisteredClaimNames.Jti,   Guid.NewGuid().ToString())
            };

            var token = new JwtSecurityToken(
                issuer:             issuer,
                audience:           audience,
                claims:             claims,
                notBefore:          DateTime.UtcNow,
                expires:            expires,
                signingCredentials: credentials);

            return new LoginResponseDto
            {
                Token     = new JwtSecurityTokenHandler().WriteToken(token),
                ExpiresAt = expires,
                UserId    = userId,
                FullName  = fullName,
                Email     = email
                // Role is carried inside the token claims; callers can decode it if needed.
            };
        }
    }
}

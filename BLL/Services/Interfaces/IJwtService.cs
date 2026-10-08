using BLL.DTOs.Auth;

namespace BLL.Services.Interfaces
{
    /// <summary>
    /// Generates JWT bearer tokens for authenticated users.
    /// Used by the API project only; MVC/Razor frontends use cookie authentication.
    /// </summary>
    public interface IJwtService
    {
        LoginResponseDto GenerateToken(
            int userId, string email, string fullName, string role, bool rememberMe = false);
    }
}

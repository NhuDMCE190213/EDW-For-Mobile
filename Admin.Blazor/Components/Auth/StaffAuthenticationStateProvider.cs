using BLL.Services.Interfaces;
using Microsoft.AspNetCore.Authentication.Cookies;
using Microsoft.AspNetCore.Components.Authorization;
using System.Security.Claims;

namespace Admin.Blazor.Components.Auth
{
    public class StaffAuthenticationStateProvider : AuthenticationStateProvider
    {
        private readonly IStaffService _staffService;
        private readonly IHttpContextAccessor _httpContextAccessor;

        public StaffAuthenticationStateProvider(IStaffService staffService, IHttpContextAccessor httpContextAccessor)
        {
            _staffService = staffService;
            _httpContextAccessor = httpContextAccessor;
        }

        public override async Task<AuthenticationState> GetAuthenticationStateAsync()
        {
            var httpContext = _httpContextAccessor.HttpContext;
            // If the HttpContext has an authenticated user (cookie present), propagate
            // the same claims into Blazor's AuthenticationState so components can use
            // [AuthorizeView] or AuthenticationStateProvider.GetAuthenticationStateAsync.
            if (httpContext?.User?.Identity?.IsAuthenticated == true)
            {
                var claimsIdentity = new ClaimsIdentity(httpContext.User.Claims, CookieAuthenticationDefaults.AuthenticationScheme);
                var claimsPrincipal = new ClaimsPrincipal(claimsIdentity);
                return new AuthenticationState(claimsPrincipal);
            }

            // No authenticated user: return anonymous principal
            var anonymous = new ClaimsPrincipal(new ClaimsIdentity());
            return await Task.FromResult(new AuthenticationState(anonymous));
        }

        public void NotifyAuthenticationStateChanged()
        {
            // Notify subscribers that authentication state changed
        }
    }
}
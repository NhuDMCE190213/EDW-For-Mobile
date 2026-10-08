using System.ComponentModel.DataAnnotations;

namespace BLL.DTOs.Auth
{
    public class VerifyEmailDto
    {
        [Required]
        [EmailAddress]
        public string Email { get; set; } = string.Empty;
    }
}

using System.ComponentModel.DataAnnotations;

namespace BLL.DTOs.Customer
{
    public class CustomerRegisterDto
    {
        [Required, StringLength(100)] public string FullName { get; set; } = string.Empty;
        [Required, EmailAddress] public string Email { get; set; } = string.Empty;
        [Required, StringLength(20)] public string PhoneNumber { get; set; } = string.Empty;
        [Required, StringLength(100, MinimumLength = 8)]
        [RegularExpression(@"^(?=.*[a-zA-Z])(?=.*\d)(?=.*[!@#$%^&*()_+\-=\[\]{};':""\\|,.<>\/?]).+$")]
        public string Password { get; set; } = string.Empty;
    }
}

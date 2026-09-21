using DAL.Enums;
using System.ComponentModel.DataAnnotations;

namespace BLL.DTOs.Customer
{
    public class CustomerCreateDto
    {
        [Required(ErrorMessage = "Full name is required.")]
        [StringLength(100, ErrorMessage = "Full name cannot exceed 100 characters.")]
        public string FullName { get; set; } = null!;

        [Required(ErrorMessage = "Email is required.")]
        [EmailAddress(ErrorMessage = "Invalid email format.")]
        public string Email { get; set; } = null!;

        [Required(ErrorMessage = "Phone number is required.")]
        [StringLength(20, ErrorMessage = "Phone number cannot exceed 20 characters.")]
        public string PhoneNumber { get; set; } = null!;

        [Required(ErrorMessage = "Password is required.")]
        [StringLength(100, MinimumLength = 8, ErrorMessage = "Password must be at least 8 characters.")]
        [RegularExpression(@"^(?=.*[a-zA-Z])(?=.*\d)(?=.*[!@#$%^&*()_+\-=\[\]{};':""\\|,.<>\/?]).+$", 
            ErrorMessage = "Password must contain at least one letter, one number, and one special character.")]
        public string Password { get; set; } = string.Empty;

        public RoleEnum Role { get; set; } = RoleEnum.Customer; // Customer by default
        public int Points { get; set; } = 0;
        public bool IsActive { get; set; }
    }
}
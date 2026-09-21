using System.ComponentModel.DataAnnotations;

namespace BLL.DTOs.Customer
{
    public class CustomerProfileDto
    {
        public int CustomerId { get; set; }
        public string Email { get; set; } = string.Empty;

        [Required(ErrorMessage = "Full name is required.")]
        [StringLength(100, ErrorMessage = "Full name cannot exceed 100 characters.")]
        public string FullName { get; set; } = string.Empty;

        [Required(ErrorMessage = "Phone number is required.")]
        [StringLength(20, ErrorMessage = "Phone number cannot exceed 20 characters.")]
        public string PhoneNumber { get; set; } = string.Empty;

        public int Points { get; set; }
    }
}
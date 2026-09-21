using AutoMapper;
using DAL.Enums;

namespace BLL.DTOs.Customer
{
    [AutoMap(typeof(DAL.Models.Customer), ReverseMap = true)]
    public class CustomerDto
    {
        public int CustomerId { get; set; }
        public string FullName { get; set; } = string.Empty;
        public string Email { get; set; } = string.Empty;
        public string PhoneNumber { get; set; } = string.Empty;
        public RoleEnum Role { get; set; }
        public int Points { get; set; }
        public bool IsDeleted { get; set; } = false;
        public DateTime CreatedAt { get; set; }
        public DateTime? UpdatedAt { get; set; }
        public bool IsActive { get; set; } = true;
    }
}
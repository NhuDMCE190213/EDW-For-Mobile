using AutoMapper;
using DAL.Enums;

namespace BLL.DTOs.Staff
{
    [AutoMap(typeof(DAL.Models.Staff), ReverseMap = true)]
    public class StaffDto
    {
        public int StaffId { get; set; }
        public string FullName { get; set; } = string.Empty;
        public string Email { get; set; } = string.Empty;
        public RoleEnum Role { get; set; }
        public bool IsActive { get; set; }
        public DateTime CreatedAt { get; set; }
        public DateTime? UpdatedAt { get; set; }
        public bool IsDeleted { get; set; } = false;
    }
}
using DAL.Enums;

namespace BLL.DTOs.Staff
{
    public class StaffCreateDto
    {
        public string FullName { get; set; } = string.Empty;
        public string Email { get; set; } = string.Empty;
        public string Password { get; set; } = string.Empty;
        public RoleEnum Role { get; set; }
        public bool IsActive { get; set; } = true;
    }
}
using DAL.Enums;
using DAL.Models.Base;

namespace DAL.Models
{
    public class Staff : IBaseEntity
    {
        public int StaffId { get; set; }
        public string Email { get; set; } = string.Empty;
        public string FullName { get; set; } = string.Empty;
        public string PasswordHash { get; set; } = string.Empty;
        public RoleEnum Role { get; set; }
        public bool IsActive { get; set; }

        public bool IsDeleted { get; set; }
        public DateTime CreatedAt { get; set; }
        public DateTime? UpdatedAt { get; set; }

        public void Update(string email, string fullName, RoleEnum role, bool isActive) {
            Email = email;
            FullName = fullName;
            Role = role;
            IsActive = isActive;
            UpdatedAt = DateTime.UtcNow;
        }
    }
}

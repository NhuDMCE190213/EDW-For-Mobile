using DAL.Enums;
using DAL.Models.Base;

namespace DAL.Models
{
    public class Customer : IBaseEntity
    {
        public int CustomerId { get; set; }
        public string FullName { get; set; } = string.Empty;
        public string Email { get; set; } = string.Empty;
        public string PhoneNumber { get; set; } = string.Empty;
        public string PasswordHash { get; set; } = string.Empty;
        public RoleEnum Role { get; set; }
        public int Points { get; set; }

        public bool IsDeleted { get; set; } = false;
        public DateTime CreatedAt { get; set; }
        public DateTime? UpdatedAt { get; set; }
        public bool IsActive { get; set; } = true;

        public void Create(string fullName, string email, string phoneNumber, string passwordHash, RoleEnum role, int points, bool isActive)
        {
            FullName = fullName;
            Email = email;
            PhoneNumber = phoneNumber;
            PasswordHash = passwordHash;
            Role = role;
            Points = points;
            CreatedAt = DateTime.UtcNow;
            IsActive = isActive;
        }

        public void Update(string fullName, string email, string phoneNumber, RoleEnum role, int points, bool isActive)
        {
            FullName = fullName;
            Email = email;
            PhoneNumber = phoneNumber;
            Role = role;
            Points = points;
            UpdatedAt = DateTime.UtcNow;
            IsActive = isActive;
        }

        public void Delete(bool isDelete)
        {
            IsDeleted = isDelete;
        }

        public void DisableAcc(bool isDisable)
        {
            if (isDisable) IsActive = false;
            else IsActive = true;
        }
    }
}

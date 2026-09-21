using DAL.Models.Base;
using Microsoft.VisualBasic;

namespace DAL.Models
{
    public class Category : IBaseEntity
    {
        public int Id { get; set; }
        public string Name { get; set; } = string.Empty;

        public bool IsDeleted { get; set; }
        public DateTime CreatedAt { get; set; }
        public DateTime? UpdatedAt { get; set; }

        public static Category Create(string name)
        {
            return new Category
            {
                Name = name,
                IsDeleted = false,
                CreatedAt = DateTime.UtcNow
            };
        }

        public void Update(string name)
        {
            Name = name;
            UpdatedAt = DateTime.UtcNow;
        }

        public void Delete()
        {
            IsDeleted = true;
            UpdatedAt = DateTime.UtcNow;
        }
    }
}

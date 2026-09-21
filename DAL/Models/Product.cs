using DAL.Models.Base;
using Microsoft.VisualBasic;

namespace DAL.Models
{
    public class Product : IBaseEntity
    {
        public int ProductId { get; set; }

        public string ProductName { get; set; } = string.Empty;

        public string Brand { get; set; } = string.Empty;

        public int CategoryId { get; set; }
        virtual public Category? Category { get; set; }
        virtual public ICollection<ProductVariant> ProductVariants { get; set; } = new List<ProductVariant>();

        public string? ImageUrl { get; set; }

        public bool IsDeleted { get; set; }
        public DateTime CreatedAt { get; set; }
        public DateTime? UpdatedAt { get; set; }

        public static Product Create(string productName, string brand, int categoryId, string? imageUrl) {
            return new Product {
                ProductName = productName,
                Brand = brand,
                CategoryId = categoryId,
                ImageUrl = imageUrl,
                IsDeleted = false,
                CreatedAt = DateTime.UtcNow
            };
        }

        public void Delete() {
            IsDeleted = true;
            UpdatedAt = DateTime.UtcNow;
        }

        public void Update(string productName, string brand, int categoryId, string? imageUrl) {
            ProductName = productName;
            Brand = brand;
            CategoryId = categoryId;
            ImageUrl = imageUrl;

            UpdatedAt = DateTime.UtcNow;
        }
    }
}

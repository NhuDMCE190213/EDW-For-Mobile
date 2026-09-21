using DAL.Models.Base;

namespace DAL.Models
{
    public class ProductReview : IBaseEntity
    {
        public int Id { get; set; }
        public int CustomerId { get; set; }
        public int ProductId { get; set; }
        public int Rating { get; set; } // 1 to 5 stars
        public string Comment { get; set; } = string.Empty;

        public bool IsDeleted { get; set; }
        public bool IsFlagged { get; set; } = false;
        public DateTime CreatedAt { get; set; }
        public DateTime? UpdatedAt { get; set; }

        public virtual Customer? Customer { get; set; }
        public virtual Product? Product { get; set; }

        public static ProductReview Create(int customerId, int productId, int rating, string comment)
        {
            return new ProductReview
            {
                CustomerId = customerId,
                ProductId = productId,
                Rating = rating,
                Comment = comment,
                IsDeleted = false,
                CreatedAt = DateTime.UtcNow
            };
        }

        public void Update(int rating, string comment)
        {
            Rating = rating;
            Comment = comment;
            UpdatedAt = DateTime.UtcNow;
        }

        public void Flag()
        {
            IsFlagged = true;
            UpdatedAt = DateTime.UtcNow;
        }

        public void Unflag()
        {
            IsFlagged = false;
            UpdatedAt = DateTime.UtcNow;
        }
    }
}
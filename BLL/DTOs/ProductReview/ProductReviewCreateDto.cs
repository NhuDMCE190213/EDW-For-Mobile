using System.ComponentModel.DataAnnotations;

namespace BLL.DTOs.ProductReview
{
    public class ProductReviewCreateDto
    {
        public int CustomerId { get; set; }

        [Required]
        public int ProductId { get; set; }

        [Required]
        [Range(1, 5, ErrorMessage = "Rating must be between 1 and 5")]
        public int Rating { get; set; }

        [Required]
        [StringLength(1000, ErrorMessage = "Comment cannot exceed 1000 characters")]
        [MinLength(10, ErrorMessage = "Comment must be at least 10 characters")]
        public string Comment { get; set; } = string.Empty;
    }
}
using BLL.DTOs.ProductVariant.Customer;

namespace BLL.DTOs.Product.Customer
{
    public class ProductCustomerDto
    {
        public int ProductId { get; set; }
        public string ProductName { get; set; } = string.Empty;
        public string Brand { get; set; } = string.Empty;
        public int CategoryId { get; set; }
        public string CategoryName { get; set; } = string.Empty;


        public string? ImageUrl { get; set; }

        public IEnumerable<ProductVariantCustomerDto> ProductVariants { get; set; } = new List<ProductVariantCustomerDto>();

        public bool IsDeleted { get; set; }
        public DateTime CreatedAt { get; set; }
        public DateTime? UpdatedAt { get; set; }
    }
}

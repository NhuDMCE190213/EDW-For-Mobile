namespace BLL.DTOs.Product.Customer
{
    public class ProductCustomerCreateDto
    {
        public string ProductName { get; set; } = string.Empty;
        public string Brand { get; set; } = string.Empty;
        public int CategoryId { get; set; }

        public string? ImageUrl { get; set; }
    }
}

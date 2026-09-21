using BLL.DTOs.Category;
using BLL.DTOs.Promotion;
using System.Collections.Generic;

namespace StaffUser.Mvc.Models
{
    public class HomeIndexViewModel
    {
        public List<CategoryDto> Categories { get; set; } = new();
        public List<HomeProductViewModel> Products { get; set; } = new();
        public List<PromotionDto> Promotions { get; set; } = new();
    }

    public class HomeProductViewModel
    {
        public int ProductId { get; set; }
        public string ProductName { get; set; } = string.Empty;
        public string Brand { get; set; } = string.Empty;
        public int CategoryId { get; set; }
        public string CategoryName { get; set; } = string.Empty;
        public string? ImageUrl { get; set; }
        public decimal BasePrice { get; set; }        // Giá gốc (min variant price)
        public decimal FinalPrice { get; set; }        // Giá sau khi áp promotion
        public bool IsOnSale { get; set; }              // FinalPrice < BasePrice
        public List<string> Features { get; set; } = new(); // e.g. "Intel i7", "16GB RAM"
    }
}

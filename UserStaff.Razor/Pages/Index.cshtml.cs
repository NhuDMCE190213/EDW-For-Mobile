using BLL.DTOs.Order;
using BLL.DTOs.Product.Staff;
using BLL.DTOs.ProductReview;
using BLL.Services.Interfaces;
using Microsoft.AspNetCore.Mvc.RazorPages;

namespace Staff.Razor.Pages
{
    public class IndexModel : PageModel
    {
        private readonly IProductService _productService;
        private readonly IOrderService _orderService;
        private readonly IProductReviewService _reviewService;

        public IndexModel(
            IProductService productService,
            IOrderService orderService,
            IProductReviewService reviewService)
        {
            _productService = productService;
            _orderService = orderService;
            _reviewService = reviewService;
        }

        public List<ProductStaffDto> Products { get; set; } = new();
        public List<OrderDto> Orders { get; set; } = new();
        public List<ProductReviewDto> Reviews { get; set; } = new();

        public int TotalProducts => Products.Count(p => !p.IsDeleted);
        public int TotalOrders => Orders.Count;
        public int PendingOrders => Orders.Count(o => o.Status == "Pending");
        public int ProcessingOrders => Orders.Count(o => o.Status == "Processing");
        public int CompletedOrders => Orders.Count(o => o.Status == "Completed");
        public decimal TotalRevenue => Orders.Where(o => o.Status == "Completed").Sum(o => o.TotalAmount);
        public int TotalReviews => Reviews.Count(r => !r.IsDeleted);
        public int FlaggedReviews => Reviews.Count(r => r.IsFlagged && !r.IsDeleted);

        public List<OrderDto> RecentOrders => Orders
            .OrderByDescending(o => o.CreatedAt)
            .Take(5)
            .ToList();

        public async Task OnGetAsync()
        {
            Products = await _productService.GetAllProductsAsync();
            Orders = await _orderService.GetAllOrdersAsync();
            Reviews = await _reviewService.GetAllProductReviewsAsync();
        }

        public string GetStatusBadgeClass(string status)
        {
            return status switch
            {
                "Pending" => "bg-warning-subtle text-warning",
                "Processing" => "bg-info-subtle text-info",
                "Completed" => "bg-success-subtle text-success",
                "Cancelled" => "bg-danger-subtle text-danger",
                _ => "bg-secondary-subtle text-secondary"
            };
        }
    }
}
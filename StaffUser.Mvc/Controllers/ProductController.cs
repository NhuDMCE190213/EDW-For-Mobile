using BLL.DTOs.Product.Customer;
using BLL.DTOs.ProductReview;
using BLL.Services.Interfaces;
using Microsoft.AspNetCore.Mvc;
using System.Security.Claims;

namespace Customer.Mvc.Controllers
{
    public class ProductController : Controller
    {

        private readonly IProductService _productService;
        private readonly IProductReviewService _productReviewService;
        private readonly ICustomerService _customerService;
        public ProductController(IProductService productService, IProductReviewService productReviewService, ICustomerService customerService)
        {
            _productService = productService;
            _productReviewService = productReviewService;
            _customerService = customerService;
        }

        public async Task<IActionResult> Index(int id)
        {
            ProductCustomerDto? productCustomerDto = await _productService.GetProductCustomerByIdAsync(id);
            if (productCustomerDto == null)
            {
                return NotFound();
            }

            var reviews = await _productReviewService.GetProductReviewsByProductIdAsync(id);
            reviews = reviews.Where(r => !r.IsFlagged && !r.IsDeleted)
                              .OrderByDescending(r => r.CreatedAt)
                              .ToList();

            ProductReviewDto? myReview = null;
            var email = User.FindFirst(ClaimTypes.Email)?.Value;
            if (!string.IsNullOrEmpty(email))
            {
                var customer = await _customerService.GetByEmailAsync(email);
                if (customer != null)
                {
                    myReview = reviews.FirstOrDefault(r => r.CustomerId == customer.CustomerId);
                }
            }

            ViewBag.Reviews = reviews;
            ViewBag.CurrentUserEmail = User.FindFirst(ClaimTypes.Email)?.Value;
            ViewBag.MyReview = myReview;

            return View(productCustomerDto);
        }
    }
}

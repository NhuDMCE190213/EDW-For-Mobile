using Microsoft.AspNetCore.Mvc;
using BLL.Services.Interfaces;
using BLL.DTOs.ProductReview;
using BLL.DTOs.Product;
using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;

namespace Customer.Mvc.Controllers
{
    public class ReviewsController : Controller
    {
        private bool IsAjax() => Request.Headers["X-Requested-With"] == "XMLHttpRequest";

        private readonly IProductReviewService _productReviewService;
        private readonly IProductService _productService;

        public ReviewsController(IProductReviewService productReviewService, IProductService productService)
        {
            _productReviewService = productReviewService;
            _productService = productService;
        }

        public async Task<IActionResult> Index(int? productId, int page = 1, int pageSize = 10)
        {
            List<ProductReviewDto> reviews;

            if (productId.HasValue && productId.Value > 0)
            {
                var product = await _productService.GetProductByIdAsync(productId.Value);
                if (product == null)
                {
                    return NotFound();
                }
                ViewBag.Product = product;
                reviews = await _productReviewService.GetProductReviewsByProductIdAsync(productId.Value);
            }
            else
            {
                reviews = await _productReviewService.GetAllProductReviewsAsync();
            }

            // Filter out flagged reviews for customers (only show normal reviews)
            reviews = reviews.Where(r => !r.IsFlagged && !r.IsDeleted).ToList();

            // Pagination
            var totalReviews = reviews.Count;
            var totalPages = (int)Math.Ceiling((double)totalReviews / pageSize);
            page = Math.Max(1, Math.Min(page, totalPages == 0 ? 1 : totalPages));

            var pagedReviews = reviews
                .OrderByDescending(r => r.CreatedAt)
                .Skip((page - 1) * pageSize)
                .Take(pageSize)
                .ToList();

            ViewBag.CurrentPage = page;
            ViewBag.TotalPages = totalPages;
            ViewBag.PageSize = pageSize;
            ViewBag.TotalReviews = totalReviews;
            ViewBag.ProductId = productId;

            // Get all products for the product selector dropdown
            var allProducts = await _productService.GetAllProductsAsync();
            ViewBag.AllProducts = allProducts.Where(p => !p.IsDeleted).ToList();

            return View(pagedReviews);
        }

        public async Task<IActionResult> ProductReviews(int productId)
        {
            var product = await _productService.GetProductByIdAsync(productId);
            if (product == null)
            {
                return NotFound();
            }

            var reviews = await _productReviewService.GetProductReviewsByProductIdAsync(productId);
            reviews = reviews.Where(r => !r.IsFlagged && !r.IsDeleted).ToList();

            ViewBag.Product = product;
            return View(reviews);
        }

        [Authorize]
        [HttpGet]
        public async Task<IActionResult> Create(int? productId)
        {
            // If no productId provided, show product selector
            if (!productId.HasValue)
            {
                var allProducts = await _productService.GetAllProductsAsync();
                ViewBag.AllProducts = allProducts.Where(p => !p.IsDeleted).ToList();
                return View("Create", new ProductReviewCreateDto());
            }

            var product = await _productService.GetProductByIdAsync(productId.Value);
            if (product == null)
            {
                return NotFound();
            }

            var email = User.FindFirst(ClaimTypes.Email)?.Value;
            if (string.IsNullOrEmpty(email))
            {
                return RedirectToAction("Login", "Auth");
            }

            // Check if user already reviewed this product
            var customerService = HttpContext.RequestServices.GetRequiredService<ICustomerService>();
            var customer = await customerService.GetByEmailAsync(email);
            if (customer != null)
            {
                var existingReviews = await _productReviewService.GetProductReviewsByProductIdAsync(productId.Value);
                var hasReviewed = existingReviews.Any(r => r.CustomerId == customer.CustomerId && !r.IsDeleted);
                
                if (hasReviewed)
                {
                    TempData["InfoMessage"] = "You have already reviewed this product. You can edit your existing review.";
                    return RedirectToAction("Index", "Product", new { id = productId.Value }, "reviews");
                }
            }

            ViewBag.Product = product;
            return View(new ProductReviewCreateDto { ProductId = productId.Value });
        }

        [Authorize]
        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> Create(ProductReviewCreateDto model)
        {
            var email = User.FindFirst(ClaimTypes.Email)?.Value;
            if (string.IsNullOrEmpty(email))
                return IsAjax() ? Json(new { success = false, message = "Please log in." }) : RedirectToAction("Login", "Auth");

            var customerService = HttpContext.RequestServices.GetRequiredService<ICustomerService>();
            var customer = await customerService.GetByEmailAsync(email);
            if (customer == null)
                return IsAjax() ? Json(new { success = false, message = "Please log in." }) : RedirectToAction("Login", "Auth");

            var existingReviews = await _productReviewService.GetProductReviewsByProductIdAsync(model.ProductId);
            if (existingReviews.Any(r => r.CustomerId == customer.CustomerId && !r.IsDeleted))
            {
                var msg = "You have already reviewed this product. Please edit your existing review.";
                if (IsAjax()) return Json(new { success = false, message = msg });
                ModelState.AddModelError("", msg);
                ViewBag.Product = await _productService.GetProductByIdAsync(model.ProductId);
                return View(model);
            }

            if (!ModelState.IsValid)
            {
                if (IsAjax())
                {
                    var errors = ModelState.Values.SelectMany(v => v.Errors).Select(e => e.ErrorMessage);
                    return Json(new { success = false, message = string.Join(" ", errors) });
                }
                ViewBag.Product = await _productService.GetProductByIdAsync(model.ProductId);
                return View(model);
            }

            model.CustomerId = customer.CustomerId;
            await _productReviewService.CreateProductReviewAsync(model);

            if (IsAjax()) return Json(new { success = true, message = "Review submitted successfully!" });
            TempData["SuccessMessage"] = "Review submitted successfully!";
            return RedirectToAction("Index", "Product", new { id = model.ProductId }, "reviews");
        }

        [Authorize]
        [HttpGet]
        public async Task<IActionResult> Edit(int id)
        {
            var email = User.FindFirst(ClaimTypes.Email)?.Value;
            if (string.IsNullOrEmpty(email))
            {
                return RedirectToAction("Login", "Auth");
            }

            var customerService = HttpContext.RequestServices.GetRequiredService<ICustomerService>();
            var customer = await customerService.GetByEmailAsync(email);
            if (customer == null)
            {
                return RedirectToAction("Login", "Auth");
            }

            var review = await _productReviewService.GetProductReviewByIdAsync(id);
            if (review == null || review.CustomerId != customer.CustomerId)
            {
                return NotFound();
            }

            var product = await _productService.GetProductByIdAsync(review.ProductId);
            ViewBag.Product = product;

            var editDto = new ProductReviewUpdateDto
            {
                Id = review.Id,
                ProductId = review.ProductId,
                Rating = review.Rating,
                Comment = review.Comment
            };

            return View(editDto);
        }

        [Authorize]
        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> Edit(ProductReviewUpdateDto model)
        {
            var email = User.FindFirst(ClaimTypes.Email)?.Value;
            if (string.IsNullOrEmpty(email))
            {
                return RedirectToAction("Login", "Auth");
            }

            var customerService = HttpContext.RequestServices.GetRequiredService<ICustomerService>();
            var customer = await customerService.GetByEmailAsync(email);
            if (customer == null)
            {
                return RedirectToAction("Login", "Auth");
            }

            var review = await _productReviewService.GetProductReviewByIdAsync(model.Id);
            if (review == null || review.CustomerId != customer.CustomerId)
            {
                return NotFound();
            }

            if (!ModelState.IsValid)
            {
                if (IsAjax())
                {
                    var errors = ModelState.Values.SelectMany(v => v.Errors).Select(e => e.ErrorMessage);
                    return Json(new { success = false, message = string.Join(" ", errors) });
                }
                var productInfo = await _productService.GetProductByIdAsync(review.ProductId);
                ViewBag.Product = productInfo;
                return View(model);
            }

            try
            {
                var result = await _productReviewService.UpdateProductReviewAsync(model);
                if (result)
                {
                    if (IsAjax()) return Json(new { success = true, message = "Review updated successfully!" });
                    TempData["SuccessMessage"] = "Review updated successfully!";
                    return RedirectToAction("Index", "Product", new { id = review.ProductId }, "reviews");
                }
                if (IsAjax()) return Json(new { success = false, message = "Failed to update review." });
                ModelState.AddModelError("", "Failed to update review.");
            }
            catch (Exception ex)
            {
                if (IsAjax()) return Json(new { success = false, message = "Error: " + ex.Message });
                ModelState.AddModelError("", "An error occurred while updating your review: " + ex.Message);
            }

            var product = await _productService.GetProductByIdAsync(review.ProductId);
            ViewBag.Product = product;
            return View(model);
        }
    }
}
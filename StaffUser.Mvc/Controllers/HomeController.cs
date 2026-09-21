using Microsoft.AspNetCore.Mvc;
using StaffUser.Mvc.Models;
using BLL.Services.Interfaces;
using System.Diagnostics;
using BLL.DTOs.Product.Staff;
using Microsoft.AspNetCore.Authorization;
using System.Runtime.ConstrainedExecution;

namespace Customer.Mvc.Controllers
{
    public class HomeController : Controller
    {
        private readonly ILogger<HomeController> _logger;
        private readonly IProductService _productService;
        private readonly ICategoryService _categoryService;
        private readonly IProductVariantService _productVariantService;
        private readonly IPromotionService _promotionService;

        public HomeController(
            ILogger<HomeController> logger,
            IProductService productService,
            ICategoryService categoryService,
            IProductVariantService productVariantService,
            IPromotionService promotionService)
        {
            _logger = logger;
            _productService = productService;
            _categoryService = categoryService;
            _productVariantService = productVariantService;
            _promotionService = promotionService;
        }

        public async Task<IActionResult> Index(string? q, int? categoryId)
        {
            var categories = await _categoryService.GetAllCategoriesAsync();

            List<ProductStaffDto> products;
            if (categoryId.HasValue && categoryId.Value > 0)
            {
                products = await _productService.GetProductsByCategoryIdAsync(categoryId.Value);
            }
            else if (!string.IsNullOrEmpty(q))
            {
                products = await _productService.SearchByNameAsync(q);
            }
            else
            {
                products = await _productService.GetAllProductsAsync();
            }

            var variants = await _productVariantService.GetAllProductVariantsAsync();

            // Fetch promotions
            var promoRequest = new BLL.DTOs.Promotion.PromotionList.PromotionListRequest
            {
                Pagination = new BLL.DTOs.Pagination.PaginationRequest { Page = 1, PageSize = 50 }
            };
            var promoList = await _promotionService.GetPromotionsListAsync(promoRequest);
            var activePromotions = promoList.Pagination.Items
                .Where(p => !p.IsDisabled && !p.IsDeleted)
                .ToList();

            var productViewModels = new List<HomeProductViewModel>();
            foreach (var p in products)
            {
                var pVariants = variants.Where(v => v.ProductId == p.ProductId && !v.IsDeleted).ToList();
                var basePrice = pVariants.Any() ? pVariants.Min(v => v.Price) : 0;

                var features = new List<string>();
                var bestVariant = pVariants.OrderBy(v => v.Price).FirstOrDefault();

                decimal finalPrice = basePrice;
                if (bestVariant != null)
                {
                    finalPrice = bestVariant.GetPrice(); // đã Include(Promotion) ở bước 1
                    if (!string.IsNullOrEmpty(bestVariant.Cpu)) features.Add(bestVariant.Cpu);
                    if (!string.IsNullOrEmpty(bestVariant.Ram)) features.Add(bestVariant.Ram + " RAM");
                    if (!string.IsNullOrEmpty(bestVariant.Storage)) features.Add(bestVariant.Storage);
                }

                productViewModels.Add(new HomeProductViewModel
                {
                    ProductId = p.ProductId,
                    ProductName = p.ProductName,
                    Brand = p.Brand,
                    CategoryId = p.CategoryId,
                    CategoryName = p.CategoryName,
                    ImageUrl = p.ImageUrl,
                    BasePrice = basePrice,
                    FinalPrice = finalPrice,
                    IsOnSale = finalPrice < basePrice,
                    Features = features
                });
            }

            var viewModel = new HomeIndexViewModel
            {
                Categories = categories,
                Products = productViewModels,
                Promotions = activePromotions
            };

            return View(viewModel);
        }

        public IActionResult Privacy()
        {
            return View();
        }

        [AllowAnonymous]
        [ResponseCache(Duration = 0, Location = ResponseCacheLocation.None, NoStore = true)]
        public IActionResult Error()
        {
            return View(new ErrorViewModel { RequestId = Activity.Current?.Id ?? HttpContext.TraceIdentifier });
        }
    }
}

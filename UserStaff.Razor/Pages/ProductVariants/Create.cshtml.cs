using BLL.DTOs.Product.Staff;
using BLL.DTOs.ProductVariant.Staff;
using BLL.DTOs.Promotion;
using BLL.Services.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;

namespace Staff.Razor.Pages.ProductVariants
{
    [Authorize]
    public class CreateModel : PageModel
    {
        private readonly IProductVariantService _productVariantService;
        private readonly IProductService _productService;
        private readonly IPromotionService _promotionService;

        public CreateModel(IProductVariantService productVariantService, IProductService productService, IPromotionService promotionService)
        {
            _productVariantService = productVariantService;
            _productService = productService;
            _promotionService = promotionService;
        }

        [BindProperty]
        public ProductVariantStaffCreateDto ProductVariant { get; set; } = new();
        public ProductStaffDto? Product { get; set; } = new();
        public List<PromotionDto> PromotionDtos { get; set; } = new();

        public async Task OnGetAsync(int productId)
        {
            Product = await _productService.GetProductByIdAsync(productId);
            PromotionDtos = await _promotionService.GetActiveAndUpcomingPromotionsAsync();
        }

        public async Task<IActionResult> OnPostAsync()
        {
            if (!ModelState.IsValid)
            {
                return Page();
            }
            try
            {
                await _productVariantService.CreateProductVariantAsync(ProductVariant);

                TempData["SuccessMessage"] = "The variant was created successfully!";
                return RedirectToPage("./Index", new { productId = ProductVariant.ProductId });

            }
            catch (Exception ex)
            {
                TempData["ErrorMessage"] = ex.Message;
                ModelState.AddModelError(string.Empty, "Failed to create the Product Variant.");
                return RedirectToPage("./Index", new { productId = ProductVariant.ProductId });
            }

        }
    }
}

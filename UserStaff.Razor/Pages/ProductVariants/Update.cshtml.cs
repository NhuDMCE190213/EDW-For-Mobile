using BLL.DTOs.Product;
using BLL.DTOs.Product.Staff;
using BLL.DTOs.ProductVariant;
using BLL.DTOs.ProductVariant.Staff;
using BLL.DTOs.Promotion;
using BLL.Services.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;

namespace Staff.Razor.Pages.ProductVariants
{
    [Authorize]
    public class UpdateModel : PageModel
    {
        private readonly IProductVariantService _productVariantService;
        private readonly IProductService _productService;
        private readonly IPromotionService _promotionService;

        public UpdateModel(IProductVariantService productVariantService, IProductService productService, IPromotionService promotionService)
        {
            _productVariantService = productVariantService;
            _productService = productService;
            _promotionService = promotionService;
        }

        [BindProperty]
        public ProductVariantStaffUpdateDto ProductVariant { get; set; } = new();
        public ProductStaffDto? Product { get; set; } = new();
        public List<PromotionDto> PromotionDtos { get; set; } = new();

        public async Task<IActionResult> OnGetAsync(Guid id, int productId)
        {
            Product = await _productService.GetProductByIdAsync(productId);
            PromotionDtos = await _promotionService.GetActiveAndUpcomingPromotionsAsync();
            var variantDto = await _productVariantService.GetProductVariantByIdAsync(id);
            if (variantDto != null)
            {
                ProductVariant = new ProductVariantStaffUpdateDto
                {
                    ProductVariantId = variantDto.ProductVariantId,
                    ProductId = variantDto.ProductId,
                    PromotionId = variantDto.PromotionId,
                    Color = variantDto.Color,
                    Cpu = variantDto.Cpu,
                    Ram = variantDto.Ram,
                    Storage = variantDto.Storage,
                    ScreenSize = variantDto.ScreenSize,
                    Price = variantDto.Price,
                    StockQuantity = variantDto.StockQuantity,
                    ImageUrl = variantDto.ImageUrl
                };
            }
            return Page();
        }

        public async Task<IActionResult> OnPostAsync()
        {
            if (!ModelState.IsValid)
            {
                return Page();
            }
            
            try
            {
                await _productVariantService.UpdateProductVariantAsync(ProductVariant);

                TempData["SuccessMessage"] = "The variant was updated successfully!";
                return RedirectToPage("./Index", new { productId = ProductVariant.ProductId });

            }
            catch (Exception ex)
            {
                TempData["ErrorMessage"] = ex.Message;
                return RedirectToPage("./Index", new { productId = ProductVariant.ProductId });
            }
        }
    }
}

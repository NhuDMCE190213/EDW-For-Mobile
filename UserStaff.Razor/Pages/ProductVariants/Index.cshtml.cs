using BLL.DTOs.ProductVariant.Staff;
using BLL.Services.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Microsoft.EntityFrameworkCore;

namespace Staff.Razor.Pages.ProductVariants
{
    [Authorize]
    public class IndexModel : PageModel
    {
        private readonly IProductVariantService _productVariantService;

        public IndexModel(IProductVariantService productVariantService)
        {
            _productVariantService = productVariantService;
        }

        public List<ProductVariantStaffDto> ProductVariants { get; set; } = new List<ProductVariantStaffDto>();
        public int productId;

        public async Task OnGetAsync(int productId)
        {
            ProductVariants = await _productVariantService.GetVariantsByProductIdAsync(productId);
            this.productId = productId;
        }

        public async Task<JsonResult> OnPostDeleteAsync(Guid id)
        {
            try
            {
                // 1. Tìm biến thể trong Database theo ID truyền lên
                var deleteStatus = await _productVariantService.DeleteProductVariantAsync(new ProductVariantStaffDeleteDto { ProductVariantId = id });

                if (!deleteStatus)
                {
                    return new JsonResult(new { success = false, message = "Variants is not exist or deleted!" });
                }

                // 4. Trả về kết quả dạng JSON cho AJAX hiển thị Toast thành công
                return new JsonResult(new { success = true, message = "The variant was deleted successfully!" });
            }
            catch (Exception ex)
            {
                return new JsonResult(new { success = false, message = "System error: " + ex.Message });
            }
        }

        public async Task<JsonResult> OnPostStockInAsync(Guid id, int increaseAmount)
        {
            try
            {
                var stockInStatus = await _productVariantService.StockInAsync(id, increaseAmount);
                if (!stockInStatus)
                {
                    return new JsonResult(new { success = false, message = "The variant does not exist or has been deleted!" });
                }

                TempData["SuccessMessage"] = "Stock in successful!";

                return new JsonResult(new { success = true, message = "Stock in successful!" });
            }
            catch (Exception ex)
            {
                TempData["ErrorMessage"] = "System error: " + ex.Message;
                return new JsonResult(new { success = false, message = "System error: " + ex.Message });
            }
        }
    }
}

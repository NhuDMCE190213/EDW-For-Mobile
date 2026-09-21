using BLL.DTOs.ProductReview;
using BLL.Services.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;

namespace Staff.Razor.Pages.Reviews
{
    [Authorize]
    public class IndexModel : PageModel
    {
        private readonly IProductReviewService _productReviewService;

        public IndexModel(IProductReviewService productReviewService)
        {
            _productReviewService = productReviewService;
        }

        public List<ProductReviewDto> Reviews { get; set; } = new List<ProductReviewDto>();
        public int ProductId { get; set; }

        public async Task OnGetAsync(int productId = 0)
        {
            ProductId = productId;
            if (productId > 0)
            {
                Reviews = await _productReviewService.GetProductReviewsByProductIdAsync(productId);
            }
            else
            {
                Reviews = await _productReviewService.GetAllProductReviewsAsync();
            }
        }

        public async Task<JsonResult> OnPostFlagAsync(int id)
        {
            try
            {
                var flagStatus = await _productReviewService.FlagProductReviewAsync(id);

                if (!flagStatus)
                {
                    return new JsonResult(new { success = false, message = "Review not found or already flagged!" });
                }

                return new JsonResult(new { success = true, message = "Review flagged successfully!" });
            }
            catch (Exception ex)
            {
                return new JsonResult(new { success = false, message = "System error: " + ex.Message });
            }
        }
    }
}
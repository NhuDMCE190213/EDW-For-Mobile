using BLL.DTOs.Product.Staff;
using BLL.Services.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc.RazorPages;

namespace Staff.Razor.Pages.Products
{
    [Authorize]
    public class IndexModel : PageModel
    {
        private readonly IProductService _productService;

        public IndexModel(IProductService productService)
        {
            _productService = productService;
        }
        public List<ProductStaffDto> Products { get; set; } = new List<ProductStaffDto>();
        public async Task OnGetAsync()
        {
            Products = await _productService.GetAllProductsAsync();
        }
    }
}

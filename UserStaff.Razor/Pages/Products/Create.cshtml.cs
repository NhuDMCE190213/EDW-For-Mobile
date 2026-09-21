using BLL.DTOs.Product.Staff;
using BLL.Services.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;

namespace Staff.Razor.Pages.Products
{
    [Authorize]
    public class CreateModel : PageModel
    {
        private readonly IProductService _productService;

        public CreateModel(IProductService productService)
        {
            _productService = productService;
        }
        [BindProperty]
        public ProductStaffCreateDto ProductToCreate { get; set; } = new();
        public void OnGet()
        {

        }

        public async Task<IActionResult> OnPostAsync()
        {
            if (!ModelState.IsValid)
            {
                return Page();
            }
            var result = await _productService.CreateProductAsync(ProductToCreate);
            if (result != null)
            {
                return RedirectToPage("./Index");
            }

            ModelState.AddModelError(string.Empty, "An error occurred while creating the product. Please try again.");
            return Page();
        }
    }
}

using AutoMapper;
using BLL.DTOs.ProductVariant.Staff;
using BLL.Services.Interfaces;
using DAL.Models;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using System.ComponentModel.DataAnnotations;

namespace Staff.Razor.Pages.ProductVariants
{
    [Authorize]
    public class CreateVariantsModel : PageModel
    {
        private readonly IProductVariantService _variantService;
        private readonly IMapper _mapper;

        public CreateVariantsModel(IProductVariantService variantService, IMapper mapper)
        {
            _variantService = variantService;
            _mapper = mapper;
        }

        // Nhận ID sản phẩm chính từ URL Route (ví dụ: /Product/CreateVariants?productId=5)
        [BindProperty(SupportsGet = true)]
        public int ProductId { get; set; }

        // Tự động nhận danh sách biến thể mảng động gửi lên từ Form giao diện công khai
        [BindProperty]
        public List<VariantInputViewModel> Variants { get; set; } = new();

        public void OnGet()
        {
            // Xử lý logic tải thông tin sản phẩm cha nếu cần thiết
        }

        public async Task<IActionResult> OnPostAsync()
        {
            if (!ModelState.IsValid || Variants == null || !Variants.Any())
            {
                TempData["ErrorMessage"] = "Failed to create the variants!";
                ModelState.AddModelError(string.Empty, "Failed to create the Products Variant.");
                return Page(); // Trả lại trang kèm lỗi nếu điền thiếu Giá hoặc Số lượng kho
            }

            try
            {
                // VÒNG LẶP DUYỆT QUA TẤT CẢ BIẾN THỂ ĐƯỢC SINH TỰ ĐỘNG ĐỂ LƯU DATABASE
                foreach (var item in Variants)
                {
                    var newVariant = ProductVariant.Create(
                        item.Color, item.Cpu, item.Ram, item.Storage, item.ScreenSize, item.Price, item.StockQuantity, null, ProductId);

                    ProductVariantStaffCreateDto variantDto = _mapper.Map<ProductVariantStaffCreateDto>(newVariant);

                    await _variantService.CreateProductVariantAsync(variantDto);
                }

                TempData["SuccessMessage"] = "The variant was created successfully!";
                return RedirectToPage("./Index", new { productId = ProductId });
            }
            catch (Exception ex)
            {
                // 1. Ghi log ngoại lệ (nếu cần) ví dụ: _logger.LogError(ex, "Duplicate variant error");

                // 2. Lưu thông báo lỗi vào TempData để hiển thị ở UI ngoài giao diện
                // Bạn có thể tùy biến chuỗi check ex.Message hoặc nội dung bên trong để hiển thị câu tiếng Việt/Anh thân thiện hơn
                if (ex.Message.Contains("duplicate") || ex.InnerException?.Message.Contains("duplicate") == true)
                {
                    TempData["ErrorMessage"] = "One or more variants already exist (Duplicate SKU/Attributes)!";
                    ModelState.AddModelError(string.Empty, "Duplicate data detected. Please check the values again.");
                }
                else
                {
                    TempData["ErrorMessage"] = $"An error occurred while saving: {ex.Message}";
                    ModelState.AddModelError(string.Empty, ex.Message);
                }

                // 3. Trả về chính trang hiện tại thay vì để hệ thống crash văng ra trang lỗi
                return RedirectToPage("./Index", new { productId = ProductId });
            }
        }
    }

    // Lớp DTO tạm thời phục vụ nhận dữ liệu đầu vào (Form Binding)
    public class VariantInputViewModel
    {
        public string Color { get; set; } = string.Empty;
        public string? Cpu { get; set; }
        public string? Ram { get; set; }
        public string? Storage { get; set; }
        public string? ScreenSize { get; set; }

        [Required]
        [Range(0, double.MaxValue)]
        public decimal Price { get; set; }

        [Required]
        [Range(0, int.MaxValue)]
        public int StockQuantity { get; set; }
    }
}
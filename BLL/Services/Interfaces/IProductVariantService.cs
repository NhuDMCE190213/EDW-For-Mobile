using BLL.DTOs.ProductVariant.Staff;

namespace BLL.Services.Interfaces
{
    public interface IProductVariantService
    {
        Task<List<ProductVariantStaffDto>> GetAllProductVariantsAsync();
        Task<ProductVariantStaffDto?> GetProductVariantByIdAsync(Guid productVariantId);
        Task<ProductVariantStaffDto> CreateProductVariantAsync(ProductVariantStaffCreateDto productVariant);
        Task<bool> UpdateProductVariantAsync(ProductVariantStaffUpdateDto productVariant);
        Task<bool> DeleteProductVariantAsync(ProductVariantStaffDeleteDto productVariant);


        Task<List<ProductVariantStaffDto>> GetVariantsByProductIdAsync(int productId);
        Task<bool> StockInAsync(Guid variantId, int increaseAmount);
    }
}

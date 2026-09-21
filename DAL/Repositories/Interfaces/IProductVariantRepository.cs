using DAL.Models;

namespace DAL.Repositories.Interfaces
{
    public interface IProductVariantRepository
    {
        Task<List<ProductVariant>> GetAllProductVariantsAsync();
        Task<ProductVariant?> GetProductVariantByIdAsync(Guid productVariantId);
        Task<ProductVariant> CreateProductVariantAsync(ProductVariant productVariant);
        Task<bool> UpdateProductVariantAsync(ProductVariant productVariant);
        Task<bool> DeleteProductVariantAsync(Guid productVariantId);


        Task<List<ProductVariant>> GetVariantsByProductIdAsync(int productId);
        Task<bool> StockInAsync(Guid variantId, int increaseAmount);
    }
}

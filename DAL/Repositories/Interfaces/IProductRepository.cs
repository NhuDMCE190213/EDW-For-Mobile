using DAL.Models;

namespace DAL.Repositories.Interfaces
{
    public interface IProductRepository
    {
        Task<List<Product>> GetAllProductsAsync();
        Task<Product?> GetProductByIdAsync(int productId);
        Task<Product> CreateProductAsync(Product product);
        Task<bool> UpdateProductAsync(Product product);
        Task<bool> DeleteProductAsync(int productId);

        Task<Product?> GetProductWithVariantsAsync(Guid productVariantId);
        Task<List<Product>> SearchByNameAsync(string keyword);
        Task<List<Product>> GetProductsByCategoryIdAsync(int categoryId);
    }
}

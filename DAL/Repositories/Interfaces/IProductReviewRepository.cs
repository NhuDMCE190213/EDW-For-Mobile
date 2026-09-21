using DAL.Models;

namespace DAL.Repositories.Interfaces
{
    public interface IProductReviewRepository
    {
        Task<List<ProductReview>> GetAllAsync();
        Task<ProductReview?> GetByIdAsync(int id);
        Task<List<ProductReview>> GetByProductIdAsync(int productId);
        Task<List<ProductReview>> GetByCustomerIdAsync(int customerId);
        Task<ProductReview> CreateAsync(ProductReview review);
        Task<bool> UpdateAsync(ProductReview review);
        Task<bool> DeleteAsync(int id);
        Task<bool> FlagAsync(int id);
        Task<bool> UnflagAsync(int id);
    }
}
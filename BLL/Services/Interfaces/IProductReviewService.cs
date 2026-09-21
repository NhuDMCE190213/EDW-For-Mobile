using BLL.DTOs.ProductReview;

namespace BLL.Services.Interfaces
{
    public interface IProductReviewService
    {
        Task<List<ProductReviewDto>> GetAllProductReviewsAsync();
        Task<ProductReviewDto?> GetProductReviewByIdAsync(int id);
        Task<List<ProductReviewDto>> GetProductReviewsByProductIdAsync(int productId);
        Task<List<ProductReviewDto>> GetProductReviewsByCustomerIdAsync(int customerId);
        Task<bool> FlagProductReviewAsync(int id);
        Task<bool> UnflagProductReviewAsync(int id);
        Task<bool> DeleteProductReviewAsync(int id);
        Task<ProductReviewDto> CreateProductReviewAsync(ProductReviewCreateDto reviewCreateDto);
        Task<bool> UpdateProductReviewAsync(ProductReviewUpdateDto reviewUpdateDto);
    }
}
using BLL.DTOs.ProductReview;
using BLL.Services.Interfaces;
using DAL.Models;
using DAL.Repositories.Interfaces;

namespace BLL.Services
{
    public class ProductReviewService : IProductReviewService
    {
        private readonly IProductReviewRepository _productReviewRepository;

        public ProductReviewService(IProductReviewRepository productReviewRepository)
        {
            _productReviewRepository = productReviewRepository;
        }

        public async Task<List<ProductReviewDto>> GetAllProductReviewsAsync()
        {
            var reviews = await _productReviewRepository.GetAllAsync();
            return reviews.Select(r => new ProductReviewDto
            {
                Id = r.Id,
                CustomerId = r.CustomerId,
                CustomerName = r.Customer?.FullName ?? string.Empty,
                CustomerEmail = r.Customer?.Email ?? string.Empty,
                ProductId = r.ProductId,
                ProductName = r.Product?.ProductName ?? string.Empty,
                Rating = r.Rating,
                Comment = r.Comment,
                IsFlagged = r.IsFlagged,
                IsDeleted = r.IsDeleted,
                CreatedAt = r.CreatedAt,
                UpdatedAt = r.UpdatedAt
            }).ToList();
        }

        public async Task<ProductReviewDto?> GetProductReviewByIdAsync(int id)
        {
            var review = await _productReviewRepository.GetByIdAsync(id);
            if (review != null)
            {
                return new ProductReviewDto
                {
                    Id = review.Id,
                    CustomerId = review.CustomerId,
                    CustomerName = review.Customer?.FullName ?? string.Empty,
                    CustomerEmail = review.Customer?.Email ?? string.Empty,
                    ProductId = review.ProductId,
                    ProductName = review.Product?.ProductName ?? string.Empty,
                    Rating = review.Rating,
                    Comment = review.Comment,
                    IsFlagged = review.IsFlagged,
                    IsDeleted = review.IsDeleted,
                    CreatedAt = review.CreatedAt,
                    UpdatedAt = review.UpdatedAt
                };
            }
            return null;
        }

        public async Task<List<ProductReviewDto>> GetProductReviewsByProductIdAsync(int productId)
        {
            var reviews = await _productReviewRepository.GetByProductIdAsync(productId);
            return reviews.Select(r => new ProductReviewDto
            {
                Id = r.Id,
                CustomerId = r.CustomerId,
                CustomerName = r.Customer?.FullName ?? string.Empty,
                CustomerEmail = r.Customer?.Email ?? string.Empty,
                ProductId = r.ProductId,
                ProductName = r.Product?.ProductName ?? string.Empty,
                Rating = r.Rating,
                Comment = r.Comment,
                IsFlagged = r.IsFlagged,
                IsDeleted = r.IsDeleted,
                CreatedAt = r.CreatedAt,
                UpdatedAt = r.UpdatedAt
            }).ToList();
        }

        public async Task<List<ProductReviewDto>> GetProductReviewsByCustomerIdAsync(int customerId)
        {
            var reviews = await _productReviewRepository.GetByCustomerIdAsync(customerId);
            return reviews.Select(r => new ProductReviewDto
            {
                Id = r.Id,
                CustomerId = r.CustomerId,
                CustomerName = r.Customer?.FullName ?? string.Empty,
                CustomerEmail = r.Customer?.Email ?? string.Empty,
                ProductId = r.ProductId,
                ProductName = r.Product?.ProductName ?? string.Empty,
                Rating = r.Rating,
                Comment = r.Comment,
                IsFlagged = r.IsFlagged,
                IsDeleted = r.IsDeleted,
                CreatedAt = r.CreatedAt,
                UpdatedAt = r.UpdatedAt
            }).ToList();
        }

        public async Task<bool> FlagProductReviewAsync(int id)
        {
            return await _productReviewRepository.FlagAsync(id);
        }

        public async Task<bool> UnflagProductReviewAsync(int id)
        {
            return await _productReviewRepository.UnflagAsync(id);
        }

        public async Task<bool> DeleteProductReviewAsync(int id)
        {
            return await _productReviewRepository.DeleteAsync(id);
        }

        public async Task<ProductReviewDto> CreateProductReviewAsync(ProductReviewCreateDto reviewCreateDto)
        {
            var review = ProductReview.Create(
                reviewCreateDto.CustomerId,
                reviewCreateDto.ProductId,
                reviewCreateDto.Rating,
                reviewCreateDto.Comment
            );

            var createdReview = await _productReviewRepository.CreateAsync(review);
            
            // Reload with navigation properties
            var reviewWithNav = await _productReviewRepository.GetByIdAsync(createdReview.Id);
            
            return new ProductReviewDto
            {
                Id = reviewWithNav!.Id,
                CustomerId = reviewWithNav.CustomerId,
                CustomerName = reviewWithNav.Customer?.FullName ?? string.Empty,
                CustomerEmail = reviewWithNav.Customer?.Email ?? string.Empty,
                ProductId = reviewWithNav.ProductId,
                ProductName = reviewWithNav.Product?.ProductName ?? string.Empty,
                Rating = reviewWithNav.Rating,
                Comment = reviewWithNav.Comment,
                IsFlagged = reviewWithNav.IsFlagged,
                IsDeleted = reviewWithNav.IsDeleted,
                CreatedAt = reviewWithNav.CreatedAt,
                UpdatedAt = reviewWithNav.UpdatedAt
            };
        }

        public async Task<bool> UpdateProductReviewAsync(ProductReviewUpdateDto reviewUpdateDto)
        {
            var existingReview = await _productReviewRepository.GetByIdAsync(reviewUpdateDto.Id);
            if (existingReview == null)
            {
                return false;
            }

            existingReview.Update(reviewUpdateDto.Rating, reviewUpdateDto.Comment);
            return await _productReviewRepository.UpdateAsync(existingReview);
        }
    }
}
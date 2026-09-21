using BLL.DTOs.ProductVariant.Staff;
using BLL.Services.Interfaces;
using DAL.Models;
using DAL.Repositories.Interfaces;

namespace BLL.Services
{
    public class ProductVariantService : IProductVariantService
    {
        private readonly IProductVariantRepository _productVariantRepository;

        public ProductVariantService(IProductVariantRepository productVariantRepository)
        {
            _productVariantRepository = productVariantRepository;
        }

        public async Task<List<ProductVariantStaffDto>> GetAllProductVariantsAsync()
        {
            var productVariants = await _productVariantRepository.GetAllProductVariantsAsync();
            return productVariants.Select(pv => new ProductVariantStaffDto
            {
                ProductVariantId = pv.ProductVariantId,
                Sku = pv.Sku,
                //ProductCode = pv.ProductCode,s
                Color = pv.Color,
                Cpu = pv.Cpu,
                Ram = pv.Ram,
                Storage = pv.Storage,
                ScreenSize = pv.ScreenSize,
                Price = pv.Price,
                StockQuantity = pv.StockQuantity,
                ImageUrl = pv.ImageUrl,
                ProductId = pv.ProductId,
                PromotionId = pv.PromotionId,
                Promotion = pv.Promotion,
                IsDeleted = pv.IsDeleted,
                CreatedAt = pv.CreatedAt,
                UpdatedAt = pv.UpdatedAt
            }).ToList();
        }

        public async Task<ProductVariantStaffDto?> GetProductVariantByIdAsync(Guid productVariantId)
        {
            var productVariant = await _productVariantRepository.GetProductVariantByIdAsync(productVariantId);
            if (productVariant != null)
            {
                return new ProductVariantStaffDto
                {
                    ProductVariantId = productVariant.ProductVariantId,
                    Sku = productVariant.Sku,
                    //ProductCode = productVariant.ProductCode,
                    Color = productVariant.Color,
                    Cpu = productVariant.Cpu,
                    Ram = productVariant.Ram,
                    Storage = productVariant.Storage,
                    ScreenSize = productVariant.ScreenSize,
                    Price = productVariant.Price,
                    StockQuantity = productVariant.StockQuantity,
                    ImageUrl = productVariant.ImageUrl,
                    ProductId = productVariant.ProductId,
                    PromotionId = productVariant.PromotionId,
                    Promotion = productVariant.Promotion,
                    IsDeleted = productVariant.IsDeleted,
                    CreatedAt = productVariant.CreatedAt,
                    UpdatedAt = productVariant.UpdatedAt
                };
            }
            return null;
        }
        public async Task<ProductVariantStaffDto> CreateProductVariantAsync(ProductVariantStaffCreateDto productVariant)
        {
            var newVariant = ProductVariant.Create(
                //productVariant.ProductCode,
                productVariant.Color,
                productVariant.Cpu,
                productVariant.Ram,
                productVariant.Storage,
                productVariant.ScreenSize,
                productVariant.Price,
                productVariant.StockQuantity,
                productVariant.ImageUrl,
                productVariant.ProductId,
                productVariant.PromotionId
            );
            var createdVariant = await _productVariantRepository.CreateProductVariantAsync(newVariant);

            return new ProductVariantStaffDto
            {
                ProductVariantId = createdVariant.ProductVariantId,
                Sku = createdVariant.Sku,
                Color = createdVariant.Color,
                Cpu = createdVariant.Cpu,
                Ram = createdVariant.Ram,
                Storage = createdVariant.Storage,
                ScreenSize = createdVariant.ScreenSize,
                Price = createdVariant.Price,
                StockQuantity = createdVariant.StockQuantity,
                ImageUrl = createdVariant.ImageUrl,
                ProductId = createdVariant.ProductId,
                PromotionId = createdVariant.PromotionId,  
                IsDeleted = createdVariant.IsDeleted,
                CreatedAt = createdVariant.CreatedAt,
                UpdatedAt = createdVariant.UpdatedAt
            };
        }

        public async Task<bool> UpdateProductVariantAsync(ProductVariantStaffUpdateDto productVariant)
        {
            var existingVariant = new ProductVariant
            {
                ProductVariantId = productVariant.ProductVariantId
            };

            existingVariant.Update(
                //productVariant.ProductCode,
                productVariant.Color,
                productVariant.Cpu,
                productVariant.Ram,
                productVariant.Storage,
                productVariant.ScreenSize,
                productVariant.Price,
                productVariant.StockQuantity,
                productVariant.ImageUrl,
                productVariant.ProductId,
                productVariant.PromotionId
            );

            return await _productVariantRepository.UpdateProductVariantAsync(existingVariant);
        }

        public async Task<bool> DeleteProductVariantAsync(ProductVariantStaffDeleteDto productVariant)
        {
            return await _productVariantRepository.DeleteProductVariantAsync(productVariant.ProductVariantId);
        }

        public async Task<List<ProductVariantStaffDto>> GetVariantsByProductIdAsync(int productId)
        {
            var variants = await _productVariantRepository.GetVariantsByProductIdAsync(productId);
            return variants.Select(v => new ProductVariantStaffDto
            {
                ProductVariantId = v.ProductVariantId,
                Sku = v.Sku,
                Color = v.Color,
                Cpu = v.Cpu,
                Ram = v.Ram,
                Storage = v.Storage,
                ScreenSize = v.ScreenSize,
                Price = v.Price,
                StockQuantity = v.StockQuantity,
                ImageUrl = v.ImageUrl,
                ProductId = v.ProductId,
                PromotionId = v.PromotionId,
                Promotion = v.Promotion,
                IsDeleted = v.IsDeleted,
                CreatedAt = v.CreatedAt,
                UpdatedAt = v.UpdatedAt
            }).ToList();
        }

        public async Task<bool> StockInAsync(Guid variantId, int increaseAmount)
        {
            return await _productVariantRepository.StockInAsync(variantId, increaseAmount);
        }
    }
}

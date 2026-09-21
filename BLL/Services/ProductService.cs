using AutoMapper;
using BLL.DTOs.Product.Customer;
using BLL.DTOs.Product.Staff;
using BLL.Services.Interfaces;
using DAL.Models;
using DAL.Repositories.Interfaces;

namespace BLL.Services
{
    public class ProductService : IProductService
    {
        private readonly IProductRepository _productRepository;
        private readonly IMapper _mapper;

        public ProductService(IProductRepository productRepository, IMapper mapper)
        {
            _productRepository = productRepository;
            _mapper = mapper;
        }

        public async Task<List<ProductStaffDto>> GetAllProductsAsync()
        {
            var products = await _productRepository.GetAllProductsAsync();
            var productDtos = products.Select(p => new ProductStaffDto
            {
                ProductId = p.ProductId,
                ProductName = p.ProductName,
                Brand = p.Brand,
                CategoryId = p.CategoryId,
                CategoryName = p.Category != null ? p.Category.Name : string.Empty,
                ImageUrl = p.ImageUrl,
                IsDeleted = p.IsDeleted,
                CreatedAt = p.CreatedAt,
                UpdatedAt = p.UpdatedAt
            }).ToList();

            return productDtos;
        }

        public async Task<ProductCustomerDto?> GetProductCustomerByIdAsync(int productId)
        {
            var product = await _productRepository.GetProductByIdAsync(productId);

            if (product == null)
            {
                return null;
            }

            return _mapper.Map<ProductCustomerDto>(product);
        }

        public async Task<ProductStaffDto?> GetProductByIdAsync(int id)
        {
            var product = await _productRepository.GetProductByIdAsync(id);
            if (product != null)
            {
                return new ProductStaffDto
                {
                    ProductId = product.ProductId,
                    ProductName = product.ProductName,
                    Brand = product.Brand,
                    CategoryId = product.CategoryId,
                    CategoryName = product.Category != null ? product.Category.Name : string.Empty,
                    ImageUrl = product.ImageUrl,
                    IsDeleted = product.IsDeleted,
                    CreatedAt = product.CreatedAt,
                    UpdatedAt = product.UpdatedAt
                };
            }
            return null;
        }
        public async Task<ProductStaffDto> CreateProductAsync(ProductStaffCreateDto productCreateDto)
        {
            var newProduct = Product.Create(
                 productCreateDto.ProductName,
                 productCreateDto.Brand,
                 productCreateDto.CategoryId,
                 productCreateDto.ImageUrl
            );

            var createdProduct = await _productRepository.CreateProductAsync(newProduct);

            var populatedProduct = await GetProductByIdAsync(createdProduct.ProductId);
            if (populatedProduct != null)
            {
                return populatedProduct;
            }

            return new ProductStaffDto
            {
                ProductId = createdProduct.ProductId,
                ProductName = createdProduct.ProductName,
                Brand = createdProduct.Brand,
                CategoryId = createdProduct.CategoryId,
                CategoryName = string.Empty,
                ImageUrl = createdProduct.ImageUrl,
                IsDeleted = createdProduct.IsDeleted,
                CreatedAt = createdProduct.CreatedAt,
                UpdatedAt = createdProduct.UpdatedAt
            };
        }

        public async Task<bool> UpdateProductAsync(ProductStaffUpdateDto productUpdateDto)
        {
            var product = new Product
            {
                ProductId = productUpdateDto.ProductId
            };

            product.Update(
                productUpdateDto.ProductName,
                productUpdateDto.Brand,
                productUpdateDto.CategoryId,
                productUpdateDto.ImageUrl
            );
            
            return await _productRepository.UpdateProductAsync(product); ;
        }

        public async Task<bool> DeleteProductAsync(ProductStaffDeleteDto productDeleteDto)
        {
            return await _productRepository.DeleteProductAsync(productDeleteDto.ProductId); ;
        }

        public async Task<List<ProductStaffDto>> GetProductsByCategoryIdAsync(int categoryId)
        {
            var products = await _productRepository.GetProductsByCategoryIdAsync(categoryId);
            var productDtos = products.Select(p => new ProductStaffDto
            {
                ProductId = p.ProductId,
                ProductName = p.ProductName,
                Brand = p.Brand,
                CategoryId = p.CategoryId,
                CategoryName = p.Category != null ? p.Category.Name : string.Empty,
                ImageUrl = p.ImageUrl,
                IsDeleted = p.IsDeleted,
                CreatedAt = p.CreatedAt,
                UpdatedAt = p.UpdatedAt
            }).ToList();

            return productDtos;
        }

        public async Task<ProductStaffDto?> GetProductWithVariantsAsync(Guid productVariantId)
        {
            var product = await _productRepository.GetProductWithVariantsAsync(productVariantId);
            if (product != null)
            {
                return new ProductStaffDto
                {
                    ProductId = product.ProductId,
                    ProductName = product.ProductName,
                    Brand = product.Brand,
                    CategoryId = product.CategoryId,
                    CategoryName = product.Category != null ? product.Category.Name : string.Empty,
                    ImageUrl = product.ImageUrl,
                    IsDeleted = product.IsDeleted,
                    CreatedAt = product.CreatedAt,
                    UpdatedAt = product.UpdatedAt
                };
            }
            return null;
        }

        public async Task<List<ProductStaffDto>> SearchByNameAsync(string keyword)
        {
            var products = await _productRepository.SearchByNameAsync(keyword);
            var productDtos = products.Select(p => new ProductStaffDto
            {
                ProductId = p.ProductId,
                ProductName = p.ProductName,
                Brand = p.Brand,
                CategoryId = p.CategoryId,
                CategoryName = p.Category != null ? p.Category.Name : string.Empty,
                ImageUrl = p.ImageUrl,
                IsDeleted = p.IsDeleted,
                CreatedAt = p.CreatedAt,
                UpdatedAt = p.UpdatedAt
            }).ToList(); 
            return productDtos;
        }
    }
}

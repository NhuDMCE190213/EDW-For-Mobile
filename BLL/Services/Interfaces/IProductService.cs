using BLL.DTOs.Product.Customer;
using BLL.DTOs.Product.Staff;

namespace BLL.Services.Interfaces
{
    public interface IProductService
    {
        Task<List<ProductStaffDto>> GetAllProductsAsync();
        Task<ProductStaffDto?> GetProductByIdAsync(int id);
        Task<ProductCustomerDto?> GetProductCustomerByIdAsync(int id);
        Task<ProductStaffDto> CreateProductAsync(ProductStaffCreateDto productCreateDto);
        Task<bool> UpdateProductAsync(ProductStaffUpdateDto productUpdateDto);
        Task<bool> DeleteProductAsync(ProductStaffDeleteDto productDeleteDto);
        Task<ProductStaffDto?> GetProductWithVariantsAsync(Guid productVariantId);
        Task<List<ProductStaffDto>> SearchByNameAsync(string keyword);
        Task<List<ProductStaffDto>> GetProductsByCategoryIdAsync(int categoryId);

    }
}

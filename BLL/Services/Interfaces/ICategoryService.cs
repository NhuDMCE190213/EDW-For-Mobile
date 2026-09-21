using BLL.DTOs.Category;

namespace BLL.Services.Interfaces
{
    public interface ICategoryService
    {
        Task<List<CategoryDto>> GetAllCategoriesAsync();
        Task<CategoryDto?> GetCategoryByIdAsync(int id);
        Task<CategoryDto> CreateCategoryAsync(CategoryCreateDto categoryCreateDto);
        Task<bool> UpdateCategoryAsync(CategoryUpdateDto categoryUpdateDto);
        Task<bool> DeleteCategoryAsync(CategoryDeleteDto categoryDeleteDto);
    }
}

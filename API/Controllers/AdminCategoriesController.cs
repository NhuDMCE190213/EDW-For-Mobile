using BLL.DTOs.Category;
using BLL.Services.Interfaces;
using Microsoft.AspNetCore.Mvc;

// For more information on enabling Web API for empty projects, visit https://go.microsoft.com/fwlink/?LinkID=397860

namespace API.Controllers
{
    [Route("api/admin/categories")]
    [ApiController]
    //[Authorize(Roles = "Staff,Admin")]
    public class AdminCategoriesController : ControllerBase
    {
        private readonly ICategoryService _categoryService;

        public AdminCategoriesController(ICategoryService categoryService)
        {
            _categoryService = categoryService;
        }

        // GET: api/<StaffProductsController>
        [HttpGet]
        public async Task<ActionResult<List<CategoryDto>>> GetAll()
        {
            return Ok(await _categoryService.GetAllCategoriesAsync());
        }

        // 2. GET: api/categories/{id}
        [HttpGet("{id:int}")]
        public async Task<IActionResult> GetById(int id)
        {
            var category = await _categoryService.GetCategoryByIdAsync(id);
            if (category == null)
            {
                return NotFound(new { Message = $"Not Found Category with ID = {id}" }); // HTTP 404
            }
            return Ok(category);
        }

        // 3. POST: api/categories
        [HttpPost]
        public async Task<IActionResult> Create([FromBody] CategoryCreateDto dto)
        {
            if (!ModelState.IsValid)
            {
                return BadRequest(ModelState); // HTTP 400 nếu dữ liệu đầu vào không hợp lệ
            }

            var createdCategory = await _categoryService.CreateCategoryAsync(dto);

            // Trả về HTTP 201 Created cùng link dẫn tới API lấy chi tiết item vừa tạo
            return CreatedAtAction(nameof(GetById), new { id = createdCategory.Id }, createdCategory);
        }

        // 4. PUT: api/categories/{id}
        [HttpPut("{id:int}")]
        public async Task<IActionResult> Update(int id, [FromBody] CategoryUpdateDto dto)
        {
            var isUpdated = await _categoryService.UpdateCategoryAsync(dto);
            if (!isUpdated)
            {
                return NotFound();
            }

            return NoContent(); // HTTP 204 No Content (Thành công nhưng không cần trả dữ liệu về)
        }

        // 5. DELETE: api/categories/{id}
        [HttpDelete("{id:int}")]
        public async Task<IActionResult> Delete(int id)
        {
            var isDeleted = await _categoryService.DeleteCategoryAsync(new CategoryDeleteDto { Id = id });
            if (!isDeleted)
            {
                return NotFound();
            }

            return NoContent(); // HTTP 204
        }

    }
}
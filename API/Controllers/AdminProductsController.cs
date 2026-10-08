using BLL.DTOs.Category;
using BLL.DTOs.Product.Staff;
using BLL.Services.Interfaces;
using Microsoft.AspNetCore.Mvc;

// For more information on enabling Web API for empty projects, visit https://go.microsoft.com/fwlink/?LinkID=397860

namespace API.Controllers
{
    [Route("api/admin/products")]
    [ApiController]
    //[Authorize(Roles = "Staff,Admin")]
    public class AdminProductsController : ControllerBase
    {
        private readonly IProductService _productService;

        public AdminProductsController(IProductService productService)
        {
            _productService = productService;
        }

        // GET: api/<StaffProductsController>
        [HttpGet]
        public async Task<ActionResult<List<ProductStaffDto>>> GetAll()
        {
            return Ok(await _productService.GetAllProductsAsync());
        }

        // 2. GET: api/categories/{id}
        [HttpGet("{id:int}")]
        public async Task<IActionResult> GetById(int id)
        {
            var product = await _productService.GetProductByIdAsync(id);
            if (product == null)
            {
                return NotFound(new { Message = $"Not Found Product with ID = {id}" }); // HTTP 404
            }
            return Ok(product);
        }

        // 3. POST: api/categories
        [HttpPost]
        public async Task<IActionResult> Create([FromBody] ProductStaffCreateDto dto)
        {
            if (!ModelState.IsValid)
            {
                return BadRequest(ModelState); // HTTP 400 nếu dữ liệu đầu vào không hợp lệ
            }

            var createdProduct = await _productService.CreateProductAsync(dto);

            // Trả về HTTP 201 Created cùng link dẫn tới API lấy chi tiết item vừa tạo
            return CreatedAtAction(nameof(GetById), new { id = createdProduct.ProductId }, createdProduct);
        }

        // 4. PUT: api/categories/{id}
        [HttpPut("{id:int}")]
        public async Task<IActionResult> Update(int id, [FromBody] ProductStaffUpdateDto dto)
        {
            var isUpdated = await _productService.UpdateProductAsync(dto);
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
            var isDeleted = await _productService.DeleteProductAsync(new ProductStaffDeleteDto { ProductId = id });
            if (!isDeleted)
            {
                return NotFound();
            }

            return NoContent(); // HTTP 204
        }

    }
}
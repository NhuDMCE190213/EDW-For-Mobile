using BLL.DTOs.ProductVariant.Staff;
using BLL.Services.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace API.Controllers
{
    [Route("api/staff/product-variants")]
    [ApiController]
    //[Authorize]
    public class StaffProductVariantsController : ControllerBase
    {
        private readonly IProductVariantService _productVariantService;

        public StaffProductVariantsController(IProductVariantService productVariantService)
        {
            _productVariantService = productVariantService;
        }

        [HttpGet]
        public async Task<ActionResult<List<ProductVariantStaffDto>>> GetAll()
        {
            return Ok(await _productVariantService.GetAllProductVariantsAsync());
        }

        [HttpGet("{id:guid}")]
        public async Task<ActionResult<ProductVariantStaffDto>> GetById(Guid id)
        {
            var variant = await _productVariantService.GetProductVariantByIdAsync(id);
            return variant is null ? NotFound() : Ok(variant);
        }

        [HttpGet("by-product/{productId:int}")]
        public async Task<ActionResult<List<ProductVariantStaffDto>>> GetByProduct(int productId)
        {
            return Ok(await _productVariantService.GetVariantsByProductIdAsync(productId));
        }

        [HttpPost]
        public async Task<ActionResult<ProductVariantStaffDto>> Create([FromBody] ProductVariantStaffCreateDto dto)
        {
            var created = await _productVariantService.CreateProductVariantAsync(dto);
            return CreatedAtAction(nameof(GetById), new { id = created.ProductVariantId }, created);
        }

        [HttpPut("{id:guid}")]
        public async Task<IActionResult> Update(Guid id, [FromBody] ProductVariantStaffUpdateDto dto)
        {
            if (id != dto.ProductVariantId)
            {
                return BadRequest("Route id and body ProductVariantId do not match.");
            }

            var updated = await _productVariantService.UpdateProductVariantAsync(dto);
            return updated ? NoContent() : NotFound();
        }

        [HttpDelete("{id:guid}")]
        public async Task<IActionResult> Delete(Guid id)
        {
            var deleted = await _productVariantService.DeleteProductVariantAsync(
                new ProductVariantStaffDeleteDto { ProductVariantId = id });
            return deleted ? NoContent() : NotFound();
        }

        [HttpPost("{id:guid}/stock-in")]
        public async Task<IActionResult> StockIn(Guid id, [FromBody] int amount)
        {
            var success = await _productVariantService.StockInAsync(id, amount);
            return success ? NoContent() : NotFound();
        }

    }
}

using BLL.DTOs.Product.Staff;
using BLL.Services.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

// For more information on enabling Web API for empty projects, visit https://go.microsoft.com/fwlink/?LinkID=397860

namespace API.Controllers
{
    [Route("api/staff/products")]
    [ApiController]
    //[Authorize(Roles = "Staff,Admin")]
    public class StaffProductsController : ControllerBase
    {
        private readonly IProductService _productService;

        public StaffProductsController(IProductService productService)
        {
            _productService = productService;
        }

        // GET: api/<StaffProductsController>
        [HttpGet]
        public async Task<ActionResult<List<ProductStaffDto>>> GetAll()
        {
            return Ok(await _productService.GetAllProductsAsync());
        }

    }
}

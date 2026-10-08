using BLL.Services.Interfaces;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.SignalR;
using API.Hubs;

namespace API.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class PromotionsController : ControllerBase
    {
        private readonly IPromotionService _promotionService;
        private readonly IHubContext<PromotionHub> _hubContext;

        public PromotionsController(IPromotionService promotionService, IHubContext<PromotionHub> hubContext)
        {
            _promotionService = promotionService;
            _hubContext = hubContext;
        }

        [HttpPost("list")]
        public async Task<ActionResult<BLL.DTOs.Promotion.PromotionList.PromotionListResponeDto>> GetPromotionsList([FromBody] BLL.DTOs.Promotion.PromotionList.PromotionListRequest request)
        {
            var result = await _promotionService.GetPromotionsListAsync(request);
            return Ok(result);
        }

        [HttpGet("{id}")]
        public async Task<ActionResult<BLL.DTOs.Promotion.PromotionDto>> GetPromotionById(Guid id)
        {
            var result = await _promotionService.GetPromotionByIdAsync(id);
            if (result == null) return NotFound();
            return Ok(result);
        }

        [HttpGet("active")]
        public async Task<ActionResult<List<BLL.DTOs.Promotion.PromotionDto>>> GetActiveAndUpcomingPromotions()
        {
            var result = await _promotionService.GetActiveAndUpcomingPromotionsAsync();
            return Ok(result);
        }

        [HttpPost]
        public async Task<IActionResult> CreatePromotion([FromBody] BLL.DTOs.Promotion.PromotionCreateDto promotionCreateDto)
        {
            await _promotionService.CreatePromotionAsync(promotionCreateDto);
            await _hubContext.Clients.All.SendAsync("OnPromotionChanged");
            return Ok(new { message = "Promotion created successfully" });
        }

        [HttpPut("{id}")]
        public async Task<IActionResult> UpdatePromotion(Guid id, [FromBody] BLL.DTOs.Promotion.PromotionUpdateDto promotionUpdateDto)
        {
            await _promotionService.UpdatePromotionAsync(id, promotionUpdateDto);
            await _hubContext.Clients.All.SendAsync("OnPromotionChanged");
            await _hubContext.Clients.All.SendAsync("PromotionUpdated", id);
            return Ok(new { message = "Promotion updated successfully" });
        }

        [HttpDelete("{id}")]
        public async Task<IActionResult> DeletePromotion(Guid id)
        {
            await _promotionService.DeletePromotionAsync(id);
            await _hubContext.Clients.All.SendAsync("OnPromotionChanged");
            await _hubContext.Clients.All.SendAsync("PromotionDeleted", id);
            return Ok(new { message = "Promotion deleted/disabled successfully" });
        }
    }
}

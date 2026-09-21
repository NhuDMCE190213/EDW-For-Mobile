using BLL.DTOs.Promotion;
using BLL.DTOs.Promotion.PromotionList;

namespace BLL.Services.Interfaces
{
    public interface IPromotionService
    {
        public Task<PromotionListResponeDto> GetPromotionsListAsync(PromotionListRequest request);
        public Task CreatePromotionAsync(PromotionCreateDto promotionCreateDto);
        public Task UpdatePromotionAsync(Guid id, PromotionUpdateDto promotionUpdateDto);
        public Task DeletePromotionAsync(Guid id);
        public Task<List<PromotionDto>> GetActiveAndUpcomingPromotionsAsync();
    }
}
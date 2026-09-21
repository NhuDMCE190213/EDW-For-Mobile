using AutoMapper;
using BLL.DTOs.Pagination;
using BLL.DTOs.Promotion;
using BLL.DTOs.Promotion.PromotionList;
using BLL.Services.Interfaces;
using DAL.Models;
using DAL.Repositories.Interfaces;
using Microsoft.EntityFrameworkCore;

namespace BLL.Services
{
    public class PromotionService : IPromotionService
    {
        private readonly IUnitOfWork _unitOfWork;
        private readonly IMapper _mapper;

        public PromotionService(IMapper mapper, IUnitOfWork unitOfWork)
        {
            _mapper = mapper;
            _unitOfWork = unitOfWork;
        }

        public async Task CreatePromotionAsync(PromotionCreateDto promotionCreateDto)
        {
            try
            {
                await _unitOfWork.BeginTransactionAsync();
                var promotion = _mapper.Map<Promotion>(promotionCreateDto);
                await _unitOfWork.Repository<Promotion>().AddAsync(promotion);
                await _unitOfWork.SaveChangesAsync();
                await _unitOfWork.CommitAsync();
            }
            catch (Exception ex)
            {
                await _unitOfWork.RollbackAsync();
                throw new Exception($"Error creating promotion: {ex.Message}");
            }
        }

        public async Task DeletePromotionAsync(Guid id)
        {
            try
            {
                await _unitOfWork.BeginTransactionAsync();
                var promotion = await _unitOfWork.Repository<Promotion>().Query().FirstOrDefaultAsync(p => p.PromotionId == id);
                if (promotion is null)
                {
                    throw new Exception("Promotion not found");
                }
                promotion.Delete(true);
                await _unitOfWork.SaveChangesAsync();
                await _unitOfWork.CommitAsync();
            }
            catch (Exception ex)
            {
                await _unitOfWork.RollbackAsync();
                throw new Exception($"Error deleting promotion: {ex.Message}");
            }
        }

        public async Task<List<PromotionDto>> GetActiveAndUpcomingPromotionsAsync()
        {
            var promotionsQuery = _unitOfWork.Repository<Promotion>().Query()
                .Where(p => !p.IsDeleted && !p.IsDisabled)
                .Where(p =>
                    // Active promotions
                    (!p.IsLimitedTime && p.IsReservedStock && p.MaxReservedStock > 0) ||
                    (p.IsLimitedTime && p.StartAt.HasValue && p.EndAt.HasValue && p.StartAt.Value <= DateTime.UtcNow && p.EndAt.Value >= DateTime.UtcNow && !p.IsReservedStock) ||
                    (p.IsLimitedTime && p.StartAt.HasValue && p.EndAt.HasValue && p.StartAt.Value <= DateTime.UtcNow && p.EndAt.Value >= DateTime.UtcNow && p.IsReservedStock && p.MaxReservedStock > 0) ||
                    // Upcoming promotions
                    (p.IsLimitedTime && p.StartAt.HasValue && p.EndAt.HasValue && p.StartAt.Value > DateTime.UtcNow)
                );
            var promotions = await promotionsQuery.ToListAsync();
            return _mapper.Map<List<PromotionDto>>(promotions);
        }

        public async Task<PromotionListResponeDto> GetPromotionsListAsync(PromotionListRequest request)
        {
            // Query
            var promotionsQuery = _unitOfWork.Repository<Promotion>().Query().OrderByDescending(p => p.CreatedAt).IgnoreQueryFilters().AsNoTracking();

            if (request.StartAt.HasValue) promotionsQuery = promotionsQuery.Where(p => p.StartAt >= request.StartAt);
            if (request.EndAt.HasValue) promotionsQuery = promotionsQuery.Where(p => p.EndAt <= request.EndAt);

            if (!request.IncludeDeleted)
            {
                promotionsQuery = promotionsQuery.Where(p => !p.IsDeleted);
            }

            if (!request.IncludeDisable)
            {
                promotionsQuery = promotionsQuery.Where(p => !p.IsDisabled);
            }

            if (!string.IsNullOrEmpty(request.SearchTerm))
            {
                promotionsQuery = promotionsQuery.Where(p => p.Name.ToLower().Contains(request.SearchTerm.ToLower()));
            }

            // Pagination
            var totalItems = await promotionsQuery.CountAsync();

            var activeCount = await promotionsQuery
                .Where(p => !p.IsDeleted && !p.IsDisabled)
                .Where(p =>
                // Stock
                    (!p.IsLimitedTime && p.IsReservedStock && p.MaxReservedStock > 0) ||
                    // Time
                    (p.IsLimitedTime && p.StartAt.HasValue && p.EndAt.HasValue && p.StartAt.Value <= DateTime.UtcNow && p.EndAt.Value >= DateTime.UtcNow && !p.IsReservedStock) ||
                    // Both
                    (p.IsLimitedTime && p.StartAt.HasValue && p.EndAt.HasValue && p.StartAt.Value <= DateTime.UtcNow && p.EndAt.Value >= DateTime.UtcNow && p.IsReservedStock && p.MaxReservedStock > 0)
                )
                .CountAsync();

            var upcomingCount = await promotionsQuery
                .Where(p => !p.IsDeleted && !p.IsDisabled)
                .Where(p =>
                    p.IsLimitedTime && p.StartAt.HasValue && p.EndAt.HasValue &&
                    p.StartAt.Value > DateTime.UtcNow
                )
                .CountAsync();

            var expiredCount = await promotionsQuery
                .Where(p => !p.IsDeleted && !p.IsDisabled)
                .Where(p => (p.IsLimitedTime && p.EndAt.HasValue && p.EndAt.Value < DateTime.UtcNow))
                .CountAsync();

            var promotions = await promotionsQuery.Skip((request.Pagination.Page - 1) * request.Pagination.PageSize).Take(request.Pagination.PageSize).ToListAsync();

            var promotionDtos = _mapper.Map<List<PromotionDto>>(promotions);

            // Return response
            return new PromotionListResponeDto
            {
                ActiveCount = activeCount,
                Upcoming = upcomingCount,
                ExpiredOrDisabledCount = expiredCount,
                Pagination = new PaginatedResponse<PromotionDto>
                {
                    Items = promotionDtos,
                    TotalCount = totalItems,
                    Page = request.Pagination.Page,
                    PageSize = request.Pagination.PageSize
                }
            };

        }

        public async Task UpdatePromotionAsync(Guid id, PromotionUpdateDto promotionUpdateDto)
        {
            try
            {
                await _unitOfWork.BeginTransactionAsync();
                var promotion = await _unitOfWork.Repository<Promotion>().Query().FirstOrDefaultAsync(p => p.PromotionId == id);
                if (promotion is null)
                {
                    throw new Exception("Promotion not found");
                }
                promotion.Update(
                    promotionUpdateDto.Name,
                    promotionUpdateDto.PromotionType,
                    promotionUpdateDto.SalePrice,
                    promotionUpdateDto.ThresholdPrice,
                    promotionUpdateDto.Percentage,
                    promotionUpdateDto.IsReservedStock,
                    promotionUpdateDto.MaxReservedStock,
                    promotionUpdateDto.IsLimitedTime,
                    promotionUpdateDto.StartAt,
                    promotionUpdateDto.EndAt,
                    promotionUpdateDto.IsDisable
                );
                await _unitOfWork.SaveChangesAsync();
                await _unitOfWork.CommitAsync();
            }
            catch (Exception ex)
            {
                await _unitOfWork.RollbackAsync();
                throw new Exception($"Error updating promotion: {ex.Message}");
            }
        }
    }
}
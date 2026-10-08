using AutoMapper;
using BLL.DTOs.Pagination;
using BLL.DTOs.Promotion;
using BLL.DTOs.Promotion.PromotionList;
using BLL.Services.Interfaces;
using DAL.Models;
using DAL.Repositories.Interfaces;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Caching.Memory;

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
            var activeAndUpcoming = await _unitOfWork.Repository<Promotion>().Query()
                .IgnoreQueryFilters()
                .AsNoTracking()
                .Where(p => !p.IsDeleted && !p.IsDisabled)
                .Where(p =>
                    // Active promotions
                    (!p.IsLimitedTime && p.IsReservedStock && p.MaxReservedStock > 0) ||
                    (p.IsLimitedTime && p.StartAt.HasValue && p.EndAt.HasValue && p.StartAt.Value <= DateTime.UtcNow && p.EndAt.Value >= DateTime.UtcNow && !p.IsReservedStock) ||
                    (p.IsLimitedTime && p.StartAt.HasValue && p.EndAt.HasValue && p.StartAt.Value <= DateTime.UtcNow && p.EndAt.Value >= DateTime.UtcNow && p.IsReservedStock && p.MaxReservedStock > 0) ||
                    // Upcoming promotions
                    (p.IsLimitedTime && p.StartAt.HasValue && p.EndAt.HasValue && p.StartAt.Value > DateTime.UtcNow)
                )
                .OrderByDescending(p => p.CreatedAt)
                .ToListAsync();

            var result = _mapper.Map<List<PromotionDto>>(activeAndUpcoming);

            return result!;
        }

        public async Task<PromotionDto?> GetPromotionByIdAsync(Guid id)
        {
            var promotion = await _unitOfWork.Repository<Promotion>().Query()
                .IgnoreQueryFilters()
                .AsNoTracking()
                .FirstOrDefaultAsync(p => p.PromotionId == id);
            
            if (promotion == null) return null;

            return _mapper.Map<PromotionDto>(promotion);
        }

        public async Task<PromotionListResponeDto> GetPromotionsListAsync(PromotionListRequest request)
        {
            var promotionsQuery = _unitOfWork.Repository<Promotion>().Query().IgnoreQueryFilters().AsNoTracking();

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

            if (request.DiscountType.HasValue)
            {
                promotionsQuery = promotionsQuery.Where(p => p.PromotionType == request.DiscountType.Value);
                if (request.DiscountType.Value == DAL.Enums.PromotionTypeEnum.Percentage)
                {
                    if (request.MinDiscount.HasValue) promotionsQuery = promotionsQuery.Where(p => p.Percentage >= request.MinDiscount.Value);
                    if (request.MaxDiscount.HasValue) promotionsQuery = promotionsQuery.Where(p => p.Percentage <= request.MaxDiscount.Value);
                }
                else
                {
                    if (request.MinDiscount.HasValue) promotionsQuery = promotionsQuery.Where(p => p.SalePrice >= request.MinDiscount.Value);
                    if (request.MaxDiscount.HasValue) promotionsQuery = promotionsQuery.Where(p => p.SalePrice <= request.MaxDiscount.Value);
                }
            }

            if (!request.IncludeActive || !request.IncludeUpcoming || !request.IncludeExpired || !request.IncludeOutOfStock)
            {
                var now = DateTime.UtcNow;
                promotionsQuery = promotionsQuery.Where(p =>
                    (request.IncludeExpired && (p.IsLimitedTime && p.EndAt.HasValue && p.EndAt.Value < now)) ||
                    (request.IncludeUpcoming && (p.IsLimitedTime && p.StartAt.HasValue && p.EndAt.HasValue && p.StartAt.Value > now)) ||
                    (request.IncludeOutOfStock && (p.IsReservedStock && p.MaxReservedStock <= 0 && !(p.IsLimitedTime && p.EndAt.HasValue && p.EndAt.Value < now) && !(p.IsLimitedTime && p.StartAt.HasValue && p.EndAt.HasValue && p.StartAt.Value > now))) ||
                    (request.IncludeActive && (
                        !(p.IsLimitedTime && p.EndAt.HasValue && p.EndAt.Value < now) &&
                        !(p.IsLimitedTime && p.StartAt.HasValue && p.EndAt.HasValue && p.StartAt.Value > now) &&
                        !(p.IsReservedStock && p.MaxReservedStock <= 0)
                    ))
                );
            }

            // Execute Counts concurrently for better performance
            var activeQuery = promotionsQuery
                .Where(p => !p.IsDeleted && !p.IsDisabled)
                .Where(p =>
                    !(p.IsLimitedTime && p.EndAt.HasValue && p.EndAt.Value < DateTime.UtcNow) &&
                    !(p.IsLimitedTime && p.StartAt.HasValue && p.EndAt.HasValue && p.StartAt.Value > DateTime.UtcNow) &&
                    !(p.IsReservedStock && p.MaxReservedStock <= 0)
                );

            var upcomingQuery = promotionsQuery
                .Where(p => !p.IsDeleted && !p.IsDisabled)
                .Where(p =>
                    p.IsLimitedTime && p.StartAt.HasValue && p.EndAt.HasValue &&
                    p.StartAt.Value > DateTime.UtcNow
                );

            var expiredQuery = promotionsQuery
                .Where(p => !p.IsDeleted && !p.IsDisabled)
                .Where(p => (p.IsLimitedTime && p.EndAt.HasValue && p.EndAt.Value < DateTime.UtcNow));

            var totalItems = await promotionsQuery.CountAsync();
            var activeCount = await activeQuery.CountAsync();
            var upcomingCount = await upcomingQuery.CountAsync();
            var expiredCount = await expiredQuery.CountAsync();

            var promotions = await promotionsQuery
                .OrderByDescending(p => p.CreatedAt)
                .Skip((request.Pagination.Page - 1) * request.Pagination.PageSize)
                .Take(request.Pagination.PageSize)
                .ToListAsync();

            var promotionDtos = _mapper.Map<List<PromotionDto>>(promotions);

            var maxCost = await _unitOfWork.Repository<Promotion>().Query().MaxAsync(p => (decimal?)p.SalePrice) ?? 0;

            return new PromotionListResponeDto
            {
                ActiveCount = activeCount,
                Upcoming = upcomingCount,
                ExpiredOrDisabledCount = expiredCount,
                MaxCost = maxCost,
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
using DAL.Enums;
using DAL.Models.Base;
using Microsoft.EntityFrameworkCore;
using System.ComponentModel.DataAnnotations;

namespace DAL.Models
{
    public class Promotion : IBaseEntity
    {
        [Key]
        public Guid PromotionId { get; set; }
        [Required]
        public string Name { get; set; } = string.Empty;
        // Type
        [Required]
        public PromotionTypeEnum PromotionType { get; set; } // true: percentage, false: fixed amount
        [Range(0, double.MaxValue)]
        public decimal? SalePrice { get; set; }
        [Range(0, double.MaxValue)]
        public decimal? ThresholdPrice { get; set; }
        [Range(0, 100)]
        public byte? Percentage { get; set; }
        // Stock
        public bool IsReservedStock { get; set; } = true;
        [Range(0, int.MaxValue)]
        public int? MaxReservedStock { get; set; }
        // Time
        public bool IsLimitedTime { get; set; } = false;
        public DateTime? StartAt { get; set; }
        public DateTime? EndAt { get; set; }

        public bool IsDeleted { get; set; } = false;
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
        public DateTime? UpdatedAt { get; set; }
        public bool IsDisabled { get; set; } = false;

        public Promotion Create(string name,PromotionTypeEnum promotionTypeEnum, decimal? salePrice = null, decimal? thresholdPrice = null, byte? percentage = null, bool isReservedStock = true, int? maxReservedStock = null, bool isLimitedTime = false, DateTime? startAt = null, DateTime? endAt = null, bool isDisable = false)
        {
            return new Promotion
            {
                Name = name,
                PromotionId = Guid.NewGuid(),
                PromotionType = promotionTypeEnum,
                SalePrice = salePrice,
                ThresholdPrice = thresholdPrice,
                Percentage = percentage,
                IsReservedStock = isReservedStock,
                MaxReservedStock = maxReservedStock,
                IsLimitedTime = isLimitedTime,
                IsDisabled = isDisable,
                StartAt = startAt,
                EndAt = endAt
            };
        }

        public void Update(string name, PromotionTypeEnum promotionTypeEnum, decimal? salePrice = null, decimal? thresholdPrice = null, byte? percentage = null, bool isReservedStock = true, int? maxReservedStock = null, bool isLimitedTime = false, DateTime? startAt = null, DateTime? endAt = null, bool isDisable = false)
        {
            Name = name;
            PromotionType = promotionTypeEnum;
            SalePrice = salePrice;
            ThresholdPrice = thresholdPrice;
            Percentage = percentage;
            IsReservedStock = isReservedStock;
            MaxReservedStock = maxReservedStock;
            IsLimitedTime = isLimitedTime;
            StartAt = startAt;
            EndAt = endAt;
            UpdatedAt = DateTime.UtcNow;
            IsDisabled = isDisable;
        }

        public void Delete(bool isDelete)
        {
            IsDeleted = isDelete;
        }

        public bool IsActive()
        {
            if (IsDeleted || IsDisabled)
            {
                return false;
            }
            if (IsReservedStock && MaxReservedStock.HasValue && MaxReservedStock.Value <= 0)
            {
                return false;
            }
            if (IsLimitedTime)
            {
                var now = DateTime.UtcNow;
                return StartAt.HasValue && EndAt.HasValue && now >= StartAt.Value && now <= EndAt.Value;
            }
            return true;
        }

        public bool HasUsesLeft()
        {
            if (!IsActive()) return false;
            if (!IsReservedStock) return true;
            return MaxReservedStock.HasValue && MaxReservedStock.Value > 0;
        }
    }
}
using AutoMapper;
using DAL.Enums;
using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace BLL.DTOs.Promotion
{
    [AutoMap(typeof(DAL.Models.Promotion), ReverseMap = true)]
    public class PromotionUpdateDto
    {
        [Required]
        public string Name { get; set; } = string.Empty;
        // Type
        [Required]
        public PromotionTypeEnum PromotionType { get; set; }
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
        public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;
        public bool IsDisable { get; set; } = false;
    }
}

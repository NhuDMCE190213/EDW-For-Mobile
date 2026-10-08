using BLL.DTOs.Pagination;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace BLL.DTOs.Promotion.PromotionList
{
    public class PromotionListRequest
    {
        public string? SearchTerm { get; set; } = null;
        public bool IncludeDeleted { get; set; } = false;
        public bool IncludeDisable { get; set; } = false;
        public bool IncludeActive { get; set; } = true;
        public bool IncludeUpcoming { get; set; } = true;
        public bool IncludeExpired { get; set; } = true;
        public bool IncludeOutOfStock { get; set; } = true;
        public DateTime? StartAt { get; set; }
        public DateTime? EndAt { get; set; }
        
        public DAL.Enums.PromotionTypeEnum? DiscountType { get; set; }
        public decimal? MinDiscount { get; set; }
        public decimal? MaxDiscount { get; set; }
        
        public PaginationRequest Pagination { get; set; } = new PaginationRequest();
    }
}

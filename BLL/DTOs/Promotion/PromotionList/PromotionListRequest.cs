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
        public DateTime? StartAt { get; set; }
        public DateTime? EndAt { get; set; }
        public PaginationRequest Pagination { get; set; } = new PaginationRequest();
    }
}

using BLL.DTOs.Pagination;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace BLL.DTOs.Promotion.PromotionList
{
    public class PromotionListResponeDto
    {
        public int ActiveCount { get; set; } = 0;
        public int Upcoming { get; set; } = 0;
        public int ExpiredOrDisabledCount { get; set; } = 0;
        public PaginatedResponse<PromotionDto> Pagination { get; set; } = new PaginatedResponse<PromotionDto>();
    }
}

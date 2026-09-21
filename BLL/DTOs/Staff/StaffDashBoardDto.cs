using BLL.DTOs.Pagination;
using BLL.DTOs.Promotion;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace BLL.DTOs.Staff
{
    public class StaffDashBoardDto
    {
        public int ActiveCount { get; set; } = 0;
        public PaginatedResponse<StaffDto> Pagination { get; set; } = new PaginatedResponse<StaffDto>();
    }
}

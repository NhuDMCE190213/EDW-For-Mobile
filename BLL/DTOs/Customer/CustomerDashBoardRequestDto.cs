using BLL.DTOs.Pagination;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace BLL.DTOs.Customer
{
    public class CustomerDashBoardRequestDto
    {
        public string? SearchTerm { get; set; }
        public bool IncludeDelete { get; set; } = false;
        public bool IncludeDisable { get; set; } = false;
        public PaginationRequest Pagination { get; set; } = new PaginationRequest();
    }
}

using BLL.DTOs.Customer;
using BLL.DTOs.Pagination;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace BLL.DTOs.Customer
{
    public class CustomerDashBoardDto
    {
        public int ActiveCount { get; set; } = 0;
        public PaginatedResponse<CustomerDto> Pagination { get; set; } = new PaginatedResponse<CustomerDto>();
    }
}

using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace BLL.DTOs.Pagination
{
    public class PaginationRequest
    {
        private int _page = 1;
        private int _pageSize = 10;
        private const int MAX_PAGE_SIZE = 100;

        public int Page
        {
            get => _page;
            set => _page = value < 1 ? 1 : value;
        }

        public int PageSize
        {
            get => _pageSize;
            set => _pageSize = value < 1 ? 10 : (value > MAX_PAGE_SIZE ? MAX_PAGE_SIZE : value);
        }
    }
}

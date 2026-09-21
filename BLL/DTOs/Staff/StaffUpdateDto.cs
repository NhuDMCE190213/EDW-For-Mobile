using AutoMapper;
using DAL.Enums;
using DAL.Models;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace BLL.DTOs.Staff
{
    [AutoMap(typeof(DAL.Models.Staff), ReverseMap = true)]
    public class StaffUpdateDto
    {
        public string FullName { get; set; } = string.Empty;
        public string Email { get; set; } = string.Empty;
        public RoleEnum Role { get; set; }
        public bool IsActive { get; set; }
    }
}

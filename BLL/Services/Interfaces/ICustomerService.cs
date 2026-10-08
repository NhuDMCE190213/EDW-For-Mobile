using BLL.DTOs.Customer;
using BLL.DTOs.Pagination;

namespace BLL.Services.Interfaces
{
    public interface ICustomerService
    {
        Task<CustomerProfileDto?> GetProfileAsync(int customerId);
        Task<CustomerDto?> GetByEmailAsync(string email);
        Task<CustomerDto?> ValidateLoginAsync(string email, string password);
        Task<CustomerDto> CreateAsync(CustomerCreateDto createDto);
        Task<CustomerDto> RegisterAsync(CustomerRegisterDto registerDto);
        Task<bool> SetPasswordAsync(int customerId, string newPassword);
        Task<bool> UpdateProfileAsync(int customerId, CustomerProfileDto profileDto);
        Task<CustomerDashBoardDto> GetCustomersAsync(CustomerDashBoardRequestDto requestDto);
        Task UpdateCustomerAsync(int customerId, CustomerUpdateDto customerUpdateDto);
        Task DeleteCustomerAsync(int customerId);
    }
}